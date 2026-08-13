import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

enum TruluraStatusTone { neutral, success, warning, danger, protected }

/// Spec component: TruluraStatusBadge.
///
/// Small pill label for states like Active / Paused / Pending / Verified.
class TruluraStatusBadge extends StatelessWidget {
  final String label;
  final TruLuraGlyph? icon;
  final TruluraStatusTone tone;

  const TruluraStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = TruluraStatusTone.neutral,
  });

  (Color bg, Color stroke, Color fg, Color glow) _colors(ColorScheme cs) {
    switch (tone) {
      case TruluraStatusTone.success:
        return (TruLuraTokens.auraCyan.withValues(alpha: 0.14), TruLuraTokens.auraCyan.withValues(alpha: 0.35), cs.onSurface, TruLuraTokens.auraCyan);
      case TruluraStatusTone.warning:
        return (TruLuraTokens.auraPink.withValues(alpha: 0.12), TruLuraTokens.auraPink.withValues(alpha: 0.30), cs.onSurface, TruLuraTokens.auraPink);
      case TruluraStatusTone.danger:
        return (Colors.red.withValues(alpha: 0.10), Colors.red.withValues(alpha: 0.22), cs.onSurface, Colors.red);
      case TruluraStatusTone.protected:
        return (TruLuraTokens.nebula.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.16), cs.onSurface, TruLuraTokens.auraViolet);
      case TruluraStatusTone.neutral:
        return (cs.surfaceContainerHighest.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.14), cs.onSurface, TruLuraTokens.auraViolet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, stroke, fg, glow) = _colors(cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stroke, width: TruLuraSurfaces.hairline),
        boxShadow: TruLuraTokens.softGlow(glow).map((s) => s.copyWith(color: s.color.withValues(alpha: 0.10))).toList(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            TruLuraIcon(glyph: icon!, size: 14, color: fg.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
          ],
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.92), fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}
