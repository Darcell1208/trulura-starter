import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/sync_candidate/sync_candidate.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/compatibility_service.dart';
import 'package:trulura/services/aura_shield_service.dart';
import 'package:trulura/services/user_service.dart';

/// Intentional matchmaking layer for TruLura (“Sync”).
///
/// Design goals:
/// - Opt-in activation (matchmaking is not default)
/// - Curated daily pacing (not endless swipe)
/// - Layered compatibility (not a single score)
/// - Emotional bandwidth protections (limit matches, pause, low-energy mode)
///
/// Storage:
/// - Local-first via SharedPreferences.
/// - Keys are namespaced per user id.
class SyncService {
  static const _stateKeyBase = 'sync_state_v1';
  static const _dailyKeyBase = 'sync_daily_suggestions_v1';
  static const _dailyMetaKeyBase = 'sync_daily_meta_v1';
  static const _activeMatchesKeyBase = 'sync_active_matches_v1';
  static const _signalsKeyBase = 'sync_signals_v1';
  static const _matchroomsKeyBase = 'sync_matchrooms_v1';
  final UserService _users = UserService();
  final CompatibilityService _compat = CompatibilityService();
  final AuraShieldService _auraShield = AuraShieldService();

  String _k(String base, String userId) => '${base}_$userId';

  String _dayStamp(DateTime now) => '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  int _hash(String seed) => seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);

  Future<List<TruInteractionSignalEvent>> getSignals({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(_signalsKeyBase, userId));
      final decoded = raw != null ? jsonDecode(raw) : null;
      if (decoded is! List) return const <TruInteractionSignalEvent>[];
      return decoded.whereType<Map>().map((e) => TruInteractionSignalEvent.fromJson(e.cast<String, dynamic>())).where((e) => e.fromUserId == userId && e.id.isNotEmpty).toList(growable: false);
    } catch (e) {
      debugPrint('SyncService.getSignals failed: $e');
      return const <TruInteractionSignalEvent>[];
    }
  }

  Future<void> _saveSignals({required String userId, required List<TruInteractionSignalEvent> signals}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k(_signalsKeyBase, userId), jsonEncode(signals.map((e) => e.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('SyncService._saveSignals failed: $e');
    }
  }

  Future<List<TruMatchroom>> getMatchrooms({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(_matchroomsKeyBase, userId));
      final decoded = raw != null ? jsonDecode(raw) : null;
      if (decoded is! List) return const <TruMatchroom>[];
      return decoded.whereType<Map>().map((e) => TruMatchroom.fromJson(e.cast<String, dynamic>())).where((e) => e.id.isNotEmpty).toList(growable: false);
    } catch (e) {
      debugPrint('SyncService.getMatchrooms failed: $e');
      return const <TruMatchroom>[];
    }
  }

  Future<void> _saveMatchrooms({required String userId, required List<TruMatchroom> rooms}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k(_matchroomsKeyBase, userId), jsonEncode(rooms.map((e) => e.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('SyncService._saveMatchrooms failed: $e');
    }
  }

  /// Interaction engine: sends Spark/Glow/Aura signals.
  ///
  /// For local-first MVP, mutuality is inferred probabilistically from
  /// compatibility + mode intent (so the flow demonstrates “interest → mutual → match”).
  Future<TruInteractionResult> sendSignal({
    required String userId,
    required String targetUserId,
    required TruInteractionSignal signal,
    TruPairCompatibilityReport? report,
  }) async {
    final now = DateTime.now();
    final currentSignals = await getSignals(userId: userId);

    // De-dupe: only one pending signal per target per type.
    final existingIdx = currentSignals.indexWhere((e) => e.toUserId == targetUserId && e.signal == signal);
    if (existingIdx != -1) {
      return TruInteractionResult(status: TruInteractionResultStatus.alreadySent, signalEvent: currentSignals[existingIdx], createdMatch: null);
    }

    final id = 'sig_${_hash('$userId|$targetUserId|${signal.name}|${now.toIso8601String()}')}';

    // Aura is contextual: it never directly creates a match.
    if (signal == TruInteractionSignal.aura) {
      final event = TruInteractionSignalEvent(id: id, fromUserId: userId, toUserId: targetUserId, signal: signal, mutual: false, createdMatch: false, createdAt: now, updatedAt: now);
      await _saveSignals(userId: userId, signals: [...currentSignals, event]);
      return TruInteractionResult(status: TruInteractionResultStatus.recorded, signalEvent: event, createdMatch: null);
    }

    // Infer mutuality (demo engine): higher compatibility → higher chance.
    final base = (report?.overall ?? 72).clamp(0, 100);
    final chance = (0.12 + (base / 100) * 0.58).clamp(0.08, 0.74);
    final rnd = math.Random(_hash('$id|mutual'));
    final isMutual = rnd.nextDouble() < chance;

    final event = TruInteractionSignalEvent(id: id, fromUserId: userId, toUserId: targetUserId, signal: signal, mutual: isMutual, createdMatch: isMutual, createdAt: now, updatedAt: now);
    await _saveSignals(userId: userId, signals: [...currentSignals, event]);

    if (!isMutual) {
      return TruInteractionResult(status: TruInteractionResultStatus.pending, signalEvent: event, createdMatch: null);
    }

    // Mutual → match: create (or reuse) a chat via the existing chat flow.
    // Note: the caller is responsible for creating the actual chat id.
    return TruInteractionResult(status: TruInteractionResultStatus.mutual, signalEvent: event, createdMatch: TruCreatedMatch(targetUserId: targetUserId, signal: signal));
  }

  /// Matchroom gating: unlocks a matchroom once message depth indicates real interaction.
  Future<TruMatchroom?> ensureMatchroomUnlocked({required String userId, required TruActiveMatch match, required int messageCount}) async {
    // Lightweight unlock: >= 6 messages between the pair.
    if (messageCount < 6) return null;

    final rooms = await getMatchrooms(userId: userId);
    final existing = rooms.where((r) => r.matchId == match.id).toList(growable: false);
    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();
    final roomId = 'mr_${_hash('${match.id}|${now.toIso8601String()}')}';
    final prompts = <String>[
      'Two truths and a soft wish: what do you both want this month?',
      'Pick a tiny shared ritual: morning check-in, weekly walk, or voice note?',
      'Name a boundary you appreciate (and why it matters).',
      'Plan a first micro-meet: time window + safe public place + exit plan.',
    ];
    final room = TruMatchroom(id: roomId, matchId: match.id, level: 1, prompts: prompts, voiceUnlocked: false, videoUnlocked: false, createdAt: now, updatedAt: now);
    await _saveMatchrooms(userId: userId, rooms: [...rooms, room]);
    return room;
  }

  Future<TruSyncState> getState({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(_stateKeyBase, userId));
      if (raw == null) return TruSyncState.defaults(userId);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return TruSyncState.defaults(userId);
      final parsed = TruSyncState.fromJson(decoded.cast<String, dynamic>());
      if (parsed.userId.isEmpty) return TruSyncState.defaults(userId);
      return parsed;
    } catch (e) {
      debugPrint('SyncService.getState failed: $e');
      return TruSyncState.defaults(userId);
    }
  }

  Future<void> upsertState(TruSyncState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k(_stateKeyBase, state.userId), jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('SyncService.upsertState failed: $e');
    }
  }

  Future<TruSyncState> setEnabled({required String userId, required bool enabled}) async {
    final current = await getState(userId: userId);
    final next = current.copyWith(enabled: enabled, updatedAt: DateTime.now());
    await upsertState(next);
    return next;
  }

  Future<TruSyncState> updatePreferences({required String userId, required TruSyncPreferences preferences}) async {
    final current = await getState(userId: userId);
    final next = current.copyWith(preferences: preferences, updatedAt: DateTime.now());
    await upsertState(next);
    return next;
  }

  Future<List<TruActiveMatch>> getActiveMatches({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(_activeMatchesKeyBase, userId));
      if (raw == null) return const <TruActiveMatch>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <TruActiveMatch>[];
      return decoded.whereType<Map>().map((e) => TruActiveMatch.fromJson(e.cast<String, dynamic>())).where((m) => m.viewerUserId == userId && m.id.isNotEmpty).toList(growable: false);
    } catch (e) {
      debugPrint('SyncService.getActiveMatches failed: $e');
      return const <TruActiveMatch>[];
    }
  }

  Future<void> _saveActiveMatches({required String userId, required List<TruActiveMatch> matches}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k(_activeMatchesKeyBase, userId), jsonEncode(matches.map((e) => e.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('SyncService._saveActiveMatches failed: $e');
    }
  }

  Future<TruActiveMatch?> addActiveMatch({required String userId, required String targetUserId, required String chatId}) async {
    final state = await getState(userId: userId);
    final current = await getActiveMatches(userId: userId);
    final stillActive = current.where((m) => m.status != TruActiveMatchStatus.closed).toList(growable: false);
    if (stillActive.length >= state.preferences.activeMatchLimit) return null;

    final now = DateTime.now();
    final id = 'am_${_hash('$userId|$targetUserId|${now.toIso8601String()}')}';
    final match = TruActiveMatch(id: id, viewerUserId: userId, targetUserId: targetUserId, chatId: chatId, status: TruActiveMatchStatus.active, createdAt: now, updatedAt: now);
    await _saveActiveMatches(userId: userId, matches: [...current, match]);
    return match;
  }

  Future<TruActiveMatch?> addActiveMatchFromSignal({
    required String userId,
    required String targetUserId,
    required String chatId,
    required TruInteractionSignal signal,
  }) async {
    final safety = await _auraShield.matchEligibility(viewerUserId: userId, targetUserId: targetUserId);
    if (safety.restricted) return null;

    final state = await getState(userId: userId);
    final current = await getActiveMatches(userId: userId);
    final stillActive = current.where((m) => m.status != TruActiveMatchStatus.closed).toList(growable: false);
    if (stillActive.length >= state.preferences.activeMatchLimit) return null;

    final now = DateTime.now();
    final id = 'am_${_hash('$userId|$targetUserId|${now.toIso8601String()}')}';
    final match = TruActiveMatch(
      id: id,
      viewerUserId: userId,
      targetUserId: targetUserId,
      chatId: chatId,
      status: TruActiveMatchStatus.active,
      signal: signal,
      stage: TruConnectionStage.matched,
      createdAt: now,
      updatedAt: now,
    );
    await _saveActiveMatches(userId: userId, matches: [...current, match]);
    return match;
  }

  Future<void> setMatchStatus({required String userId, required String matchId, required TruActiveMatchStatus status, String? pauseNote}) async {
    final current = await getActiveMatches(userId: userId);
    final idx = current.indexWhere((m) => m.id == matchId);
    if (idx == -1) return;
    final now = DateTime.now();
    final next = [...current];
    next[idx] = next[idx].copyWith(status: status, pauseNote: pauseNote, updatedAt: now);
    await _saveActiveMatches(userId: userId, matches: next);
  }

  Future<void> setMatchStage({required String userId, required String matchId, required TruConnectionStage stage, String? matchroomId}) async {
    final current = await getActiveMatches(userId: userId);
    final idx = current.indexWhere((m) => m.id == matchId);
    if (idx == -1) return;
    final now = DateTime.now();
    final next = [...current];
    next[idx] = next[idx].copyWith(stage: stage, matchroomId: matchroomId, updatedAt: now);
    await _saveActiveMatches(userId: userId, matches: next);
  }

  Future<TruActiveMatch?> findMatchByChatId({required String userId, required String chatId}) async {
    final matches = await getActiveMatches(userId: userId);
    try {
      return matches.firstWhere((m) => m.chatId == chatId);
    } catch (_) {
      return null;
    }
  }

  /// Gets the viewer's suggestions for *today*.
  ///
  /// - If suggestions were already generated today, returns the stored list.
  /// - Otherwise generates a fresh daily batch and stores it.
  Future<List<TruSyncSuggestion>> getDailySuggestions({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dayStamp(DateTime.now());

      final metaRaw = prefs.getString(_k(_dailyMetaKeyBase, userId));
      if (metaRaw != null) {
        final meta = jsonDecode(metaRaw);
        if (meta is Map && meta['day'] == today) {
          final raw = prefs.getString(_k(_dailyKeyBase, userId));
          final decoded = raw != null ? jsonDecode(raw) : null;
          if (decoded is List) {
            return decoded.whereType<Map>().map((e) => TruSyncSuggestion.fromJson(e.cast<String, dynamic>())).toList(growable: false);
          }
        }
      }

      final next = await _generateDailySuggestions(userId: userId, dayStamp: today);
      await prefs.setString(_k(_dailyKeyBase, userId), jsonEncode(next.map((e) => e.toJson()).toList(growable: false)));
      await prefs.setString(_k(_dailyMetaKeyBase, userId), jsonEncode({'day': today, 'generatedAt': DateTime.now().toIso8601String()}));
      return next;
    } catch (e) {
      debugPrint('SyncService.getDailySuggestions failed: $e');
      return const <TruSyncSuggestion>[];
    }
  }

  Future<void> passSuggestion({required String userId, required String suggestionId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(_dailyKeyBase, userId));
      final decoded = raw != null ? jsonDecode(raw) : null;
      if (decoded is! List) return;
      final list = decoded.whereType<Map>().map((e) => TruSyncSuggestion.fromJson(e.cast<String, dynamic>())).toList();
      list.removeWhere((s) => s.id == suggestionId);
      await prefs.setString(_k(_dailyKeyBase, userId), jsonEncode(list.map((e) => e.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('SyncService.passSuggestion failed: $e');
    }
  }

  Future<List<String>> buildGuidedPrompts({required User viewer, required User target, required TruPairCompatibilityReport report, required bool lowEnergyMode}) async {
    // Heuristic prompt bank.
    final top = [...report.layers]..sort((a, b) => b.score.compareTo(a.score));
    final best = top.take(2).toList(growable: false);
    final base = <String>[
      'What kind of day would feel genuinely good for you this week?',
      'What’s something you’re excited about lately — even if it’s small?',
    ];
    final layerDriven = <String>[
      if (best.any((e) => e.key == 'emotional')) 'When you’re overwhelmed, what kind of support actually helps?',
      if (best.any((e) => e.key == 'intellectual')) 'What’s a question you’ve been thinking about recently?',
      if (best.any((e) => e.key == 'communication')) 'Do you prefer quick back-and-forth or slower, thoughtful messages?',
      if (best.any((e) => e.key == 'lifestyle')) 'What’s a non-negotiable in your day-to-day rhythm?',
      if (best.any((e) => e.key == 'attraction')) 'What does “chemistry” feel like to you when it’s healthy?',
    ];

    final gentle = <String>[
      'Low energy check-in: do you want something light, or something deeper?',
      'No pressure — what’s one comfort thing you’ve been into lately?',
    ];

    final out = <String>[...base, ...layerDriven];
    if (lowEnergyMode) out.insertAll(0, gentle);
    return out.take(6).toList(growable: false);
  }

  List<String> suggestSafeMeetIdeas({required TruMatchPurpose purpose}) {
    // “Date planning integration” as safe-first recommendations.
    // (Venue sponsorships can slot into this later.)
    final shared = <String>[
      'Coffee shop with daylight seating',
      'Bookstore + short walk',
      'Museum / gallery hour',
      'Farmers market meetup',
      'Public park loop (midday)',
    ];
    if (purpose == TruMatchPurpose.companionship) {
      return [...shared, 'Community class (yoga / pottery)', 'Volunteering shift together'].take(7).toList(growable: false);
    }
    if (purpose == TruMatchPurpose.serious) {
      return [...shared, 'Dinner reservation in a well-lit area', 'Live event with seated tickets'].take(7).toList(growable: false);
    }
    return [...shared, 'Mocktail bar early evening', 'Food hall (multiple options)'].take(7).toList(growable: false);
  }

  Future<List<TruSyncSuggestion>> _generateDailySuggestions({required String userId, required String dayStamp}) async {
    final me = await _users.getCurrentUser();
    if (me == null) return const <TruSyncSuggestion>[];
    final personalization = await _compat.getQuizPersonalization(userId: userId);

    final state = await getState(userId: userId);
    if (!state.enabled) return const <TruSyncSuggestion>[];
    if (state.preferences.paused) return const <TruSyncSuggestion>[];

    final active = await getActiveMatches(userId: userId);
    final activeTargets = active.where((m) => m.status != TruActiveMatchStatus.closed).map((e) => e.targetUserId).toSet();

    final all = await _users.getAllUsers();
    final others = all.where((u) => u.id != userId && !activeTargets.contains(u.id)).toList();
    if (others.isEmpty) return const <TruSyncSuggestion>[];

    final prefs = state.preferences;
    bool isVerified(User u) => (u.profileImage ?? '').trim().isNotEmpty;

    // Apply coarse filters (age is approximate in the current model — still useful for UX).
    final filtered = others.where((u) {
      if (prefs.verifiedOnly && !isVerified(u)) return false;
      final age = u.age;
      if (age < prefs.minAge || age > prefs.maxAge) return false;
      // Intent fit: for MVP we treat “purpose” as needing any matching intent label.
      final wanted = prefs.purpose.label.toLowerCase();
      final has = u.intents.map((e) => e.toLowerCase()).contains(wanted);
      if (!has && wanted != 'dating') {
        // Dating is the default “fallback” bucket.
        return u.intents.isEmpty || u.intents.any((e) => e.toLowerCase() == 'dating');
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return const <TruSyncSuggestion>[];

    // Deterministic shuffle per day (so refresh feels stable).
    final seed = _hash('$userId|$dayStamp|${prefs.purpose.name}|${prefs.verifiedOnly}|${prefs.minAge}-${prefs.maxAge}|${prefs.maxDistanceMiles}');
    final rnd = math.Random(seed);
    filtered.shuffle(rnd);

    // Intentional pacing: small daily batch.
    final batchSize = prefs.lowEnergyMode ? 2 : 3;
    final picked = filtered.take(batchSize).toList(growable: false);

    final now = DateTime.now();
    return picked.map((u) {
      final report = _applyPersonalizationToReport(
        report: _compat.buildPairReport(
          viewer: me,
          target: u,
          purpose: prefs.purpose,
        ),
        target: u,
        personalization: personalization,
      );
      final reasons = report.layers
          .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
      final shortReasons = <String>{
        if (personalization.hasResults)
          ..._personalizationReasonsForTarget(
            target: u,
            personalization: personalization,
          ),
        ...reasons.take(3).map((e) => e.title),
      }.take(3).toList(growable: false);
      final id = 'ss_${_hash('$userId|${u.id}|$dayStamp')}';
      return TruSyncSuggestion(id: id, viewerUserId: userId, targetUserId: u.id, report: report, reasons: shortReasons, createdAt: now, updatedAt: now);
    }).toList(growable: false);
  }

  TruPairCompatibilityReport _applyPersonalizationToReport({
    required TruPairCompatibilityReport report,
    required User target,
    required TruQuizPersonalization personalization,
  }) {
    if (!personalization.hasResults) return report;
    final boost = _personalizationBoostForTarget(
      target: target,
      personalization: personalization,
    );
    if (boost == 0) return report;

    final adjustedLayers = report.layers
        .map(
          (layer) => TruCompatibilityLayer(
            key: layer.key,
            title: layer.title,
            score: (layer.score + boost).clamp(0, 100),
            note: layer.note,
          ),
        )
        .toList(growable: false);
    return TruPairCompatibilityReport(
      viewerUserId: report.viewerUserId,
      targetUserId: report.targetUserId,
      purpose: report.purpose,
      overall: (report.overall + boost).clamp(0, 100),
      layers: adjustedLayers,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
    );
  }

  int _personalizationBoostForTarget({
    required User target,
    required TruQuizPersonalization personalization,
  }) {
    final targetText = <String>[
      ...target.interests,
      ...target.intents,
      ...(target.bio == null ? const <String>[] : <String>[target.bio!]),
      ...target.moodTags,
    ].join(' ').toLowerCase();
    var boost = 0;
    for (final theme in personalization.contentThemes) {
      if (targetText.contains(theme.toLowerCase())) {
        boost += 3;
      }
    }
    for (final emphasis in personalization.discoveryEmphasis) {
      if (targetText.contains(emphasis.toLowerCase())) {
        boost += 2;
      }
    }
    return boost.clamp(0, 8);
  }

  List<String> _personalizationReasonsForTarget({
    required User target,
    required TruQuizPersonalization personalization,
  }) {
    final lowerInterests =
        target.interests.map((interest) => interest.toLowerCase()).toSet();
    final reasons = <String>[];
    if (personalization.discoveryEmphasis.any(
      (item) => item.toLowerCase().contains('friends'),
    )) {
      reasons.add('Trusted friend energy');
    }
    if (personalization.discoveryEmphasis.any(
      (item) => item.toLowerCase().contains('communities'),
    )) {
      reasons.add('Community-fit');
    }
    if (personalization.discoveryEmphasis.any(
      (item) => item.toLowerCase().contains('sparks'),
    )) {
      reasons.add('Easy social spark');
    }
    if (personalization.contentThemes.any(
          (item) => item.toLowerCase().contains('deep'),
        ) ||
        lowerInterests.contains('emotional depth')) {
      reasons.add('Depth-friendly');
    }
    return reasons.take(2).toList(growable: false);
  }
}

enum TruInteractionResultStatus { recorded, pending, mutual, alreadySent }

@immutable
class TruCreatedMatch {
  final String targetUserId;
  final TruInteractionSignal signal;

  const TruCreatedMatch({required this.targetUserId, required this.signal});
}

@immutable
class TruInteractionResult {
  final TruInteractionResultStatus status;
  final TruInteractionSignalEvent signalEvent;
  final TruCreatedMatch? createdMatch;

  const TruInteractionResult({required this.status, required this.signalEvent, required this.createdMatch});
}
