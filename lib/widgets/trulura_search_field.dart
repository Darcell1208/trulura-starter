import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraSearchField.
///
/// Glassy search input with optional trailing action (filter).
class TruluraSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String placeholder;
  final VoidCallback? onFilterTap;
  final bool autofocus;

  const TruluraSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.placeholder = 'Search',
    this.onFilterTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TruLuraGlassCard(
      radius: 999,
      blur: TruLuraTokens.glassBlur,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          TruLuraIcon(glyph: TruLuraGlyph.search, size: 20, color: cs.onSurface.withValues(alpha: 0.82)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: placeholder,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: 8),
            _FilterIconButton(onTap: onFilterTap!),
          ],
        ],
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterIconButton({required this.onTap});

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
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: TruLuraSurfaces.hairline),
          ),
          child: TruLuraIcon(glyph: TruLuraGlyph.filter, size: 18, color: cs.onSurface.withValues(alpha: 0.88)),
        ),
      ),
    );
  }
}
