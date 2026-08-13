import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';

/// TruLura primary CTA button with a rich gradient fill (no ripples).
///
/// Use this instead of [ElevatedButton] for main actions to keep the UI vibrant.
class TruLuraPrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool expand;

  const TruLuraPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.borderRadius = 24,
    this.expand = true,
  });

  @override
  State<TruLuraPrimaryButton> createState() => _TruLuraPrimaryButtonState();
}

class _TruLuraPrimaryButtonState extends State<TruLuraPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final presence = app.emotionalPresenceState;
    final disabled = widget.onPressed == null;
    final touch = presence.touchSoftness.clamp(0.55, 1.0);

    final content = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: disabled ? 0.55 : 1,
      child: DefaultTextStyle.merge(
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w900),
        child: IconTheme.merge(
          data: IconThemeData(color: cs.onPrimary),
          child: widget.child,
        ),
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: AnimatedScale(
        duration: Duration(milliseconds: (120 + touch * 90).round()),
        curve: Curves.easeOutCubic,
        scale: _pressed && !disabled ? 0.985 : 1,
        child: AnimatedContainer(
          duration: Duration(milliseconds: (180 + touch * 120).round()),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: disabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surfaceContainerHighest.withValues(alpha: 0.9),
                      cs.surface.withValues(alpha: 0.6)
                    ],
                  )
                : TruLuraGradients.primaryButton,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
                color: Colors.white.withValues(
                    alpha: disabled ? 0.06 : TruLuraTokens.strokeOpacity),
                width: 1),
            boxShadow: disabled
                ? []
                : [
                    ...TruLuraEffects.multiAuraGlow(
                        TruLuraTokens.auraViolet, TruLuraTokens.auraCyan,
                        intensity: (0.76 + (1 - touch) * 0.24) * app.glowScale),
                    BoxShadow(
                      color: TruLuraTokens.auraPink
                          .withValues(alpha: _pressed ? 0.20 : 0.12),
                      blurRadius: _pressed ? 66 : 52,
                      offset: const Offset(0, 30),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
            onTapCancel:
                disabled ? null : () => setState(() => _pressed = false),
            onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child:
                Padding(padding: widget.padding, child: Center(child: content)),
          ),
        ),
      ),
    );

    if (!widget.expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
