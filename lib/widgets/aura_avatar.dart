import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/widgets/trulura_safe_avatar.dart';

class AuraAvatar extends StatefulWidget {
  final String image;
  final int compatibility;
  final double size;

  const AuraAvatar({
    super.key,
    required this.image,
    required this.compatibility,
    this.size = 80,
  });

  @override
  State<AuraAvatar> createState() => _AuraAvatarState();
}

class _AuraAvatarState extends State<AuraAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<Color> ringColors(Color auraColor) {
    final c = widget.compatibility;
    final base = Color.lerp(auraColor, Colors.white, 0.18) ?? auraColor;

    if (c >= 90) {
      return [base, Color.lerp(base, Colors.orangeAccent, 0.45) ?? Colors.orangeAccent];
    }

    if (c >= 75) {
      return [base, Color.lerp(base, Colors.pinkAccent, 0.35) ?? Colors.pinkAccent];
    }

    if (c >= 60) {
      return [Color.lerp(base, Colors.deepPurple, 0.25) ?? Colors.deepPurple, base];
    }

    return [Color.lerp(base, Colors.grey, 0.45) ?? Colors.grey, base];
  }

  ImageProvider? _imageProvider() {
    final raw = widget.image.trim();
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    final isNetwork = uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    return isNetwork ? NetworkImage(raw) : AssetImage(raw);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    final aura = context.watch<AuraStateController>();
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final angle = controller.value * 2 * pi;
          final pulse = 0.75 + (sin(angle) + 1) * 0.18;
          final colors = ringColors(aura.auraColor);
          return Transform.rotate(
            angle: angle,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: colors),
                boxShadow: [
                  BoxShadow(
                    color: aura.auraColor.withValues(alpha: 0.18 * pulse),
                    blurRadius: 18 * pulse,
                    spreadRadius: 2 * pulse,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -angle,
                child: TruLuraSafeAvatar(radius: size / 2, image: _imageProvider()),
              ),
            ),
          );
        },
      ),
    );
  }
}
