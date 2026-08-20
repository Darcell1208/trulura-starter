import 'package:flutter/material.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/trust_signal_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraExploreProfileCard.
///
/// Reusable Explore grid card.
class TruluraExploreProfileCard extends StatelessWidget {
  final User user;
  final bool followed;
  final bool connectSent;
  final VoidCallback onTapCard;
  final VoidCallback onFollow;
  final VoidCallback? onConnect;

  const TruluraExploreProfileCard({
    super.key,
    required this.user,
    required this.followed,
    required this.connectSent,
    required this.onTapCard,
    required this.onFollow,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = user.publicDisplayName;
    final username = user.publicUsername;
    final handle = username == null ? null : '@$username';
    final bio = (user.bio?.trim().isNotEmpty ?? false)
        ? user.bio!.trim()
        : '✨ Always up for an adventure…';
    final trust = const TrustSignalService().compute(user);
    final image = user.profileImage?.trim();
    final imageUri =
        image == null || image.isEmpty ? null : Uri.tryParse(image);
    final imageIsNetwork = imageUri != null &&
        imageUri.hasScheme &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https');

    Widget imageFallback() => Container(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
          child: const TruLuraIcon(glyph: TruLuraGlyph.person, size: 48),
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapCard,
      child: TruLuraGlassCard(
        tone: TruLuraModeTone.explore,
        radius: 22,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: (image?.isNotEmpty ?? false)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          imageIsNetwork
                              ? Image.network(
                                  image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => imageFallback(),
                                )
                              : Image.asset(
                                  image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => imageFallback(),
                                ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    cs.surface.withValues(alpha: 0.30)
                                  ]),
                            ),
                          ),
                        ],
                      )
                    : imageFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (handle != null)
                        Expanded(
                          child: Text(handle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.68),
                                      fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        )
                      else
                        const Spacer(),
                      if (trust.isVisible) ...[
                        const SizedBox(width: 8),
                        _TrustPill(label: trust.label!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(bio,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.76),
                          height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TruLuraCompactActionButton(
                          label: followed ? 'Following' : 'Follow',
                          glyph: followed
                              ? TruLuraGlyph.check
                              : TruLuraGlyph.postPlus,
                          emphasized: followed,
                          onTap: onFollow,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TruLuraCompactActionButton(
                          label: connectSent ? 'Sent' : 'Connect',
                          glyph: connectSent
                              ? TruLuraGlyph.check
                              : TruLuraGlyph.send,
                          emphasized: !connectSent,
                          enabled: onConnect != null,
                          onTap: onConnect,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small no-splash pill button designed for tight grid cards.
///
/// Avoids TextButton wrapping ("Conne\nct") by enforcing single-line labels.
class TruLuraCompactActionButton extends StatefulWidget {
  final String label;
  final TruLuraGlyph glyph;
  final VoidCallback? onTap;
  final bool enabled;
  final bool emphasized;

  const TruLuraCompactActionButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.onTap,
    this.enabled = true,
    this.emphasized = false,
  });

  @override
  State<TruLuraCompactActionButton> createState() =>
      _TruLuraCompactActionButtonState();
}

class _TruLuraCompactActionButtonState
    extends State<TruLuraCompactActionButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.enabled && widget.onTap != null;

    final bg = widget.emphasized
        ? LinearGradient(colors: [
            TruLuraBrandColors.neonPurple
                .withValues(alpha: enabled ? 0.68 : 0.26),
            TruLuraBrandColors.nebulaMagenta
                .withValues(alpha: enabled ? 0.55 : 0.22),
          ])
        : null;

    final surface =
        cs.surfaceContainerHighest.withValues(alpha: enabled ? 0.40 : 0.22);
    final border = Colors.white.withValues(alpha: enabled ? 0.12 : 0.07);
    final fg = widget.emphasized ? Colors.white : cs.onSurface;
    final mutedFg = cs.onSurface.withValues(alpha: 0.60);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? widget.onTap : null,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.98 : 1,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: bg,
            color: bg == null ? surface : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: TruLuraSurfaces.hairline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TruLuraIcon(
                  glyph: widget.glyph,
                  size: 16,
                  active: true,
                  color: enabled ? fg : mutedFg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: enabled ? fg : mutedFg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final String label;
  const _TrustPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: TruLuraSurfaces.hairline),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
}
