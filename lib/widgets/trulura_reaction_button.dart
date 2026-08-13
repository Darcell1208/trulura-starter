import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraReactionButton.
class TruluraReactionButton extends StatefulWidget {
  final TruLuraGlyph icon;
  final String? label;
  final bool active;
  final VoidCallback? onTap;

  const TruluraReactionButton({
    super.key,
    required this.icon,
    this.label,
    this.active = false,
    this.onTap,
  });

  @override
  State<TruluraReactionButton> createState() => _TruluraReactionButtonState();
}

class _TruluraReactionButtonState extends State<TruluraReactionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final presence = app.emotionalPresenceState;
    final fg =
        widget.active ? Colors.white : cs.onSurface.withValues(alpha: 0.84);
    final bg = widget.active
        ? TruLuraTokens.auraViolet.withValues(alpha: 0.28)
        : cs.surfaceContainerHighest.withValues(alpha: 0.16);
    final touch = presence.touchSoftness.clamp(0.55, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedScale(
          duration: Duration(milliseconds: (110 + touch * 80).round()),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.965 : 1,
          child: AnimatedContainer(
            duration: Duration(milliseconds: (170 + touch * 120).round()),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
                horizontal: widget.label == null ? 10 : 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: Colors.white
                      .withValues(alpha: widget.active ? 0.20 : 0.10),
                  width: TruLuraSurfaces.hairline),
              boxShadow: widget.active || _pressed
                  ? TruLuraTokens.softGlow(TruLuraTokens.auraViolet)
                      .map((s) => s.copyWith(
                            blurRadius: s.blurRadius + (_pressed ? 10 : 0),
                            color: s.color
                                .withValues(alpha: _pressed ? 0.20 : 0.14),
                          ))
                      .toList()
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TruLuraIcon(glyph: widget.icon, size: 18, color: fg),
                if (widget.label != null) ...[
                  const SizedBox(width: 8),
                  Text(widget.label!,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: fg, fontWeight: FontWeight.w800)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
