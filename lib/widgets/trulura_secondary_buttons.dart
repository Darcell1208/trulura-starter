import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';

/// A compact glass-style secondary action button (no ripples).
///
/// Use this for supportive actions (filters, quick actions, etc.) that should
/// feel consistent with TruLura glass surfaces.
class SecondaryGlassButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SecondaryGlassButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.radius = TruLuraTokens.r16,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: TruLuraTokens.textSecondary,
          fontWeight: FontWeight.w800,
        );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: TruLuraTokens.ink.withValues(alpha: 0.28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: TruLuraTokens.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Text(text, style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A vivid “CONNECT” CTA pill used for social actions (no ripples).
class ConnectButton extends StatelessWidget {
  /// When provided, the button will use the palette gradient for this mode.
  ///
  /// If null, the button falls back to the original `TruLuraTokens` aura look
  /// for backward compatibility.
  final TruLuraMode? mode;

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color glowColor;
  final double height;

  const ConnectButton({
    super.key,
    this.mode,
    String? text,
    String? label,
    this.icon = Icons.favorite_rounded,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.radius = TruLuraTokens.r16,
    this.glowColor = TruLuraTokens.auraViolet,
    this.height = 46,
  })  : assert(text == null || label == null, 'Pass either text or label, not both.'),
        label = label ?? text ?? 'CONNECT';

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900);

    final palette = mode == null ? null : kTruLuraPalettes[mode!];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: palette == null
                ? TruLuraTokens.auraGradient(opacity: 1)
                : LinearGradient(
                    begin: const Alignment(-1, -1),
                    end: const Alignment(1, 1),
                    colors: [palette.glowA, palette.glowB],
                  ),
            boxShadow: disabled
                ? []
                : (palette == null
                    ? TruLuraTokens.softGlow(glowColor)
                    : [
                        BoxShadow(
                          blurRadius: 18,
                          spreadRadius: -6,
                          color: palette.glowB.withValues(alpha: 0.35),
                          offset: const Offset(0, 12),
                        ),
                      ]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: padding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(label, style: style),
                  ],
                ),
              ),
            )
          ),
        ),
      ),
    );
  }
}

/// Primary TruLura action button.
///
/// This is a semantic alias of [ConnectButton] so feature code can reference a
/// stable “action CTA” component name (per the interaction maps) while
/// preserving the existing, token-driven visual implementation.
class TruluraActionButton extends StatelessWidget {
  final TruLuraMode? mode;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color glowColor;
  final double height;

  const TruluraActionButton({
    super.key,
    this.mode,
    this.label = 'CONNECT',
    this.icon = Icons.favorite_rounded,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.radius = TruLuraTokens.r16,
    this.glowColor = TruLuraTokens.auraViolet,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) => ConnectButton(
        mode: mode,
        label: label,
        icon: icon,
        onTap: onTap,
        padding: padding,
        radius: radius,
        glowColor: glowColor,
        height: height,
      );
}
