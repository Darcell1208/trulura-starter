import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_safe_avatar.dart';

/// Circular avatar with a neon halo glow behind it.
///
/// Defaults to a blue/purple cosmic aura (requested). Use [tone] to match
/// Mode styling.
class TruLuraHaloAvatar extends StatefulWidget {
  final ImageProvider<Object>? image;
  final double radius;
  final Widget? fallback;
  final TruLuraModeTone tone;

  /// Optional match score (0.0 → 1.0). When provided, shows a % badge.
  final double? matchPercent;

  /// Sync-only: when true, the halo pulses (matched state).
  final bool matched;

  const TruLuraHaloAvatar({
    super.key,
    required this.radius,
    this.image,
    this.fallback,
    this.tone = TruLuraModeTone.aura,
    this.matched = false,
    this.matchPercent,
  });

  @override
  State<TruLuraHaloAvatar> createState() => _TruLuraHaloAvatarState();
}

class _TruLuraHaloAvatarState extends State<TruLuraHaloAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant TruLuraHaloAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pulse.isAnimating) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (a, b) = widget.tone.resolve(cs);
    final glowScale = context.watch<AppProvider>().glowScale;
    final softMode = context.watch<AppProvider>().softModeEnabled;

    final haloIntensity = switch (widget.tone) {
          TruLuraModeTone.sync => 1.40,
          TruLuraModeTone.explore => 1.25,
          TruLuraModeTone.profile => 1.28,
          TruLuraModeTone.messages => 1.12,
          TruLuraModeTone.notifications => 1.18,
          TruLuraModeTone.aura => 1.15,
        } *
        glowScale *
        (softMode ? 0.72 : 1.0);

    final haloSize = widget.radius * 2.25;
    final ring = (widget.radius * 2) * 0.14;
    final matchValue = widget.matchPercent;
    return SizedBox(
      width: haloSize,
      height: haloSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (cinematic aura)
          if (!softMode)
            IgnorePointer(
              child: Container(
                width: widget.radius * 2 + ring * 2,
                height: widget.radius * 2 + ring * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        a.withValues(alpha: 0.95),
                        b.withValues(alpha: 0.95)
                      ]),
                  boxShadow: TruLuraTokens.softGlow(TruLuraTokens.auraPink),
                ),
              ),
            ),

          // Inner dark ring
          IgnorePointer(
            child: Container(
              width: widget.radius * 2 + ring,
              height: widget.radius * 2 + ring,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TruLuraTokens.ink.withValues(alpha: 0.55)),
            ),
          ),

          if (!softMode)
            IgnorePointer(
              child: Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      a.withValues(alpha: 0.26),
                      b.withValues(alpha: 0.18),
                      Colors.transparent
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ),

          // Locked: Sync halo ring system.
          if (widget.tone == TruLuraModeTone.sync)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = widget.matched && !softMode ? _pulse.value : 0.0;
                final outerGlow = (0.55 + (widget.matched ? 0.10 : 0.0)) *
                    (softMode ? 0.65 : 1.0);
                final blur = 30.0 * (1.0 + 0.18 * t);
                return Container(
                  width: widget.radius * 2 + 10,
                  height: widget.radius * 2 + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF8B4DFF), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromRGBO(150, 70, 255, 1)
                              .withValues(alpha: outerGlow),
                          blurRadius: blur,
                          offset: Offset.zero),
                      BoxShadow(
                        color: const Color.fromRGBO(255, 110, 170, 1)
                            .withValues(
                                alpha:
                                    (0.35 + 0.04 * (widget.matched ? 1 : 0)) *
                                        (softMode ? 0.60 : 1.0)),
                        blurRadius: 25,
                        offset: Offset.zero,
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                );
              },
            )
          else if (!softMode && glowScale > 0.38)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return IgnorePointer(
                  child: CustomPaint(
                    size: Size.square(haloSize),
                    painter: _HaloRingPainter(
                      a: a,
                      b: b,
                      progress: _pulse.value,
                      matched: widget.matched,
                      matchPercent: widget.matchPercent,
                    ),
                  ),
                );
              },
            ),

          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: softMode
                    ? []
                    : TruLuraEffects.multiAuraGlow(a, b,
                        intensity: haloIntensity)),
            child: TruLuraSafeAvatar(
              radius: widget.radius,
              image: widget.image,
              fallback: widget.fallback ??
                  TruLuraIcon(glyph: TruLuraGlyph.person, size: widget.radius),
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.75),
            ),
          ),

          if (matchValue != null)
            Positioned(
              right: 0,
              bottom: 2,
              child: _PercentBadge(value: (matchValue * 100).round()),
            ),
        ],
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final int value;

  const _PercentBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: TruLuraTokens.auraGradient(opacity: 1),
        boxShadow: TruLuraTokens.softGlow(TruLuraTokens.auraViolet),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$value%',
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.2),
      ),
    );
  }
}

class _HaloRingPainter extends CustomPainter {
  final Color a;
  final Color b;
  final double progress;
  final bool matched;
  final double? matchPercent;

  _HaloRingPainter({
    required this.a,
    required this.b,
    required this.progress,
    required this.matched,
    required this.matchPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final stroke = size.shortestSide * 0.06;
    final ringRect = rect.deflate(stroke * 0.8);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: [
          a.withValues(alpha: 0.95),
          b.withValues(alpha: 0.75),
          a.withValues(alpha: 0.95)
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.9)
      ..blendMode = BlendMode.plus;

    canvas.drawOval(ringRect, paint);

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.46
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        transform: GradientRotation(progress * 6.28318),
        colors: [
          Colors.transparent,
          a.withValues(alpha: matched ? 0.56 : 0.34),
          b.withValues(alpha: matchPercent != null ? 0.62 : 0.30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.46, 1.0],
      ).createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.42);
    canvas.drawArc(
      ringRect.inflate(stroke * 1.45),
      progress * 6.28318 - 1.1,
      matched ? 2.9 : 2.15,
      false,
      orbitPaint,
    );

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;
    final energy = (matchPercent ?? (matched ? 0.82 : 0.46)).clamp(0.0, 1.0);
    for (var i = 0; i < 3; i++) {
      final angle = progress * 6.28318 + i * 2.094;
      final radius = size.shortestSide * (0.42 + i * 0.025);
      final dot = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * radius * 0.88,
      );
      dotPaint.color =
          (i.isEven ? a : b).withValues(alpha: (0.18 + 0.20 * energy));
      canvas.drawCircle(dot, stroke * (0.42 + energy * 0.18), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloRingPainter oldDelegate) =>
      oldDelegate.a != a ||
      oldDelegate.b != b ||
      oldDelegate.progress != progress ||
      oldDelegate.matched != matched ||
      oldDelegate.matchPercent != matchPercent;
}
