import 'package:flutter/material.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/breathing_glow.dart';

/// A palette-driven, glowing circular action button used for creating a post.
///
/// Designed to match the "orb" style: gradient fill, subtle gloss highlight,
/// and breathing outer glow.
class PostOrbButton extends StatelessWidget {
  final TruLuraMode mode;
  final VoidCallback onTap;
  final bool enabled;
  final double size;

  const PostOrbButton(
      {super.key,
      required this.mode,
      required this.onTap,
      this.enabled = true,
      this.size = 54});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;

    return BreathingGlow(
      enabled: enabled,
      glowColor: p.glowA,
      maxBlur: 22,
      maxAlpha: 0.18,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.25, -0.35),
              colors: [
                Colors.white.withValues(alpha: 0.22),
                p.glowA.withValues(alpha: 0.86),
                p.bg1.withValues(alpha: 0.92),
                Colors.black.withValues(alpha: 0.82),
              ],
              stops: const [0.0, 0.24, 0.66, 1.0],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: p.glowA.withValues(alpha: 0.24),
                blurRadius: 24,
                spreadRadius: -8,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 18,
                spreadRadius: -7,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PostRitualRingPainter(
                      accent: p.glowA,
                      secondary: p.glowB,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: size * 0.185,
                left: size * 0.222,
                right: size * 0.222,
                child: Container(
                  height: size * 0.296,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.white.withValues(alpha: 0.0)
                      ],
                    ),
                  ),
                ),
              ),
              Icon(Icons.add_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: size * 0.50),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostRitualRingPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  const _PostRitualRingPainter({
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        colors: [
          accent.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.18),
          secondary.withValues(alpha: 0.16),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.shortestSide * 0.38),
      -0.8,
      4.6,
      false,
      paint,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..blendMode = BlendMode.plus
        ..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant _PostRitualRingPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.secondary != secondary;
  }
}
