import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';

/// Spec component: TruluraProfileTabBar.
///
/// Wraps TabBar in a Trulura glass surface and uses a gradient underline.
class TruluraProfileTabBar extends StatelessWidget {
  final TabController controller;
  final List<Tab> tabs;

  const TruluraProfileTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final phase =
            controller.animation?.value ?? controller.index.toDouble();
        return TruLuraGlassCard(
          tone: TruLuraModeTone.aura,
          radius: 24,
          glow: TruLuraTokens.auraViolet,
          tint: TruLuraTokens.auraViolet.withValues(alpha: 0.030),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TabAuraPainter(
                      phase: phase,
                      tabCount: tabs.length,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStatePropertyAll(
                  TruLuraTokens.auraViolet.withValues(alpha: 0.08),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicator: _GradientUnderlineIndicator(
                  thickness: 4.0,
                  radius: 999,
                  gradient: LinearGradient(colors: [
                    TruLuraTokens.auraPink.withValues(alpha: 0.95),
                    TruLuraTokens.auraCyan.withValues(alpha: 0.70),
                    TruLuraTokens.auraViolet.withValues(alpha: 0.95)
                  ]),
                ),
                labelColor: cs.onSurface,
                unselectedLabelColor: cs.onSurface.withValues(alpha: 0.60),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                tabs: tabs,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabAuraPainter extends CustomPainter {
  final double phase;
  final int tabCount;

  const _TabAuraPainter({
    required this.phase,
    required this.tabCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || tabCount == 0) return;
    final rect = Offset.zero & size;
    final normalized = (phase / (tabCount - 1).clamp(1, 99)).clamp(0.0, 1.0);
    final center = Alignment(-0.92 + normalized * 1.84, 0.15);
    final aura = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: center,
        radius: 0.48,
        colors: [
          TruLuraTokens.auraPink.withValues(alpha: 0.16),
          TruLuraTokens.auraCyan.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, aura);

    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = TruLuraTokens.auraCyan.withValues(alpha: 0.12);
    final y = size.height * 0.70;
    final path = Path()..moveTo(size.width * 0.08, y);
    path.cubicTo(size.width * 0.28, y - 5, size.width * 0.62, y + 6,
        size.width * 0.92, y - 2);
    canvas.drawPath(path, wave);
  }

  @override
  bool shouldRepaint(covariant _TabAuraPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.tabCount != tabCount;
  }
}

class _GradientUnderlineIndicator extends Decoration {
  final double thickness;
  final double radius;
  final LinearGradient gradient;

  const _GradientUnderlineIndicator(
      {required this.thickness, required this.radius, required this.gradient});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GradientUnderlinePainter(
          thickness: thickness, radius: radius, gradient: gradient);
}

class _GradientUnderlinePainter extends BoxPainter {
  final double thickness;
  final double radius;
  final LinearGradient gradient;

  _GradientUnderlinePainter(
      {required this.thickness, required this.radius, required this.gradient});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;

    final Rect rect = offset & size;
    final double y = rect.bottom - thickness;
    final Rect underline = Rect.fromLTWH(rect.left, y, rect.width, thickness);
    final RRect rrect =
        RRect.fromRectAndRadius(underline, Radius.circular(radius));

    final Paint paint = Paint()..shader = gradient.createShader(underline);
    canvas.drawRRect(rrect, paint);
  }
}
