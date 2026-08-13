import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/models/profile/compatibility_report.dart';
import 'package:trulura/models/profile/quiz_result.dart';
import 'package:trulura/models/sync_candidate/sync_candidate.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/quiz_registry_service.dart';

@immutable
class TruQuizPersonalization {
  final bool hasResults;
  final String emotionalTone;
  final String connectionStyle;
  final List<String> contentThemes;
  final List<String> discoveryEmphasis;

  const TruQuizPersonalization({
    required this.hasResults,
    required this.emotionalTone,
    required this.connectionStyle,
    required this.contentThemes,
    required this.discoveryEmphasis,
  });

  const TruQuizPersonalization.empty()
      : hasResults = false,
        emotionalTone = 'open',
        connectionStyle = 'balanced',
        contentThemes = const <String>[],
        discoveryEmphasis = const <String>[];
}

/// Local-first “identity + compatibility” engine.
///
/// This is intentionally deterministic (seeded) so the UI feels real in MVP,
/// while remaining backend-portable later.
class CompatibilityService {
  CompatibilityService({QuizRegistryService? registry})
      : _registry = registry ?? const QuizRegistryService();

  static const _quizKeyBase = 'compat_quiz_results_v1';
  static const _remoteQuizColumn = 'deeper_quiz_results';
  static const String _devQuizOverrideState = String.fromEnvironment(
    'TRULURA_DEV_QUIZ_STATE',
    defaultValue: 'real',
  );

  String _quizKey(String userId) => '${_quizKeyBase}_$userId';
  final QuizRegistryService _registry;

  int _hash(String seed) =>
      seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);

  bool get _supabaseReady => DatabaseService.instance.isInitialized;

  bool get _useDevQuizOverride =>
      kDebugMode && _normalizedDevQuizState != 'real';

  String get _normalizedDevQuizState =>
      _devQuizOverrideState.trim().toLowerCase();

  List<TruQuizResult>? _developmentQuizResultsFor(String userId) {
    if (!_useDevQuizOverride) return null;

    switch (_normalizedDevQuizState) {
      case 'none':
      case 'no_results':
        return const <TruQuizResult>[];
      case 'sample_a':
        return _sampleQuizResults(userId, sample: 'sample_a');
      case 'sample_b':
        return _sampleQuizResults(userId, sample: 'sample_b');
      case 'real':
      default:
        return null;
    }
  }

  List<TruQuizResult> _sampleQuizResults(String userId,
      {required String sample}) {
    final now = DateTime.now();
    final traits = switch (sample) {
      'sample_b' => <String, int>{
          'secure': 58,
          'playful': 84,
          'depth': 49,
          'independence': 76,
        },
      _ => <String, int>{
          'secure': 86,
          'playful': 52,
          'depth': 82,
          'independence': 44,
        },
    };
    final discoverySignals = switch (sample) {
      'sample_b' => const <String, int>{
          'communities': 52,
          'aligned_people': 58,
          'social_sparks': 84,
        },
      _ => const <String, int>{
          'communities': 82,
          'aligned_people': 74,
          'social_sparks': 48,
        },
    };

    return <TruQuizResult>[
      TruQuizResult(
        userId: userId,
        quizId: sample == 'sample_b'
            ? 'dev_social_energy_v1'
            : 'dev_depth_alignment_v1',
        quizType: TruQuizType.compatibilityTraits,
        completionLevel: TruQuizCompletionLevel.deeper,
        category: TruQuizCategory.advanced,
        ledgerState: TruQuizLedgerState.recovery,
        resultType: TruQuizResultType.compatibility,
        traitScores: traits,
        discoverySignals: discoverySignals,
        visibility: TruQuizVisibility.privateOnly,
        routedEffects: const <TruQuizEffect>[
          TruQuizEffect.feedPersonalization,
          TruQuizEffect.savedVault,
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<TruQuizResult> _decodeQuizResults(dynamic raw) {
    if (raw is! List) return const <TruQuizResult>[];
    return raw
        .whereType<Map>()
        .map((e) => TruQuizResult.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<TruQuizResult>> _getPersistedQuizResults({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localRaw = prefs.getString(_quizKey(userId));
    final localResults = localRaw == null
        ? const <TruQuizResult>[]
        : _decodeQuizResults(jsonDecode(localRaw));

    if (_supabaseReady) {
      try {
        final row = await DatabaseService.instance.client
            .from('user_settings')
            .select(_remoteQuizColumn)
            .eq('user_id', userId)
            .maybeSingle();
        final remoteResults = _decodeQuizResults(row?[_remoteQuizColumn]);
        if (remoteResults.isNotEmpty) return remoteResults;
        if (localResults.isNotEmpty) {
          await _persistRemoteQuizResults(
            userId: userId,
            results: localResults,
          );
          return localResults;
        }
        if (row?[_remoteQuizColumn] is List) {
          return const <TruQuizResult>[];
        }
      } catch (e) {
        debugPrint(
          'CompatibilityService._getPersistedQuizResults remote read failed: $e',
        );
      }
    }

    return localResults;
  }

  Future<void> _persistRemoteQuizResults({
    required String userId,
    required List<TruQuizResult> results,
  }) async {
    if (!_supabaseReady) return;
    final client = DatabaseService.instance.client;
    final payload = results.map((e) => e.toJson()).toList(growable: false);
    final nowIso = DateTime.now().toIso8601String();
    final updated = await client
        .from('user_settings')
        .update({
          _remoteQuizColumn: payload,
          'updated_at': nowIso,
        })
        .eq('user_id', userId)
        .select('user_id');
    if ((updated as List).isNotEmpty) return;
    await client.from('user_settings').insert({
      'user_id': userId,
      'created_at': nowIso,
      'updated_at': nowIso,
      _remoteQuizColumn: payload,
    });
  }

  /// Generates a mode-specific compatibility report for the current user.
  ///
  /// In real production this would compare viewer ↔ target.
  TruCompatibilityReport buildSelfReport(
      {required User viewer, required TruIdentityMode context}) {
    final now = DateTime.now();
    final seed =
        '${viewer.id}|${viewer.vibeLabel.name}|${viewer.moodTags.join(',')}|${viewer.intents.join(',')}|${context.name}';
    final h = _hash(seed);
    int pick(int min, int max, int salt) =>
        (min + ((h + salt) % (max - min + 1))).clamp(min, max);

    final attraction = TruAttractionMap(
      emotional: pick(55, 94, 11),
      intellectual: pick(52, 92, 29),
      visual: pick(48, 90, 47),
      cultural: pick(50, 93, 71),
      lifestyle: pick(50, 91, 97),
    );

    final dims = <TruCompatibilityDimension>[
      TruCompatibilityDimension(
        key: 'emotional',
        title: context == TruIdentityMode.vent
            ? 'Emotional Safety'
            : 'Emotional Resonance',
        score: pick(55, 95, 3),
        insight: context == TruIdentityMode.vent
            ? 'Your system prioritizes calm exposures and supportive language over novelty.'
            : 'Your strongest matches are people who mirror your pace and emotional clarity.',
      ),
      TruCompatibilityDimension(
        key: 'communication',
        title: 'Communication Style',
        score: pick(52, 93, 5),
        insight: context == TruIdentityMode.dating
            ? 'Your ideal connections respond with warmth + specificity — not games.'
            : 'You do best with direct, low-pressure interactions and clear signals.',
      ),
      TruCompatibilityDimension(
        key: 'lifestyle',
        title: context == TruIdentityMode.luxe
            ? 'Lifestyle Alignment'
            : 'Lifestyle Flow',
        score: attraction.lifestyle,
        insight: context == TruIdentityMode.luxe
            ? 'You prefer curated visibility and selective access. Quality over reach.'
            : 'You match best with people whose energy cadence fits your day-to-day.',
      ),
      TruCompatibilityDimension(
        key: 'attraction',
        title: context == TruIdentityMode.social
            ? 'Social Chemistry'
            : 'Attraction Signature',
        score: ((attraction.emotional +
                    attraction.visual +
                    attraction.intellectual) /
                3)
            .round(),
        insight: context == TruIdentityMode.social
            ? 'Friendship-fit is strongest when cultural vibe + humor overlap.'
            : 'Attraction is multi-layered here — emotional + aesthetic + intellect combine.',
      ),
    ];

    final overall =
        ((dims.map((e) => e.score).reduce((a, b) => a + b)) / dims.length)
            .round()
            .clamp(50, 98);

    return TruCompatibilityReport(
      viewerUserId: viewer.id,
      context: context,
      overall: overall,
      attraction: attraction,
      dimensions: dims,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generates a *pairwise* layered compatibility report (viewer ↔ target).
  ///
  /// This powers the Sync / matchmaking UX where we want *layers*, not a single
  /// score. It remains deterministic (seeded) for MVP realism.
  TruPairCompatibilityReport buildPairReport(
      {required User viewer,
      required User target,
      required TruMatchPurpose purpose}) {
    final now = DateTime.now();
    final seed =
        '${viewer.id}|${target.id}|${viewer.vibeLabel.name}|${target.vibeLabel.name}|${purpose.name}|${now.year}-${now.month}';
    final h = _hash(seed);
    int pick(int min, int max, int salt) =>
        (min + ((h + salt) % (max - min + 1))).clamp(min, max);

    // Layer weights change slightly based on purpose (intentional context).
    final emotional =
        pick(purpose == TruMatchPurpose.companionship ? 62 : 55, 95, 11);
    final intellectual = pick(52, 92, 29);
    final communication = pick(55, 94, 47);
    final attraction =
        pick(purpose == TruMatchPurpose.serious ? 50 : 48, 92, 71);
    final lifestyle = pick(52, 93, 97);

    final layers = <TruCompatibilityLayer>[
      TruCompatibilityLayer(
        key: 'emotional',
        title: 'Emotional Compatibility',
        score: emotional,
        note: purpose == TruMatchPurpose.companionship
            ? 'A calm, supportive frequency — good for consistency and care.'
            : 'Shared pace + emotional clarity: less guessing, more ease.',
      ),
      TruCompatibilityLayer(
        key: 'intellectual',
        title: 'Intellectual Fit',
        score: intellectual,
        note: 'Curiosity alignment — how well your minds “play” together.',
      ),
      TruCompatibilityLayer(
        key: 'communication',
        title: 'Communication Style',
        score: communication,
        note: purpose == TruMatchPurpose.serious
            ? 'Directness + repair skills matter more when you’re building long-term.'
            : 'Tone + cadence — whether you feel safe to be real early.',
      ),
      TruCompatibilityLayer(
        key: 'attraction',
        title: 'Attraction (Visual + Energetic)',
        score: attraction,
        note:
            'Chemistry is multi-factor: presence, aesthetics, and reciprocity.',
      ),
      TruCompatibilityLayer(
        key: 'lifestyle',
        title: 'Lifestyle Alignment',
        score: lifestyle,
        note:
            'Your day-to-day rhythm: social energy, routines, and priorities.',
      ),
    ];

    final overall =
        ((layers.map((e) => e.score).reduce((a, b) => a + b)) / layers.length)
            .round()
            .clamp(50, 98);
    return TruPairCompatibilityReport(
      viewerUserId: viewer.id,
      targetUserId: target.id,
      purpose: purpose,
      overall: overall,
      layers: layers,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<TruQuizResult>> getQuizResults({required String userId}) async {
    try {
      final persistedResults = await _getPersistedQuizResults(userId: userId);
      if (persistedResults.isNotEmpty) {
        debugPrint(
          'CompatibilityService.getQuizResults source=real_persisted count=${persistedResults.length}',
        );
        return persistedResults;
      }

      final devResults = _developmentQuizResultsFor(userId);
      if (devResults != null) {
        final source = switch (_normalizedDevQuizState) {
          'none' || 'no_results' => 'dev_none',
          'sample_a' => 'dev_sample_a',
          'sample_b' => 'dev_sample_b',
          _ => 'dev_unknown',
        };
        debugPrint(
          'CompatibilityService.getQuizResults source=$source count=${devResults.length}',
        );
        return devResults;
      }

      debugPrint(
        'CompatibilityService.getQuizResults source=no_results count=0',
      );
      return const <TruQuizResult>[];
    } catch (e) {
      debugPrint('CompatibilityService.getQuizResults failed: $e');
      return const <TruQuizResult>[];
    }
  }

  Future<void> upsertQuizResult(TruQuizResult result) async {
    try {
      final existing = await _getPersistedQuizResults(userId: result.userId);
      final next = [...existing];
      final idx = next.indexWhere((e) => e.quizId == result.quizId);
      if (idx == -1) {
        next.add(result);
      } else {
        next[idx] = result;
      }
      final encoded =
          jsonEncode(next.map((e) => e.toJson()).toList(growable: false));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_quizKey(result.userId), encoded);
      await _persistRemoteQuizResults(userId: result.userId, results: next);
    } catch (e) {
      debugPrint('CompatibilityService.upsertQuizResult failed: $e');
    }
  }

  /// Creates a deterministic “quiz” result (MVP) to power the UI.
  Future<TruQuizPersonalization> getQuizPersonalization({
    required String userId,
  }) async {
    final results = await getQuizResults(userId: userId);
    return derivePersonalization(results);
  }

  TruQuizResult? latestDeeperQuizResult(List<TruQuizResult> results) {
    final deeperResults = results
        .where(
          (result) => result.completionLevel == TruQuizCompletionLevel.deeper,
        )
        .toList(growable: false);
    if (deeperResults.isEmpty) return null;
    deeperResults.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return deeperResults.last;
  }

  TruQuizResult? latestMicroQuizResult(List<TruQuizResult> results) {
    final microResults = results
        .where(
          (result) => result.completionLevel == TruQuizCompletionLevel.micro,
        )
        .toList(growable: false);
    if (microResults.isEmpty) return null;
    microResults.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return microResults.last;
  }

  TruQuizResult? latestPersonalizationQuizResult(List<TruQuizResult> results) {
    final routed = resultsForEffect(
      results,
      TruQuizEffect.feedPersonalization,
    );
    if (routed.isNotEmpty) {
      routed.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      return routed.last;
    }
    return latestDeeperQuizResult(results) ?? latestMicroQuizResult(results);
  }

  Map<String, int> mergedTraitScores(List<TruQuizResult> results) {
    final routed = resultsForEffect(results, TruQuizEffect.feedPersonalization);
    if (routed.isEmpty) return const <String, int>{};
    final merged = <String, int>{};
    for (final result in routed) {
      for (final entry in result.traitScores.entries) {
        merged.update(
          entry.key,
          (value) => ((value + entry.value) / 2).round(),
          ifAbsent: () => entry.value,
        );
      }
    }
    return merged;
  }

  List<TruQuizResult> resultsForCategory(
    List<TruQuizResult> results,
    TruQuizCategory category,
  ) {
    return results.where((result) {
      final entry = _registry.byId(result.quizId);
      return (entry?.category ?? result.category) == category;
    }).toList(growable: false);
  }

  List<TruQuizResult> resultsForLedgerState(
    List<TruQuizResult> results,
    TruQuizLedgerState state,
  ) {
    return results.where((result) {
      final entry = _registry.byId(result.quizId);
      return (entry?.ledgerState ?? result.ledgerState) == state;
    }).toList(growable: false);
  }

  List<TruQuizRegistryEntry> unlockedRegistryEntries(
    List<TruQuizResult> results,
  ) {
    final completedIds = results.map((result) => result.quizId).toSet();
    return _registry.unlockedEntries(completedQuizIds: completedIds);
  }

  List<TruQuizResult> resultsForEffect(
    List<TruQuizResult> results,
    TruQuizEffect effect,
  ) {
    return results.where((result) {
      if (result.routedEffects.contains(effect)) return true;
      final entry = _registry.byId(result.quizId);
      return entry?.effects.contains(effect) ?? false;
    }).toList(growable: false);
  }

  List<TruQuizResult> savedQuizVault(List<TruQuizResult> results) {
    final saved = results
        .where((result) => result.savedToVault)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return saved;
  }

  List<TruQuizResult> selectedProfileCardResults(List<TruQuizResult> results) {
    final visible = results
        .where(
          (result) =>
              result.visibility == TruQuizVisibility.profileOptIn &&
              result.selectedForProfileCard,
        )
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return visible;
  }

  List<TruQuizResult> matchingVisibleResults(List<TruQuizResult> results) {
    final matching = results
        .where(
          (result) =>
              result.visibility == TruQuizVisibility.matchingOnly ||
              result.includeInMatching,
        )
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matching;
  }

  TruQuizResult applyVisibilityChoice(
    TruQuizResult result, {
    required TruQuizVisibility visibility,
  }) {
    return result.copyWith(
      visibility: visibility,
      selectedForProfileCard: visibility == TruQuizVisibility.profileOptIn,
      includeInMatching: visibility == TruQuizVisibility.matchingOnly,
      savedToVault: true,
      updatedAt: DateTime.now(),
    );
  }

  TruQuizPersonalization derivePersonalization(List<TruQuizResult> results) {
    final routed = resultsForEffect(results, TruQuizEffect.feedPersonalization);
    if (routed.isEmpty) return const TruQuizPersonalization.empty();

    final mergedTraits = mergedTraitScores(routed);
    final mergedDiscovery = <String, int>{};
    for (final result in routed) {
      for (final entry in result.discoverySignals.entries) {
        mergedDiscovery.update(
          entry.key,
          (value) => ((value + entry.value) / 2).round(),
          ifAbsent: () => entry.value,
        );
      }
    }

    int scoreFor(String key) {
      return mergedTraits[key] ?? 50;
    }

    int discoveryScoreFor(String key) {
      return mergedDiscovery[key] ?? 50;
    }

    final secure = scoreFor('secure');
    final playful = scoreFor('playful');
    final depth = scoreFor('depth');
    final independence = scoreFor('independence');
    final communities = discoveryScoreFor('communities');
    final alignedPeople = discoveryScoreFor('aligned_people');
    final socialSparks = discoveryScoreFor('social_sparks');

    final emotionalTone = depth >= 70
        ? 'reflective'
        : playful >= 68
            ? 'playful'
            : secure >= 65
                ? 'grounded'
                : 'open';

    final connectionStyle = independence >= 70
        ? 'independent'
        : secure >= 72
            ? 'steady'
            : playful >= 70
                ? 'spark-first'
                : 'balanced';

    final contentThemes = <String>[
      if (depth >= 65) 'deep conversations',
      if (playful >= 65) 'light social energy',
      if (secure >= 65) 'supportive communities',
      if (independence >= 65) 'solo-friendly spaces',
      if (depth < 65 && playful < 65 && secure < 65 && independence < 65)
        'fresh discovery',
    ];
    final discoveryEmphasis = <String>[
      if (alignedPeople >= 65 || secure >= 65) 'trusted friends',
      if (communities >= 65 || depth >= 65) 'thoughtful communities',
      if (socialSparks >= 65 || playful >= 65) 'social sparks',
      if (independence >= 65) 'solo-paced discovery',
      if (alignedPeople < 65 &&
          communities < 65 &&
          socialSparks < 65 &&
          secure < 65 &&
          depth < 65 &&
          playful < 65)
        'new communities',
    ];

    return TruQuizPersonalization(
      hasResults: true,
      emotionalTone: emotionalTone,
      connectionStyle: connectionStyle,
      contentThemes: contentThemes.take(3).toList(growable: false),
      discoveryEmphasis: discoveryEmphasis.take(3).toList(growable: false),
    );
  }

  TruQuizResult generateQuiz({required String userId, required String quizId}) {
    final now = DateTime.now();
    final h = _hash('$userId|$quizId|${now.year}-${now.month}');
    int pick(int min, int max, int salt) =>
        (min + ((h + salt) % (max - min + 1))).clamp(min, max);
    final traits = <String, int>{
      'secure': pick(40, 96, 2),
      'playful': pick(35, 92, 9),
      'depth': pick(45, 97, 17),
      'independence': pick(30, 90, 31),
    };
    final discoverySignals = <String, int>{
      'communities': pick(42, 94, 41),
      'aligned_people': pick(42, 94, 53),
      'social_sparks': pick(42, 94, 67),
    };
    return TruQuizResult(
      userId: userId,
      quizId: quizId,
      quizType: TruQuizType.compatibilityTraits,
      completionLevel: TruQuizCompletionLevel.deeper,
      category: TruQuizCategory.advanced,
      ledgerState: TruQuizLedgerState.recovery,
      resultType: TruQuizResultType.compatibility,
      traitScores: traits,
      discoverySignals: discoverySignals,
      visibility: TruQuizVisibility.privateOnly,
      savedToVault: true,
      routedEffects: const <TruQuizEffect>[
        TruQuizEffect.feedPersonalization,
        TruQuizEffect.savedVault,
      ],
      createdAt: now,
      updatedAt: now,
    );
  }
}
