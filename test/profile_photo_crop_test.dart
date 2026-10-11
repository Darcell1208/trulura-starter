import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/widgets/profile_photo_crop.dart';
void main() {
  testWidgets('crop exports a square image', (tester) async {
    final data=await tester.runAsync(() async {
    final recorder=ui.PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0,0,80,40),Paint()..color=Colors.blue);
    final picture=recorder.endRecording();
    final source=await picture.toImage(80,40);
    final data=await source.toByteData(format:ui.ImageByteFormat.png);
    source.dispose(); picture.dispose(); return data;
    });
    Uint8List? output;
    await tester.pumpWidget(MaterialApp(home:Builder(builder:(context)=>Scaffold(
      body:TextButton(onPressed:() async { output=await ProfilePhotoCrop.open(context,data!.buffer.asUint8List()); },child:const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds:100)); });
    await tester.pumpAndSettle();
    expect(find.text('Adjust Profile Photo'),findsOneWidget);
    await tester.tap(find.text('Use Crop'));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds:100)); });
    await tester.pumpAndSettle();
    expect(output,isNotNull);
    await tester.runAsync(() async {
    final codec=await ui.instantiateImageCodec(output!);
    final frame=await codec.getNextFrame();
    expect(frame.image.width,512); expect(frame.image.height,512);
    frame.image.dispose(); codec.dispose();
    });
    expect(tester.takeException(),isNull);
    await tester.tap(find.text('Open'));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds:100)); });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(output,isNull);
    expect(tester.takeException(),isNull);
  });
}


