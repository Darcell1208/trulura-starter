import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/trulura_mode.dart';

/// A TruLura-styled glass app bar that matches the cinematic mocks.
///
/// - No Material tinting
/// - Blurred glass pill with hairline stroke
/// - Optional back button + actions
class TruLuraGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TruLuraMode? mode;
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final bool showClose;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final List<Widget> actions;
  final double height;

  const TruLuraGlassAppBar({
    super.key,
    this.mode,
    this.title,
    this.titleWidget,
    this.showBack = false,
    this.showClose = false,
    this.onBack,
    this.onClose,
    this.actions = const <Widget>[],
    this.height = 64,
  }) : assert(title == null || titleWidget == null, 'Provide only one of title or titleWidget.');

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final effectiveShowBack = showBack || canPop;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: TruLuraGlassCard(
          mode: mode,
          radius: 22,
          blur: TruLuraTokens.glassBlur,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (effectiveShowBack)
                IconButton(
                  onPressed: onBack ?? () => TruNavigation.goBackOrReturn(context),
                  icon: TruLuraIcon(glyph: TruLuraGlyph.back, size: 22, color: cs.onSurface.withValues(alpha: 0.92)),
                  tooltip: 'Back',
                )
              else
                const SizedBox(width: 8),
              const SizedBox(width: 2),
              Expanded(
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.3, color: cs.onSurface),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: titleWidget ?? Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              if (showClose)
                IconButton(
                  onPressed: onClose ?? () => TruNavigation.closeModule(context),
                  icon: TruLuraIcon(glyph: TruLuraGlyph.close, size: 20, color: cs.onSurface.withValues(alpha: 0.92)),
                  tooltip: 'Close',
                ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
