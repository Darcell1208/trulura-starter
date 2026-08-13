import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class TruWorldStage extends StatelessWidget {
  final String overline;
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color primary;
  final Color secondary;
  final String focalLabel;
  final String focalValue;
  final String atmosphereLabel;
  final String heroLabel;
  final String identityLabel;
  final String identityValue;
  final String interactionLabel;
  final String contentLabel;
  final List<Widget> guidance;
  final List<Widget> portals;
  final double minHeight;

  const TruWorldStage({
    super.key,
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.primary,
    required this.secondary,
    required this.focalLabel,
    required this.focalValue,
    this.atmosphereLabel = 'Emotional environment',
    this.heroLabel = 'Focal experience',
    this.identityLabel = 'World identity',
    this.identityValue = 'Living space',
    this.interactionLabel = 'Core actions',
    this.contentLabel = 'Story continues',
    this.guidance = const <Widget>[],
    this.portals = const <Widget>[],
    this.minHeight = 430,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -80,
            top: -40,
            width: 320,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: soft ? 0.08 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _WorldAtmospherePainter(
                primary: primary,
                secondary: secondary,
                soft: soft,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    TruLuraTokens.ink.withValues(alpha: 0.10),
                    TruLuraTokens.ink.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 26, 8, 22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 820;
                final narrative = _WorldNarrative(
                  overline: overline,
                  title: title,
                  subtitle: subtitle,
                  glyph: glyph,
                  primary: primary,
                  secondary: secondary,
                  atmosphereLabel: atmosphereLabel,
                  heroLabel: heroLabel,
                  identityLabel: identityLabel,
                  identityValue: identityValue,
                  interactionLabel: interactionLabel,
                  contentLabel: contentLabel,
                  guidance: guidance,
                );
                final focal = TruWorldFocal(
                  label: focalLabel,
                  value: focalValue,
                  glyph: glyph,
                  primary: primary,
                  secondary: secondary,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      narrative,
                      const SizedBox(height: 24),
                      Center(child: focal),
                      if (portals.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        TruPortalRail(children: portals),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 6, child: narrative),
                        const SizedBox(width: 28),
                        Expanded(flex: 4, child: focal),
                      ],
                    ),
                    if (portals.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      TruPortalRail(children: portals),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldNarrative extends StatelessWidget {
  final String overline;
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color primary;
  final Color secondary;
  final String atmosphereLabel;
  final String heroLabel;
  final String identityLabel;
  final String identityValue;
  final String interactionLabel;
  final String contentLabel;
  final List<Widget> guidance;

  const _WorldNarrative({
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.primary,
    required this.secondary,
    required this.atmosphereLabel,
    required this.heroLabel,
    required this.identityLabel,
    required this.identityValue,
    required this.interactionLabel,
    required this.contentLabel,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WorldGlyph(glyph: glyph, primary: primary, secondary: secondary),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                overline.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: TruLuraTokens.textPrimary,
                  fontFamily: 'Georgia',
                  height: 1.02,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TruLuraTokens.textSecondary,
                  height: 1.5,
                ),
          ),
        ),
        if (guidance.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(spacing: 10, runSpacing: 10, children: guidance),
        ],
      ],
    );
  }
}

class TruWorldFocal extends StatelessWidget {
  final String label;
  final String value;
  final TruLuraGlyph glyph;
  final Color primary;
  final Color secondary;

  const TruWorldFocal({
    super.key,
    required this.label,
    required this.value,
    required this.glyph,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: CustomPaint(
        painter: _FocalOrbitPainter(primary: primary, secondary: secondary),
        child: Center(
          child: Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: 0.34),
                  secondary.withValues(alpha: 0.18),
                  TruLuraTokens.ink.withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 42,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TruLuraIcon(
                    glyph: glyph, active: true, size: 34, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: TruLuraTokens.textPrimary,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TruLuraTokens.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TruWorldAction extends StatelessWidget {
  final String label;
  final TruLuraGlyph glyph;
  final Color accent;
  final VoidCallback? onTap;
  final bool primary;

  const TruWorldAction({
    super.key,
    required this.label,
    required this.glyph,
    required this.accent,
    this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: primary
                ? [
                    accent.withValues(alpha: 0.48),
                    TruLuraBrandColors.glowGold.withValues(alpha: 0.28),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.075),
                    Colors.white.withValues(alpha: 0.030),
                  ],
          ),
          border: Border.all(
            color: (primary ? accent : Colors.white).withValues(alpha: 0.22),
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.24),
                    blurRadius: 24,
                    spreadRadius: -8,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TruLuraIcon(glyph: glyph, active: primary, size: 17, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TruLuraTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class TruRealmPortal extends StatelessWidget {
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color accent;
  final VoidCallback? onTap;

  const TruRealmPortal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 220,
        height: 154,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PortalPainter(accent: accent),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.13)),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WorldGlyph(
                        glyph: glyph, primary: accent, secondary: Colors.white),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: TruLuraTokens.textPrimary,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TruLuraTokens.textSecondary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TruPortalRail extends StatelessWidget {
  final List<Widget> children;

  const TruPortalRail({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _WorldGlyph extends StatelessWidget {
  final TruLuraGlyph glyph;
  final Color primary;
  final Color secondary;

  const _WorldGlyph({
    required this.glyph,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            primary.withValues(alpha: 0.36),
            secondary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: TruLuraIcon(
          glyph: glyph, active: true, size: 21, color: Colors.white),
    );
  }
}

class _WorldAtmospherePainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final bool soft;

  const _WorldAtmospherePainter({
    required this.primary,
    required this.secondary,
    required this.soft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF02030A),
            const Color(0xFF060A1C),
            primary.withValues(alpha: soft ? 0.14 : 0.30),
            secondary.withValues(alpha: soft ? 0.08 : 0.20),
          ],
        ).createShader(rect),
    );

    final nebula = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: const Alignment(0.35, -0.32),
        radius: 0.92,
        colors: [
          secondary.withValues(alpha: soft ? 0.10 : 0.32),
          primary.withValues(alpha: soft ? 0.06 : 0.18),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebula);

    final horizon = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          TruLuraBrandColors.glowGold.withValues(alpha: soft ? 0.06 : 0.18),
          secondary.withValues(alpha: soft ? 0.06 : 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.56, size.width, 96));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.56, size.width, 96), horizon);

    final stars = Paint()
      ..color = Colors.white.withValues(alpha: soft ? 0.09 : 0.24);
    for (var i = 0; i < (soft ? 24 : 80); i++) {
      final x = ((math.sin(i * 43.11) + 1) / 2) * size.width;
      final y = ((math.cos(i * 27.73) + 1) / 2) * size.height * 0.76;
      canvas.drawCircle(Offset(x, y), i % 11 == 0 ? 1.2 : 0.55, stars);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldAtmospherePainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.soft != soft;
  }
}

class _FocalOrbitPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  const _FocalOrbitPainter({required this.primary, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 6; i++) {
      final radius = 54.0 + i * 18.0;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawOval(
        rect.inflate(i.isEven ? 10 : -4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? 2.2 : 1
          ..shader = SweepGradient(
            colors: [
              primary.withValues(alpha: 0.45),
              secondary.withValues(alpha: 0.30),
              TruLuraBrandColors.glowGold.withValues(alpha: 0.22),
              primary.withValues(alpha: 0.45),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocalOrbitPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}

class _PortalPainter extends CustomPainter {
  final Color accent;

  const _PortalPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TruLuraTokens.ink.withValues(alpha: 0.94),
            accent.withValues(alpha: 0.22),
            TruLuraTokens.deepIndigo.withValues(alpha: 0.72),
          ],
        ).createShader(rect),
    );
    final center = Offset(size.width * 0.72, size.height * 0.34);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        center,
        22 + i * 18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent.withValues(alpha: 0.28 - i * 0.045),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PortalPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
