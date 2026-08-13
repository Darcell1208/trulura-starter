import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

enum TruluraPillChipVariant { neutral, selected, glow }

/// Spec component: TruluraPillChip.
class TruluraPillChip extends StatelessWidget {
  final String label;
  final bool removable;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final TruluraPillChipVariant variant;
  final TruLuraGlyph? leadingIcon;

  const TruluraPillChip({
    super.key,
    required this.label,
    this.removable = false,
    this.onTap,
    this.onRemove,
    this.variant = TruluraPillChipVariant.neutral,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bool isSelected = variant == TruluraPillChipVariant.selected || variant == TruluraPillChipVariant.glow;
    final Color bg = isSelected
        ? TruLuraTokens.nebula.withValues(alpha: 0.30)
        : cs.surfaceContainerHighest.withValues(alpha: 0.18);
    final Color stroke = isSelected ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.10);

    final List<BoxShadow> glow = variant == TruluraPillChipVariant.glow
        ? TruLuraTokens.softGlow(TruLuraTokens.auraViolet).map((s) => s.copyWith(color: s.color.withValues(alpha: 0.16))).toList()
        : const <BoxShadow>[];

    final fg = isSelected ? cs.onSurface.withValues(alpha: 0.95) : cs.onSurface.withValues(alpha: 0.82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: removable ? 12 : 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: stroke, width: TruLuraSurfaces.hairline),
            boxShadow: glow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                TruLuraIcon(glyph: leadingIcon!, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
              ),
              if (removable) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onRemove,
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: TruLuraIcon(glyph: TruLuraGlyph.close, size: 16, color: fg.withValues(alpha: 0.92)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
