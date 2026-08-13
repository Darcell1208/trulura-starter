import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';

/// A TruLura-styled segmented control pill meant for top bars.
///
/// - No Material splash/ripple (uses gesture press + subtle scale).
/// - Uses [TruLuraTokens] for color + gradient.
class TopModePill extends StatelessWidget {
  /// Optional palette mode.
  ///
  /// When provided (and [items] length is 2), the pill uses the TruLura
  /// palette-driven styling (moving gradient highlight + palette border/text).
  final TruLuraMode? mode;
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;
  final double height;

  const TopModePill({
    super.key,
    this.mode,
    required this.items,
    required this.index,
    required this.onChanged,
    this.padding = const EdgeInsets.all(6),
    this.height = 44,
  }) : assert(items.length >= 2, 'TopModePill expects at least 2 items');

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, items.length - 1);

    // Palette-driven 2-option pill (matches the user-provided snippet style).
    if (mode != null && items.length == 2) {
      return _PaletteTwoOptionTopModePill(
        mode: mode!,
        height: height,
        left: items[0],
        right: items[1],
        isRightSelected: safeIndex == 1,
        onLeft: () => onChanged(0),
        onRight: () => onChanged(1),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: TruLuraTokens.ink.withValues(alpha: 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == safeIndex;
            return Expanded(
              child: _TopModePillSegment(
                label: items[i],
                selected: selected,
                onTap: () => onChanged(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PaletteTwoOptionTopModePill extends StatelessWidget {
  final TruLuraMode mode;
  final String left;
  final String right;
  final bool isRightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final double height;

  const _PaletteTwoOptionTopModePill({
    required this.mode,
    required this.left,
    required this.right,
    required this.isRightSelected,
    required this.onLeft,
    required this.onRight,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    final t = Theme.of(context).textTheme;

    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.22),
          border: Border.all(color: p.border),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: isRightSelected ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [p.glowA, p.glowB]),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      spreadRadius: -8,
                      color: p.glowA.withValues(alpha: 0.45),
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    onTap: onLeft,
                    child: Center(
                      child: Text(
                        left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (t.labelLarge ?? const TextStyle()).copyWith(
                          color: isRightSelected ? p.muted : p.text,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    onTap: onRight,
                    child: Center(
                      child: Text(
                        right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (t.labelLarge ?? const TextStyle()).copyWith(
                          color: isRightSelected ? p.text : p.muted,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopModePillSegment extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopModePillSegment({required this.label, required this.selected, required this.onTap});

  @override
  State<_TopModePillSegment> createState() => _TopModePillSegmentState();
}

class _TopModePillSegmentState extends State<_TopModePillSegment> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final selected = widget.selected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        try {
          widget.onTap();
        } catch (e) {
          debugPrint('TopModePill segment tap failed: $e');
        }
      },
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.98 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected ? TruLuraTokens.auraGradient(opacity: 1) : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (t.labelLarge ?? const TextStyle()).copyWith(
              color: selected ? Colors.white : TruLuraTokens.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
