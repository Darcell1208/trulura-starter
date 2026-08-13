import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';

class AuraBackground extends StatefulWidget {
  final Widget child;
  final Color accentA;
  final Color accentB;
  final bool includeHeroGlow;

  const AuraBackground({
    super.key,
    required this.child,
    this.accentA = TruLuraTokens.auraViolet,
    this.accentB = TruLuraTokens.auraPink,
    this.includeHeroGlow = true,
  });

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (!context.read<AppProvider>().softModeEnabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final soft = context.watch<AppProvider>().softModeEnabled;
    if (soft && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.22;
    } else if (!soft && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soft = context.watch<AppProvider>().softModeEnabled;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = soft ? 0.18 : Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF02040D),
                Color(0xFF060914),
                Color(0xFF0B1028),
                Color(0xFF070817),
              ],
              stops: [0, 0.34, 0.70, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarfieldPainter(
                    t: t,
                    accentA: widget.accentA,
                    accentB: widget.accentB,
                    soft: soft,
                  ),
                ),
              ),
              if (widget.includeHeroGlow)
                Positioned(
                  right: -120 + t * 70,
                  top: -80 + t * 54,
                  width: 430,
                  height: 430,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            widget.accentB.withValues(
                              alpha: soft ? 0.060 : 0.20,
                            ),
                            widget.accentA.withValues(
                              alpha: soft ? 0.035 : 0.12,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: -150,
                bottom: -170 + t * 34,
                width: 460,
                height: 460,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          TruLuraTokens.auraCyan.withValues(
                            alpha: soft ? 0.040 : 0.13,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  final Color accentA;
  final Color accentB;
  final bool soft;

  const _StarfieldPainter({
    required this.t,
    required this.accentA,
    required this.accentB,
    required this.soft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final nebula = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.4 + t * 0.22, -0.55),
        radius: 0.95,
        colors: [
          accentA.withValues(alpha: soft ? 0.070 : 0.17),
          accentB.withValues(alpha: soft ? 0.035 : 0.10),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebula);

    final dust = Paint()
      ..color = Colors.white.withValues(alpha: soft ? 0.08 : 0.22);
    final count = soft ? 26 : 74;
    for (var i = 0; i < count; i++) {
      final x = ((math.sin(i * 41.13 + t) + 1) / 2) * size.width;
      final y = ((math.cos(i * 17.71 - t) + 1) / 2) * size.height;
      final r = i % 9 == 0 ? 1.15 : 0.55;
      canvas.drawCircle(Offset(x, y), r, dust);
    }

    final curve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: soft ? 0.08 : 0.24),
          accentB.withValues(alpha: soft ? 0.06 : 0.20),
          Colors.transparent,
        ],
      ).createShader(rect);
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * (0.18 + t * 0.03))
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.06,
        size.width * 0.66,
        size.height * 0.36,
        size.width * 0.92,
        size.height * (0.20 - t * 0.04),
      );
    canvas.drawPath(path, curve);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.soft != soft;
  }
}
