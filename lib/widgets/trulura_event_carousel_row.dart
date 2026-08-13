import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/theme/mood_colors.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class TruluraEventCarouselRow extends StatelessWidget {
  final String? moodTagOverride;
  const TruluraEventCarouselRow({super.key, this.moodTagOverride});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final app = context.watch<AppProvider>();
    if (app.isLowEnergyContext) {
      // Low energy: keep discovery calm. We hide this entire row.
      return const SizedBox.shrink();
    }

    final mood = moodTagOverride ?? (app.currentUser?.moodTags.isNotEmpty ?? false ? app.currentUser!.moodTags.first : '');
    final accent = MoodColors.glow(mood);
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final isNight = now.hour >= 20 || now.hour <= 2;

    final items = <_TruEventItem>[
      _TruEventItem(
        title: isNight ? 'Nebula Night' : 'Nebula Hours',
        subtitle: isNight ? 'Live rooms + late DJs' : 'Soft live lounges',
        glyph: TruLuraGlyph.video,
      ),
      _TruEventItem(title: isWeekend ? 'Festival Drop' : 'Creator Drop', subtitle: 'Themed creators', glyph: TruLuraGlyph.star),
      _TruEventItem(title: 'Replay Capsule', subtitle: 'Highlights + replays', glyph: TruLuraGlyph.tv),
      _TruEventItem(title: 'Community Quest', subtitle: 'Quality boosts • $mood', glyph: TruLuraGlyph.spark),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Text('Live layers', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(child: Text('Events, festivals, and replays — mode-aware.', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700))),
              _NoSplashMini(
                onTap: () => TruNavigation.pushWithReturnTo(
                  context,
                  AppRoutes.live,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Open', style: t.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    TruLuraIcon(glyph: TruLuraGlyph.chevronRight, size: 16, active: false, color: cs.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final e = items[index];
              return SizedBox(
                width: 220,
                child: TruLuraGlassCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  tint: accent.withValues(alpha: 0.04),
                  onTap: () => TruNavigation.pushWithReturnTo(
                    context,
                    '${AppRoutes.placeholder}?title=${Uri.encodeComponent(e.title)}&subtitle=${Uri.encodeComponent('Event layer: ${e.subtitle}')}',
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: TruLuraSurfaces.hairline),
                          boxShadow: TruLuraEffects.softGlow(accent, intensity: 0.22 * app.glowScale),
                        ),
                        child: TruLuraIcon(glyph: e.glyph, size: 22, active: true, color: cs.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(e.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.25)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TruEventItem {
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;

  const _TruEventItem({required this.title, required this.subtitle, required this.glyph});
}

class _NoSplashMini extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NoSplashMini({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: Padding(padding: const EdgeInsets.all(6), child: child));
  }
}
