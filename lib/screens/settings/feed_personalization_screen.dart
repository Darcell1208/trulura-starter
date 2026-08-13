import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/trulura_mode.dart';

class FeedPersonalizationScreen extends StatelessWidget {
  const FeedPersonalizationScreen({super.key});

  String _tabLabel(String key) {
    switch (key) {
      case 'for_you':
        return 'For You';
      case 'aura':
        return 'Aura';
      case 'spark':
        return 'Spark';
      case 'vent':
        return 'Vent';
      case 'trending':
        return 'Trending';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    Widget sliderCard(
        {required TruLuraGlyph glyph,
        required String title,
        required String subtitle,
        required double value,
        required ValueChanged<double> onChanged,
        String? left,
        String? right}) {
      return TruLuraGlassCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: TruLuraSurfaces.hairline),
                  ),
                  child: TruLuraIcon(
                      glyph: glyph,
                      size: 20,
                      active: true,
                      color: cs.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.72),
                                  height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.2,
                  overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: value,
                min: 0,
                max: 1,
                divisions: 100,
                onChanged: onChanged,
              ),
            ),
            if (left != null || right != null)
              Row(
                children: [
                  Text(left ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(right ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800)),
                ],
              ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        showClose: true,
        onBack: () =>
            TruNavigation.goBackOrReturn(context, fallback: AppRoutes.settings),
        onClose: () =>
            TruNavigation.closeModule(context, fallback: AppRoutes.settings),
        title: 'Feed Personalization',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            TruLuraGlassCard(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const TruLuraIcon(
                      glyph: TruLuraGlyph.moon, size: 20, active: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Low Energy feed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          'Reduces stimulation: fewer boosted slots, calmer motion, and hides event/live layers. (Separate from Soft Mode.)',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.72),
                                  height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  TruToggle(
                      value: app.lowEnergyFeedEnabled,
                      onChanged: (v) => app.setLowEnergyFeedEnabled(v)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            sliderCard(
              glyph: TruLuraGlyph.insights,
              title: 'Content intensity',
              subtitle:
                  'Tune how bright and high-energy your feed feels. Lower values soften virality and reduce stimulation.',
              value: app.feedContentIntensity,
              onChanged: (v) => app.setFeedContentIntensity(v),
              left: 'Calm',
              right: 'Intense',
            ),
            const SizedBox(height: 14),
            sliderCard(
              glyph: TruLuraGlyph.video,
              title: 'Creator frequency',
              subtitle:
                  'Control how often creator content appears (it will never override Vent protections).',
              value: app.feedCreatorWeight,
              onChanged: (v) => app.setFeedCreatorWeight(v),
              left: 'Rare',
              right: 'More',
            ),
            const SizedBox(height: 14),
            sliderCard(
              glyph: TruLuraGlyph.heartOutline,
              title: 'Romantic visibility',
              subtitle:
                  'How strongly Spark and Dating content can surface in "For You." Mode boundaries are still enforced.',
              value: app.feedRomanticVisibility,
              onChanged: (v) => app.setFeedRomanticVisibility(v),
              left: 'Low',
              right: 'High',
            ),
            const SizedBox(height: 14),
            sliderCard(
              glyph: TruLuraGlyph.shield,
              title: 'Emotional sensitivity',
              subtitle:
                  'Higher sensitivity reduces exposure to heavy emotional posts unless you explicitly enter Vent.',
              value: app.feedEmotionalSensitivity,
              onChanged: (v) => app.setFeedEmotionalSensitivity(v),
              left: 'Open',
              right: 'Protect',
            ),
            const SizedBox(height: 14),
            sliderCard(
              glyph: TruLuraGlyph.explore,
              title: 'Discovery balance',
              subtitle:
                  'Blend familiar comfort with new people and topics. Higher values explore more new creators without using toxic virality loops.',
              value: app.feedDiscoveryBalance,
              onChanged: (v) => app.setFeedDiscoveryBalance(v),
              left: 'Familiar',
              right: 'New',
            ),
            const SizedBox(height: 14),
            _MuteControlsCard(),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TruLuraIcon(
                          glyph: TruLuraGlyph.spark, size: 20, active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart feed switching',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              'Trulura can suggest switching tabs when your behavior shifts, like romantic reactions pointing toward Spark. It never breaks protected spaces.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.72),
                                      height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      TruToggle(
                          value: app.smartFeedSwitchingEnabled,
                          onChanged: (v) =>
                              app.setSmartFeedSwitchingEnabled(v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const TruLuraIcon(
                          glyph: TruLuraGlyph.aura, size: 20, active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mood-adaptive visuals',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              'Subtle background tone + motion patterns adapt to your vibe and the selected feed context.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.72),
                                      height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      TruToggle(
                          value: app.moodAdaptiveUiEnabled,
                          onChanged: (v) => app.setMoodAdaptiveUiEnabled(v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const TruLuraIcon(
                          glyph: TruLuraGlyph.info, size: 20, active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Transparency explainers',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              'Show "why am I seeing this?" and boosted or organic labels in feed cards.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.72),
                                      height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      TruToggle(
                          value: app.transparencyExplainersEnabled,
                          onChanged: (v) =>
                              app.setTransparencyExplainersEnabled(v)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TruLuraIcon(
                          glyph: TruLuraGlyph.video, size: 20, active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Live layers in feed',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                                'Event rows and "Live now" cards appear as horizontal layers. Protected spaces can suppress them.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.72),
                                        height: 1.3)),
                          ],
                        ),
                      ),
                      TruToggle(
                          value: app.showLivesInFeed,
                          onChanged: (v) => app.setShowLivesInFeed(v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: app.showLivesInFeed ? 1.0 : 0.45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                            width: TruLuraSurfaces.hairline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Frequency',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  width: TruLuraSurfaces.hairline),
                            ),
                            child: SizedBox(
                              width: 96,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: app.livesInFeedFrequency,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Rare', child: Text('Rare')),
                                    DropdownMenuItem(
                                        value: 'Normal', child: Text('Normal')),
                                    DropdownMenuItem(
                                        value: 'Often', child: Text('Often')),
                                  ],
                                  onChanged: app.showLivesInFeed
                                      ? (v) {
                                          if (v != null) {
                                            app.setLivesInFeedFrequency(v);
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TruLuraIcon(
                          glyph: TruLuraGlyph.insights, size: 20, active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Feed tab order',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                                'Drag to reorder. Each tab preserves its own memory and scroll state.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.72),
                                        height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: app.feedTabOrder.length,
                    onReorderItem: (oldIndex, newIndex) {
                      final next = [...app.feedTabOrder];
                      final item = next.removeAt(oldIndex);
                      next.insert(newIndex, item);
                      app.setFeedTabOrder(next);
                    },
                    itemBuilder: (context, i) {
                      final key = app.feedTabOrder[i];
                      return Container(
                        key: ValueKey<String>('tab_$key'),
                        margin: EdgeInsets.only(
                            bottom: i == app.feedTabOrder.length - 1 ? 0 : 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                              width: TruLuraSurfaces.hairline),
                        ),
                        child: Row(
                          children: [
                            TruLuraIcon(
                                glyph: TruLuraGlyph.more,
                                size: 18,
                                active: false,
                                color: cs.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(_tabLabel(key),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w900))),
                            Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const TruLuraIcon(
                      glyph: TruLuraGlyph.moon, size: 20, active: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soft Mode affects the feed',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                            'When Soft Mode is enabled, glow, particles, and motion are reduced across all feeds.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.72),
                                    height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TruToggle(
                      value: app.softModeEnabled,
                      onChanged: (v) => app.setSoftModeEnabled(v)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MuteControlsCard extends StatelessWidget {
  const _MuteControlsCard();

  static const _topicOptions = <String>[
    'wellness',
    'music',
    'art',
    'dating',
    'creator',
    'support',
    'events'
  ];
  static const _moodOptions = <String>['sad', 'anx', 'anger', 'grief', 'spicy'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    Widget chipRow(
        {required String title,
        required List<String> options,
        required List<String> selected,
        required ValueChanged<List<String>> onChange}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final v in options)
                FilterChip(
                  selected: selected.contains(v),
                  label: Text(v),
                  onSelected: (on) {
                    final next = [...selected];
                    if (on) {
                      if (!next.contains(v)) {
                        next.add(v);
                      }
                    } else {
                      next.remove(v);
                    }
                    onChange(next);
                  },
                  showCheckmark: false,
                ),
            ],
          ),
        ],
      );
    }

    return TruLuraGlassCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: TruLuraSurfaces.hairline),
                ),
                child: TruLuraIcon(
                    glyph: TruLuraGlyph.close,
                    size: 20,
                    active: true,
                    color: cs.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temporary mutes',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        'Control what you don\'t want to see right now. These mutes affect ranking + distribution but never break mode safety rules.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          chipRow(
              title: 'Mute topics',
              options: _topicOptions,
              selected: app.feedMutedTopics,
              onChange: (v) => app.setFeedMutedTopics(v)),
          const SizedBox(height: 14),
          chipRow(
              title: 'Mute moods',
              options: _moodOptions,
              selected: app.feedMutedMoods,
              onChange: (v) => app.setFeedMutedMoods(v)),
        ],
      ),
    );
  }
}
