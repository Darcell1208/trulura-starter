import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';

/// Spec component: TruluraSegmentedPill.
///
/// A modern segmented control with a soft neon active capsule.
class TruluraSegmentedPill extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;
  final LinearGradient? activeGradient;
  final List<BoxShadow>? activeShadows;

  const TruluraSegmentedPill({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.compact = false,
    this.activeGradient,
    this.activeShadows,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = compact ? 38.0 : 44.0;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: TruLuraSurfaces.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * selectedIndex,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: activeGradient ?? TruLuraTokens.auraGradient(opacity: 0.95),
                    boxShadow: activeShadows ?? TruLuraTokens.softGlow(TruLuraTokens.auraViolet).map((s) => s.copyWith(blurRadius: s.blurRadius * 0.8, color: s.color.withValues(alpha: 0.16))).toList(),
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < options.length; i++)
                    Expanded(
                      child: _SegmentItem(
                        label: options[i],
                        selected: i == selectedIndex,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.70),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.2,
                ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
