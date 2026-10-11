import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A square crop shared by photo previews. No upload occurs here.
class ProfilePhotoCrop extends StatefulWidget {
  final ui.Image image;
  const ProfilePhotoCrop({super.key, required this.image});
  static Future<Uint8List?> open(BuildContext context, Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!context.mounted) { frame.image.dispose(); return null; }
    try {
      return await showDialog<Uint8List>(context: context,
        builder: (_) => ProfilePhotoCrop(image: frame.image));
    } finally { frame.image.dispose(); }
  }
  @override
  State<ProfilePhotoCrop> createState() => _ProfilePhotoCropState();
}
class _ProfilePhotoCropState extends State<ProfilePhotoCrop> {
  double zoom = 1, horizontal = 0, vertical = 0;
  bool saving = false;
  late final ui.Image previewImage;
  @override
  void initState() {
    super.initState();
    // The dialog remains mounted during its closing animation.
    previewImage = widget.image.clone();
  }
  @override
  void dispose() {
    previewImage.dispose();
    super.dispose();
  }
  Rect get crop {
    final side = math.min(previewImage.width, previewImage.height) / zoom;
    return Rect.fromLTWH((previewImage.width-side)*(horizontal+1)/2,
      (previewImage.height-side)*(vertical+1)/2, side, side);
  }
  Future<void> apply() async {
    setState(() => saving = true);
    try {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(previewImage, crop,
        const Rect.fromLTWH(0,0,512,512), Paint()..filterQuality=FilterQuality.high);
      final picture = recorder.endRecording();
      final result = await picture.toImage(512,512);
      picture.dispose();
      final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
      result.dispose();
      if (mounted && bytes != null) Navigator.pop(context, bytes.buffer.asUint8List());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not crop this photo. Try a different image.')));
    } finally { if (mounted) setState(() => saving=false); }
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adjust Profile Photo'),
    content: SizedBox(width: 320, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      AspectRatio(aspectRatio: 1, child: ClipOval(child: CustomPaint(painter: _CropPainter(previewImage,crop)))),
      const SizedBox(height: 12),
      const Text('Zoom and position your photo inside the circle.'),
      const Text('Zoom'),
      Slider(value:zoom,min:1,max:3,label:zoom.toStringAsFixed(1),onChanged:saving?null:(v)=>setState(()=>zoom=v)),
      const Text('Left / Right'),
      Slider(value:horizontal,min:-1,max:1,onChanged:saving?null:(v)=>setState(()=>horizontal=v)),
      const Text('Up / Down'),
      Slider(value:vertical,min:-1,max:1,onChanged:saving?null:(v)=>setState(()=>vertical=v)),
    ]))),
    actions: [TextButton(onPressed:saving?null:()=>Navigator.pop(context),child:const Text('Cancel')),
      FilledButton(onPressed:saving?null:apply,child:Text(saving?'Preparing…':'Use Crop'))],
  );
}
class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect crop;
  _CropPainter(this.image,this.crop);
  @override
  void paint(Canvas canvas,Size size) => canvas.drawImageRect(image,crop,Offset.zero & size,Paint()..filterQuality=FilterQuality.high);
  @override
  bool shouldRepaint(covariant _CropPainter old)=>old.crop!=crop || old.image!=image;
}
