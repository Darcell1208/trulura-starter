import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/post_orb_button.dart';
import 'package:trulura/widgets/breathing_glow.dart';

class TruLuraBottomNav extends StatelessWidget {
  /// When provided, the nav uses the corresponding palette for glow + accents.
  ///
  /// If null, we fall back to the current mode from [TruLuraModeController] to
  /// keep existing screens working.
  final TruLuraMode? mode;

  final int index;

  /// New preferred callback name (matches snippet API).
  final ValueChanged<int>? onTap;

  /// Back-compat callback name.
  final ValueChanged<int>? onSelect;

  final VoidCallback onPost;
  final VoidCallback? onOpenProfile;

  /// Optional overrides for using your exact concept PNG icons.
  ///
  /// Example:
  /// ```dart
  /// assetIconOverrides: {
  ///   TruLuraGlyph.aura: TruLuraAssets.navAuraSuggested,
  /// }
  /// ```
  final Map<TruLuraGlyph, String>? assetIconOverrides;

  const TruLuraBottomNav({
    super.key,
    this.mode,
    required this.index,
    this.onTap,
    this.onSelect,
    required this.onPost,
    this.onOpenProfile,
    this.assetIconOverrides,
  }) : assert(onTap == null || onSelect == null,
            'Provide only one of onTap or onSelect.');

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final fallbackMode = context.watch<TruLuraModeController>().mode;
    final resolvedMode = mode ?? fallbackMode;
    final isWideLayout = MediaQuery.sizeOf(context).width >= 700;
    final compactDesktopNav = kIsWeb || isWideLayout;
    final navHeight = compactDesktopNav ? 58.0 : 64.0;
    final bottomPadding = compactDesktopNav ? 12.0 : 14.0;
    final verticalPadding = compactDesktopNav ? 7.0 : 9.0;
    final postSlotWidth = compactDesktopNav ? 50.0 : 56.0;
    final postOrbSize = compactDesktopNav ? 38.0 : 42.0;
    final palette = kTruLuraPalettes[resolvedMode]!;

    final handleTap = onTap ?? onSelect;
    if (handleTap == null) {
      throw FlutterError('TruLuraBottomNav requires either onTap or onSelect.');
    }

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
          child: _MagneticDockPresence(
            glow: palette.glowA,
            enabled: !soft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.72),
                    blurRadius: 48,
                    spreadRadius: -18,
                    offset: const Offset(0, 22),
                  ),
                  if (!soft)
                    BoxShadow(
                      color:
                          palette.glowA.withValues(alpha: 0.11 * app.glowScale),
                      blurRadius: 58,
                      spreadRadius: -24,
                      offset: const Offset(-10, 18),
                    ),
                ],
              ),
              child: SizedBox(
                height: navHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.82),
                          TruLuraTokens.ink.withValues(alpha: 0.86),
                          palette.bg0.withValues(alpha: 0.54),
                        ],
                      ),
                      border: Border.all(
                        color:
                            Colors.white.withValues(alpha: soft ? 0.08 : 0.06),
                        width: TruLuraSurfaces.hairline,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _DockAtmospherePainter(
                                accentA: palette.glowA,
                                accentB: palette.glowB,
                                intensity: soft ? 0.32 : app.glowScale,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: -18,
                          height: 42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  palette.glowA.withValues(
                                      alpha:
                                          soft ? 0.05 : 0.12 * app.glowScale),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compactDesktopNav ? 10 : 12,
                              vertical: verticalPadding),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: _NavItem(
                                      mode: resolvedMode,
                                      selected: index == 0,
                                      label: 'Worlds',
                                      glyph: TruLuraGlyph.explore,
                                      onTap: () => handleTap(0),
                                      assetPath: assetIconOverrides?[
                                          TruLuraGlyph.aura])),
                              Expanded(
                                  child: _NavItem(
                                      mode: resolvedMode,
                                      selected: index == 1,
                                      label: 'Connect',
                                      glyph: TruLuraGlyph.messages,
                                      onTap: () => handleTap(1),
                                      assetPath: assetIconOverrides?[
                                          TruLuraGlyph.messages])),
                              SizedBox(
                                width: postSlotWidth,
                                child: Center(
                                  child: BreathingGlow(
                                    glowColor:
                                        kTruLuraPalettes[resolvedMode]!.glowA,
                                    enabled: !soft,
                                    maxBlur: 24,
                                    maxAlpha: 0.20,
                                    child: PostOrbButton(
                                        mode: resolvedMode,
                                        onTap: onPost,
                                        size: postOrbSize),
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: _NavItem(
                                      mode: resolvedMode,
                                      selected: index == 2,
                                      label: 'Pulse',
                                      glyph: TruLuraGlyph.inbox,
                                      onTap: () => handleTap(2),
                                      assetPath: assetIconOverrides?[
                                          TruLuraGlyph.inbox])),
                              Expanded(
                                child: _NavItem(
                                  mode: resolvedMode,
                                  selected: index == 3,
                                  label: 'Identity',
                                  glyph: TruLuraGlyph.person,
                                  onTap: onOpenProfile ?? () => handleTap(3),
                                  assetPath:
                                      assetIconOverrides?[TruLuraGlyph.person],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MagneticDockPresence extends StatefulWidget {
  final Widget child;
  final Color glow;
  final bool enabled;

  const _MagneticDockPresence({
    required this.child,
    required this.glow,
    required this.enabled,
  });

  @override
  State<_MagneticDockPresence> createState() => _MagneticDockPresenceState();
}

class _MagneticDockPresenceState extends State<_MagneticDockPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.enabled) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MagneticDockPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _breath.repeat(reverse: true);
    } else if (oldWidget.enabled && !widget.enabled) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_breath.value);
        return Transform.translate(
          offset: Offset(0, -1.5 - t * 1.6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: widget.glow.withValues(alpha: 0.055 + t * 0.045),
                  blurRadius: 34 + t * 18,
                  spreadRadius: -16,
                  offset: Offset(0, 12 + t * 3),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _NavItem extends StatefulWidget {
  final TruLuraMode mode;
  final bool selected;
  final String label;
  final TruLuraGlyph glyph;
  final VoidCallback onTap;
  final String? assetPath;

  const _NavItem(
      {required this.mode,
      required this.selected,
      required this.label,
      required this.glyph,
      required this.onTap,
      this.assetPath});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.selected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _pulseController.repeat(reverse: true);
    } else if (oldWidget.selected && !widget.selected) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final p = kTruLuraPalettes[widget.mode]!;

    final Color color;
    if (widget.selected && !soft) {
      color = cs.onSurface;
    } else {
      color = TruLuraTokens.textMuted;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = widget.selected && !soft
            ? Curves.easeInOut.transform(_pulseController.value)
            : 0.0;
        return _NoSplashPressable(
          onTap: widget.onTap,
          onPressedChanged: _setPressed,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.985 : 1,
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.selected && !soft)
                    Positioned(
                      top: 2 - pulse * 2,
                      child: Container(
                        width: 42 + pulse * 8,
                        height: 42 + pulse * 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              p.glowA.withValues(alpha: 0.13 - pulse * 0.03),
                              p.glowB.withValues(alpha: 0.055),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: app.motionDuration,
                            curve: Curves.easeOutCubic,
                            width: widget.selected ? 31 : 27,
                            height: widget.selected ? 31 : 27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: widget.selected && !soft
                                  ? RadialGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.055),
                                        p.glowA.withValues(alpha: 0.22),
                                        p.glowB.withValues(alpha: 0.08),
                                        Colors.transparent,
                                      ],
                                      stops: const [0, 0.42, 0.72, 1],
                                    )
                                  : null,
                              border: Border.all(
                                color: widget.selected && !soft
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.0),
                                width: TruLuraSurfaces.hairline,
                              ),
                              boxShadow: widget.selected && !soft
                                  ? [
                                      BoxShadow(
                                        color: p.glowB.withValues(
                                            alpha: 0.24 * app.glowScale),
                                        blurRadius: 20,
                                        spreadRadius: -7,
                                      ),
                                      BoxShadow(
                                        color: p.glowA.withValues(
                                            alpha: 0.14 * app.glowScale),
                                        blurRadius: 20,
                                        spreadRadius: -10,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                            child: Center(
                              child: TruLuraIcon(
                                glyph: widget.glyph,
                                size: 18,
                                active: widget.selected,
                                color: widget.selected && !soft
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : color,
                                assetPath: widget.assetPath,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: widget.selected && !soft
                                      ? cs.onSurface.withValues(alpha: 0.90)
                                      : color,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                  height: 1.0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.selected)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: soft
                              ? null
                              : LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                      p.glowA.withValues(alpha: 0.75),
                                      p.glowB.withValues(alpha: 0.42)
                                    ]),
                          color: soft
                              ? cs.onSurface.withValues(alpha: 0.22)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DockAtmospherePainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final double intensity;

  const _DockAtmospherePainter({
    required this.accentA,
    required this.accentB,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final topShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.030),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.26),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, topShade);

    final bleed = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.85),
        radius: 0.92,
        colors: [
          accentA.withValues(alpha: 0.095 * intensity),
          accentB.withValues(alpha: 0.040 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bleed);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: 0.20 * intensity),
          Colors.white.withValues(alpha: 0.06),
          accentB.withValues(alpha: 0.12 * intensity),
          Colors.transparent,
        ],
      ).createShader(rect);
    final y = size.height * 0.70;
    final path = Path()
      ..moveTo(size.width * 0.10, y)
      ..cubicTo(size.width * 0.30, y - 7, size.width * 0.70, y + 7,
          size.width * 0.90, y - 1);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _DockAtmospherePainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.intensity != intensity;
  }
}

/// Gesture-based press handler that deliberately avoids any Material splash/ripple.
class _NoSplashPressable extends StatelessWidget {
  final VoidCallback onTap;
  final ValueChanged<bool> onPressedChanged;
  final Widget child;

  const _NoSplashPressable(
      {required this.onTap,
      required this.onPressedChanged,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) => onPressedChanged(false),
      onTapCancel: () => onPressedChanged(false),
      child: child,
    );
  }
}
