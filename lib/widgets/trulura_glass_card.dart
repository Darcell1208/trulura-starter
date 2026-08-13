import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';

/// A reusable glassmorphism surface for TruLura.
///
/// Use this instead of [Card] when you need true cinematic glass:
/// - Blur behind the surface
/// - Low-opacity gradient fill
/// - Faint neon edge glow (blue/purple)
class TruLuraGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? glow;
  final TruLuraModeTone tone;
  final VoidCallback? onTap;

  /// Adds a subtle dark depth shadow under the glass.
  ///
  /// This is intentionally separate from the neon edge glow and is useful for
  /// feed cards that should feel like they're floating above the background.
  final bool depth;

  /// Optional quick tint override used by the lightweight TruLura UI Kit.
  ///
  /// When provided, we treat it as a fill override (and derive a slightly
  /// stronger secondary fill) while preserving the rest of the glass styling.
  ///
  /// This keeps existing advanced palette behavior intact, but allows snippets
  /// like `TruLuraGlassCard(tint: Colors.white.withValues(alpha: 0.06))`.
  final Color? tint;

  /// Draw a subtle gradient stroke (neon edge) instead of a flat border.
  ///
  /// Enabled by default because it matches the TruLura “main standard” comps.
  /// Automatically disabled in Soft Mode.
  final bool gradientStroke;

  /// Alias for [paletteMode]. This exists to support older snippets that use
  /// `TruLuraGlassCard(mode: ...)`.
  ///
  /// Prefer [paletteMode] in new code.
  final TruLuraMode? mode;

  /// Optional palette override for when you want this glass surface to be
  /// driven by the global TruLura mode palettes (bg/card/border/glow).
  ///
  /// When provided, this will override fill/border/glow (but still respects
  /// soft-mode blur reduction and the general glass styling of this widget).
  final TruLuraMode? paletteMode;

  /// Optional overrides for mode-specific surfaces (e.g., Sync feed cards).
  final Color? fillAOverride;
  final Color? fillBOverride;
  final Color? borderColorOverride;
  final double? blurSigmaOverride;

  const TruLuraGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = TruLuraTokens.r20,
    this.blur = TruLuraTokens.glassBlur,
    this.glow,
    this.tone = TruLuraModeTone.aura,
    this.onTap,
    this.depth = false,
    this.tint,
    this.gradientStroke = true,
    this.mode,
    this.paletteMode,
    this.fillAOverride,
    this.fillBOverride,
    this.borderColorOverride,
    this.blurSigmaOverride,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      mode == null || paletteMode == null,
      'Provide only one of `mode` or `paletteMode`.',
    );

    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final brightness = Theme.of(context).brightness;
    final (a, b) = tone.resolve(cs);

    final effectiveMode = paletteMode ?? mode;
    final TruLuraMode? m = effectiveMode;
    final TruLuraPalette? palette = m == null ? null : kTruLuraPalettes[m];

    final glowColor = glow ?? palette?.glowA ?? a;
    final blurSigma = blurSigmaOverride ?? (soft ? blur * 0.45 : blur);

    final List<BoxShadow> depthShadow = (depth || brightness == Brightness.dark)
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: depth ? 0.58 : 0.38),
              blurRadius: depth ? 46 : 32,
              spreadRadius: depth ? -14 : -14,
              offset: Offset(0, depth ? 22 : 14),
            ),
            if (brightness == Brightness.dark)
              BoxShadow(
                color: glowColor.withValues(
                  alpha:
                      ((depth ? 0.18 : 0.105) * app.glowScale).clamp(0.0, 1.0),
                ),
                blurRadius: depth ? 58 : 38,
                spreadRadius: -18,
                offset: const Offset(0, 26),
              ),
          ]
        : const <BoxShadow>[];

    // Locked glass surface (reference CSS)
    // background: rgba(20, 28, 60, 0.55); blur: 16px;
    final derivedFillA = tint;
    final derivedFillB =
        tint?.withValues(alpha: (tint!.a + 0.04).clamp(0.0, 1.0));

    final fillA = fillAOverride ??
        derivedFillA ??
        (palette?.card ??
            (brightness == Brightness.dark
                ? TruLuraTokens.nebula.withValues(alpha: 0.26)
                : cs.surface.withValues(alpha: 0.85)));
    final fillB = fillBOverride ??
        derivedFillB ??
        (palette == null
            ? (brightness == Brightness.dark
                ? TruLuraTokens.ink.withValues(alpha: 0.34)
                : cs.surfaceContainerHighest.withValues(alpha: 0.72))
            : palette.card
                .withValues(alpha: (palette.card.a + 0.06).clamp(0.0, 1.0)));

    final edgeGlow = brightness == Brightness.dark
        ? [
            ...depthShadow,
            if (!soft)
              ...TruLuraTokens.softGlow(glowColor).map(
                (s) => s.copyWith(
                  color: s.color.withValues(
                    alpha: (s.color.a * 1.18 * app.glowScale).clamp(0.0, 1.0),
                  ),
                ),
              ),
            if (!soft)
              ...TruLuraEffects.softGlow(
                palette?.glowB ?? b,
                intensity: 0.075 * app.glowScale,
              ),

            // Signature TruLura aura glow (premium depth). Kept subtle and
            // auto-attenuated by glowScale + Soft Mode.
            if (!soft)
              BoxShadow(
                color: (palette?.glowB ?? b)
                    .withValues(alpha: (0.34 * app.glowScale).clamp(0.0, 1.0)),
                blurRadius: 54,
                spreadRadius: -16,
                offset: const Offset(0, 20),
              ),
          ]
        : <BoxShadow>[];

    // If a global palette mode is provided (mode/paletteMode), we support the
    // more "locked" glass spec that uses palette.card + palette.border and a
    // subtle internal sheen gradient.
    final bool useLockedModeSpec = palette != null &&
        fillAOverride == null &&
        fillBOverride == null &&
        borderColorOverride == null;

    final bool useGradientStroke =
        gradientStroke && !soft && brightness == Brightness.dark;
    final Color strokeFallback = borderColorOverride ??
        (palette?.border ??
            (brightness == Brightness.dark
                ? Colors.white.withValues(alpha: TruLuraTokens.strokeOpacity)
                : Colors.black.withValues(alpha: 0.08)));

    final LinearGradient strokeGradient = LinearGradient(
      begin: const Alignment(-1, -1),
      end: const Alignment(1, 1),
      colors: [
        (palette?.glowB ?? b).withValues(alpha: 0.75),
        (palette?.glowA ?? a).withValues(alpha: 0.65),
        Colors.white.withValues(alpha: 0.18),
      ],
      stops: const [0.0, 0.62, 1.0],
    );

    final Widget content = useLockedModeSpec
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                          color: useGradientStroke
                              ? Colors.transparent
                              : palette.border.withValues(alpha: 0.88),
                          width: TruLuraSurfaces.hairline),
                      boxShadow: brightness == Brightness.dark
                          ? [
                              ...depthShadow,
                              if (!soft)
                                BoxShadow(
                                  blurRadius: 28,
                                  spreadRadius: -6,
                                  color: palette.glowA.withValues(
                                      alpha: (0.18 * app.glowScale)
                                          .clamp(0.0, 1.0)),
                                  offset: const Offset(0, 14),
                                ),
                              if (!soft)
                                BoxShadow(
                                  color: palette.glowB.withValues(
                                      alpha: (0.25 * app.glowScale)
                                          .clamp(0.0, 1.0)),
                                  blurRadius: 35,
                                  spreadRadius: -12,
                                  offset: const Offset(0, 20),
                                ),
                            ]
                          : const <BoxShadow>[],
                    ),
                    child: Container(
                      padding: padding,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: const Alignment(-1, -1),
                          end: const Alignment(1, 1),
                          colors: [
                            Colors.white.withValues(alpha: 0.075),
                            Colors.transparent,
                            palette.glowB.withValues(alpha: 0.105),
                            Colors.black.withValues(alpha: 0.12),
                          ],
                          stops: const [0.0, 0.42, 0.82, 1.0],
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  if (brightness == Brightness.dark && !soft)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GlassBloomPainter(
                            radius: radius,
                            accentA: palette.glowA,
                            accentB: palette.glowB,
                          ),
                        ),
                      ),
                    ),
                  if (useGradientStroke)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GradientStrokePainter(
                              radius: radius,
                              width: TruLuraSurfaces.hairline,
                              gradient: strokeGradient),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.060),
                          fillA,
                          fillB,
                          Colors.black.withValues(alpha: 0.10),
                        ],
                        stops: const [0.0, 0.30, 0.78, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                          color: useGradientStroke
                              ? Colors.transparent
                              : strokeFallback,
                          width: TruLuraSurfaces.hairline),
                      boxShadow: edgeGlow,
                    ),
                    child: Padding(padding: padding, child: child),
                  ),
                  if (brightness == Brightness.dark && !soft)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GlassBloomPainter(
                            radius: radius,
                            accentA: glowColor,
                            accentB: palette?.glowB ?? b,
                          ),
                        ),
                      ),
                    ),
                  if (useGradientStroke)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GradientStrokePainter(
                              radius: radius,
                              width: TruLuraSurfaces.hairline,
                              gradient: strokeGradient),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );

    if (onTap == null) return content;
    return _EmotionPressSurface(
      onTap: onTap!,
      glowColor: glowColor,
      child: content,
    );
  }
}

class _EmotionPressSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color glowColor;

  const _EmotionPressSurface({
    required this.child,
    required this.onTap,
    required this.glowColor,
  });

  @override
  State<_EmotionPressSurface> createState() => _EmotionPressSurfaceState();
}

class _EmotionPressSurfaceState extends State<_EmotionPressSurface> {
  bool _hovered = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final active = _hovered || _pressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          duration: app.motionDuration,
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.992 : 1,
          child: AnimatedContainer(
            duration: app.motionDuration,
            curve: Curves.easeOutCubic,
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(
                          alpha: (_hovered ? 0.12 : 0.08) * app.glowScale,
                        ),
                        blurRadius: _hovered ? 30 : 18,
                        spreadRadius: -16,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Back-compat alias used by some early snippets.
///
/// Prefer [TruLuraGlassCard] in new code.
class TruluraGlassCard extends TruLuraGlassCard {
  const TruluraGlassCard({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(16),
    super.radius = 22,
    super.blur = 18,
    super.glow,
    super.tone = TruLuraModeTone.aura,
    super.onTap,
    super.depth = false,
    super.tint,
    super.gradientStroke = true,
    super.mode,
    super.paletteMode,
    super.fillAOverride,
    super.fillBOverride,
  });
}

class _GlassBloomPainter extends CustomPainter {
  final double radius;
  final Color accentA;
  final Color accentB;

  const _GlassBloomPainter({
    required this.radius,
    required this.accentA,
    required this.accentB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final clip = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(clip);
    final paint = Paint()..blendMode = BlendMode.screen;

    paint.shader = RadialGradient(
      colors: [
        accentA.withValues(alpha: 0.135),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.18, size.height * 0.06),
      radius: size.shortestSide * 0.72,
    ));
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader = RadialGradient(
      colors: [
        accentB.withValues(alpha: 0.105),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.90, size.height * 1.04),
      radius: size.shortestSide * 0.80,
    ));
    canvas.drawRect(Offset.zero & size, paint);

    final edgePaint = Paint()
      ..blendMode = BlendMode.screen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          accentA.withValues(alpha: 0.14),
          Colors.transparent,
          accentB.withValues(alpha: 0.16),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ).deflate(0.5),
      edgePaint,
    );
    final falloffPaint = Paint()
      ..blendMode = BlendMode.multiply
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.12),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, falloffPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassBloomPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB;
  }
}

class _GradientStrokePainter extends CustomPainter {
  final double radius;
  final double width;
  final Gradient gradient;

  const _GradientStrokePainter(
      {required this.radius, required this.width, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          width / 2, width / 2, size.width - width, size.height - width),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = gradient.createShader(Offset.zero & size);
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientStrokePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.width != width ||
        oldDelegate.gradient != gradient;
  }
}
