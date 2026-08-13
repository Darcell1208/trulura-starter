import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Pill-shaped tag/button with a subtle glow.
///
/// Use for mood tags, mode selector, and expressive category chips.
class TruLuraGlowPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final TruLuraGlyph? icon;
  final EdgeInsetsGeometry padding;
  final TruLuraModeTone tone;

  const TruLuraGlowPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.tone = TruLuraModeTone.aura,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final (a, b) = tone.resolve(cs);

    final bg = selected
        ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b])
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceContainerHighest.withValues(alpha: brightness == Brightness.dark ? 0.82 : 0.92),
              cs.surface.withValues(alpha: brightness == Brightness.dark ? 0.55 : 0.75),
            ],
          );

    final border = selected ? a.withValues(alpha: 0.36) : a.withValues(alpha: brightness == Brightness.dark ? 0.18 : 0.14);
    final fg = selected ? Colors.white : cs.onSurface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
          boxShadow: selected
              ? TruLuraEffects.multiAuraGlow(
                  a,
                  b,
                  intensity: brightness == Brightness.dark ? 1.55 : 1.05,
                )
              : [
                  BoxShadow(
                    color: a.withValues(alpha: brightness == Brightness.dark ? 0.10 : 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OrbDot(accentA: a, accentB: b, selected: selected),
            const SizedBox(width: 10),
            if (icon != null) ...[
              TruLuraIcon(glyph: icon!, size: 16, active: selected, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbDot extends StatelessWidget {
  final Color accentA;
  final Color accentB;
  final bool selected;

  const _OrbDot({required this.accentA, required this.accentB, required this.selected});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final size = selected ? 18.0 : 16.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accentA.withValues(alpha: selected ? 0.95 : 0.70),
            accentB.withValues(alpha: selected ? 0.55 : 0.35),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: TruLuraEffects.multiAuraGlow(
          accentA,
          accentB,
          intensity: selected
              ? (brightness == Brightness.dark ? 0.85 : 0.55)
              : (brightness == Brightness.dark ? 0.35 : 0.20),
        ),
      ),
    );
  }
}
