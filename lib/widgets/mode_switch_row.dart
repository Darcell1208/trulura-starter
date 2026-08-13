import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';

/// A compact, palette-driven segmented control for switching between TruLura modes.
///
/// - [mode] controls the *visual palette* (gradient + border tones)
/// - [selected] is the currently selected tab
/// - [onSelected] is called when a tab is tapped
class ModeSwitchRow extends StatelessWidget {
  final TruLuraMode mode;
  final TruLuraMode selected;
  final ValueChanged<TruLuraMode> onSelected;

  const ModeSwitchRow({super.key, required this.mode, required this.selected, required this.onSelected});

  static const List<_ModeTab> _items = [
    _ModeTab('For You', TruLuraMode.social),
    _ModeTab('Aura', TruLuraMode.aura),
    _ModeTab('Sync', TruLuraMode.sync),
    _ModeTab('Vent', TruLuraMode.vent),
    _ModeTab('Trending', TruLuraMode.trending),
  ];

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: TruLuraTokens.ink.withValues(alpha: 0.18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: _items
            .map((t) => Expanded(
                  child: _ModeSwitchTab(
                    label: t.label,
                    isSelected: t.mode == selected,
                    gradient: LinearGradient(colors: [kTruLuraPalettes[t.mode]!.glowA, kTruLuraPalettes[t.mode]!.glowB]),
                    glowColor: kTruLuraPalettes[t.mode]!.glowB,
                    // Match the spec: selected label renders as pure white.
                    selectedTextColor: Colors.white,
                    unselectedTextColor: p.text.withValues(alpha: 0.92),
                    textStyle: textTheme.labelMedium,
                    onTap: () => onSelected(t.mode),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ModeSwitchTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final LinearGradient gradient;
  final Color glowColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  const _ModeSwitchTab({
    required this.label,
    required this.isSelected,
    required this.gradient,
    required this.glowColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: -6,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (textStyle ?? const TextStyle()).copyWith(
              color: isSelected ? selectedTextColor : unselectedTextColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: -0.1,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTab {
  final String label;
  final TruLuraMode mode;
  const _ModeTab(this.label, this.mode);
}
