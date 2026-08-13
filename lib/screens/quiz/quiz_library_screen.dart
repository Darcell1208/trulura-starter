import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/compatibility_service.dart';
import 'package:trulura/services/quiz_registry_service.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';

class QuizLibraryScreen extends StatefulWidget {
  const QuizLibraryScreen({super.key});

  @override
  State<QuizLibraryScreen> createState() => _QuizLibraryScreenState();
}

class _QuizLibraryScreenState extends State<QuizLibraryScreen> {
  final QuizRegistryService _registry = const QuizRegistryService();
  final CompatibilityService _compat = CompatibilityService();
  TruQuizCategory? _category;
  Future<Set<String>>? _completedQuizIdsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _category ??= _initialCategory();
    _completedQuizIdsFuture ??= _loadCompletedQuizIds();
  }

  TruQuizCategory _initialCategory() {
    final raw = GoRouterState.of(context).uri.queryParameters['category'];
    for (final category in TruQuizCategory.values) {
      if (category.name == raw) return category;
    }
    return TruQuizCategory.spark;
  }

  String _resolveReturnTo() {
    final route = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (route != null && route.trim().isNotEmpty) return route;
    return AppRoutes.homeTab('aura');
  }

  Future<Set<String>> _loadCompletedQuizIds() async {
    final userId = context.read<AppProvider>().currentUser?.id;
    if (userId == null) return <String>{};
    final results = await _compat.getQuizResults(userId: userId);
    return results.map((result) => result.quizId).toSet();
  }

  String _effectsLabel(Set<TruQuizEffect> effects) {
    if (effects.isEmpty) return 'No routed effects yet';
    final labels = <String>[
      if (effects.contains(TruQuizEffect.feedPersonalization)) 'Feed',
      if (effects.contains(TruQuizEffect.friendshipSuggestions)) 'Friends',
      if (effects.contains(TruQuizEffect.nicheCommunitySuggestions))
        'Communities',
      if (effects.contains(TruQuizEffect.sparkDatingCompatibility)) 'Spark',
      if (effects.contains(TruQuizEffect.attractionOverlays)) 'Attraction',
      if (effects.contains(TruQuizEffect.healingArchive)) 'Archive',
      if (effects.contains(TruQuizEffect.truJourney)) 'TruJourney',
      if (effects.contains(TruQuizEffect.identityReflection)) 'Identity',
      if (effects.contains(TruQuizEffect.emotionalPatterning)) 'Emotional',
      if (effects.contains(TruQuizEffect.relationshipReadiness)) 'Readiness',
      if (effects.contains(TruQuizEffect.profileCard)) 'Profile',
      if (effects.contains(TruQuizEffect.savedVault)) 'Vault',
    ];
    return labels.join(' • ');
  }

  Future<void> _openEntry(TruQuizRegistryEntry entry) async {
    final launcher = _registry.launcherPathFor(entry);
    if (launcher == null) return;
    final currentRoute = GoRouterState.of(context).uri.toString();
    final uri = Uri(
      path: launcher,
      queryParameters: {
        'quiz': entry.quizId,
        'returnTo': currentRoute,
      },
    );
    await context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _category ?? TruQuizCategory.spark;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entries = _registry.byCategory(selectedCategory);
    final categoryCounts = _registry.countsByCategory();
    final ledgerCounts = _registry.countsByLedgerState();
    final meta = selectedCategory.meta;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Library'),
        leading: IconButton(
          onPressed: () => TruNavigation.goBackOrReturn(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go(_resolveReturnTo()),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registry-driven quiz ledger',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meta.longDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.76),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TruQuizCategory.values.map((category) {
                      return TruLuraGlowPill(
                        label:
                            '${category.meta.label} (${categoryCounts[category] ?? 0})',
                        selected: category == selectedCategory,
                        onTap: () => setState(() => _category = category),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TruLuraGlowPill(
                        label: '${meta.plannedScale}+ planned',
                        selected: meta.isLargestBucket,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      TruLuraGlowPill(
                        label:
                            '${_registry.readyByCategory(selectedCategory).length} ready now',
                        selected: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      TruLuraGlowPill(
                        label:
                            'Confirmed ${ledgerCounts[TruQuizLedgerState.confirmed] ?? 0}',
                        selected: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      if (meta.isLargestBucket)
                        const TruLuraGlowPill(
                          label: 'largest bucket',
                          selected: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Set<String>>(
              future: _completedQuizIdsFuture,
              builder: (context, snapshot) {
                final completedIds = snapshot.data ?? <String>{};
                if (entries.isEmpty) {
                  return TruLuraGlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No registry entries are mapped to this category yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.76),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final entry in entries) ...[
                      _QuizRegistryCard(
                        entry: entry,
                        effectsLabel: _effectsLabel(entry.effects),
                        isUnlocked: entry.isUnlocked(
                          completedQuizIds: completedIds,
                          completedQuizCount: completedIds.length,
                        ),
                        onTap: (_registry.launcherPathFor(entry) == null ||
                                !entry.isUnlocked(
                                  completedQuizIds: completedIds,
                                  completedQuizCount: completedIds.length,
                                ))
                            ? null
                            : () => _openEntry(entry),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizRegistryCard extends StatelessWidget {
  final TruQuizRegistryEntry entry;
  final String effectsLabel;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _QuizRegistryCard({
    required this.entry,
    required this.effectsLabel,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surfaceLabel =
        entry.launcherSurfaces.map((surface) => surface.label).join(' • ');

    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.74),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: onTap,
                child: Text(
                  !isUnlocked
                      ? 'Locked'
                      : onTap == null
                          ? 'Planned'
                          : 'Open',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TruLuraGlowPill(
                label: entry.subcategory,
                selected: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
              TruLuraGlowPill(
                label: entry.ledgerState.label,
                selected: entry.ledgerState == TruQuizLedgerState.confirmed,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
              TruLuraGlowPill(
                label: entry.resultType.name,
                selected: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
              TruLuraGlowPill(
                label: entry.visibilityDefault.label,
                selected: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
              TruLuraGlowPill(
                label: entry.unlockTier.label,
                selected: entry.unlockTier == TruQuizUnlockTier.open,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
              if (entry.isCanon)
                const TruLuraGlowPill(
                  label: 'canon',
                  selected: true,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                ),
              if (entry.isCore)
                const TruLuraGlowPill(
                  label: 'core',
                  selected: true,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                ),
              TruLuraGlowPill(
                label: entry.isReady
                    ? (isUnlocked ? 'ready' : 'locked')
                    : 'planned',
                selected: entry.isReady && isUnlocked,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Effects: $effectsLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Launch surfaces: $surfaceLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.68),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.startsUnlocked
                ? 'Unlock: available immediately'
                : entry.unlockAfterQuizIds.isNotEmpty
                    ? 'Unlock: after ${entry.unlockAfterQuizIds.length} prior quiz${entry.unlockAfterQuizIds.length == 1 ? '' : 'zes'}'
                    : 'Unlock: after ${entry.minimumCompletedQuizzes} completed quizzes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.68),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
