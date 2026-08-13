import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Spec component: TruluraConversationTile.
class TruluraConversationTile extends StatefulWidget {
  final String name;
  final String subtitle;
  final String status;
  final ImageProvider? avatar;
  final VoidCallback onTap;
  final bool pinned;

  const TruluraConversationTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.avatar,
    required this.onTap,
    this.pinned = false,
  });

  @override
  State<TruluraConversationTile> createState() => _TruluraConversationTileState();
}

class _TruluraConversationTileState extends State<TruluraConversationTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final isActive = widget.status.toLowerCase() == 'active';

    final Color pillBg = isActive ? cs.tertiaryContainer : cs.surfaceContainerHighest;
    final Color pillFg = isActive ? cs.onTertiaryContainer : cs.onSurface.withValues(alpha: 0.72);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: TruLuraGlassCard(
          radius: 22,
          tone: TruLuraModeTone.aura,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          gradientStroke: !soft,
          child: Row(
            children: [
              TruLuraHaloAvatar(radius: 26, image: widget.avatar, fallback: const TruLuraIcon(glyph: TruLuraGlyph.person, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.25)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (widget.pinned) ...[
                Icon(Icons.push_pin_rounded, size: 18, color: cs.secondary.withValues(alpha: 0.92)),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: pillBg.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: TruLuraSurfaces.hairline)),
                child: Text(widget.status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: pillFg, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
