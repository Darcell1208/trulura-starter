import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraCompanionModeCard.
class TruluraCompanionModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final TruLuraModeTone tone;
  final VoidCallback onTap;

  const TruluraCompanionModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      tone: tone,
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [cs.primary.withValues(alpha: 0.95), cs.secondary.withValues(alpha: 0.65)], stops: const [0, 1]),
              boxShadow: TruLuraEffects.softGlow(cs.primary, intensity: 0.35),
            ),
            child: Center(child: TruLuraIcon(glyph: glyph, size: 18, active: true, color: cs.onPrimary.withValues(alpha: 0.95))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.25)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TruLuraIcon(glyph: TruLuraGlyph.chevronRight, size: 18, active: true, color: cs.onSurface.withValues(alpha: 0.75)),
        ],
      ),
    );
  }
}
