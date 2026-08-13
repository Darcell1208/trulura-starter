import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

/// A subtle, no-splash “breathing” aura glow wrapper.
///
/// Use this to give hero elements (orbs, CTAs, avatars) a living neon presence
/// without Material ripples. Prefer enabling it on a small number of widgets
/// per screen to avoid excessive GPU work.
class BreathingGlow extends StatefulWidget {
  final Widget child;

  /// Preferred API: the glow tint.
  ///
  /// Keep [color] for backward-compatibility with earlier call-sites.
  final Color? glowColor;

  /// Backward-compatible alias of [glowColor].
  final Color? color;

  /// Maximum blur radius reached during the breathing cycle.
  final double maxBlur;

  /// Minimum blur radius.
  final double minBlur;

  /// Maximum glow alpha.
  final double maxAlpha;

  /// Minimum glow alpha.
  final double minAlpha;

  /// Minimum spread radius.
  final double minSpread;

  /// Maximum spread radius.
  final double maxSpread;

  /// Breathing period.
  final Duration duration;

  /// If false, renders [child] without animation.
  final bool enabled;

  const BreathingGlow({
    super.key,
    required this.child,
    this.glowColor,
    this.color,
    this.maxBlur = 26,
    this.minBlur = 10,
    this.maxAlpha = 0.38,
    this.minAlpha = 0.18,
    this.minSpread = 1,
    this.maxSpread = 4,
    this.duration = const Duration(milliseconds: 1800),
    this.enabled = true,
  }) : assert(glowColor == null || color == null, 'Provide only one of glowColor or color.');

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BreathingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) _c.duration = widget.duration;

    if (!oldWidget.enabled && widget.enabled) {
      _c.repeat(reverse: true);
    } else if (oldWidget.enabled && !widget.enabled) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final effectiveColor = widget.glowColor ?? widget.color ?? TruLuraTokens.auraViolet;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          final blur = widget.minBlur + (widget.maxBlur - widget.minBlur) * t;
          final alpha = widget.minAlpha + (widget.maxAlpha - widget.minAlpha) * t;
          final spread = widget.minSpread + (widget.maxSpread - widget.minSpread) * t;

          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: alpha.clamp(0.0, 1.0)),
                  blurRadius: blur,
                  spreadRadius: spread,
                ),
              ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}
