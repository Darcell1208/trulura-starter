import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first interaction + control layer for Trulura discovery.
///
/// This is intentionally backend-agnostic:
/// - Stores per-user (when userId available) and also a global fallback.
/// - Tracks lightweight signals used by the feed distribution engine.
/// - Provides user controls like Hide/Report without requiring schema changes.
class FeedBehaviorService {
  FeedBehaviorService._();

  static final FeedBehaviorService instance = FeedBehaviorService._();

  static const _prefsBaseKey = 'feed_behavior_v1';
  static const _globalKey = '${_prefsBaseKey}_global';

  /// Bumps whenever local feed preferences/signals change.
  ///
  /// Screens can listen and recompute ranking without forcing a full refetch.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  String _keyForUser(String? userId) => userId == null || userId.trim().isEmpty ? _globalKey : '${_prefsBaseKey}_${userId.trim()}';

  Future<TruFeedBehaviorProfile> getProfile({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyForUser(userId));
      if (raw == null || raw.trim().isEmpty) return const TruFeedBehaviorProfile();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruFeedBehaviorProfile.fromJson(json);
    } catch (e) {
      debugPrint('FeedBehaviorService.getProfile failed: $e');
      return const TruFeedBehaviorProfile();
    }
  }

  Future<void> setProfile(TruFeedBehaviorProfile profile, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyForUser(userId), jsonEncode(profile.toJson()));
      revision.value = revision.value + 1;
    } catch (e) {
      debugPrint('FeedBehaviorService.setProfile failed: $e');
    }
  }

  Future<void> hidePost({required String postId, String? userId}) async {
    if (postId.trim().isEmpty) return;
    final p = await getProfile(userId: userId);
    if (p.hiddenPostIds.contains(postId)) return;
    final next = p.copyWith(hiddenPostIds: {...p.hiddenPostIds, postId});
    await setProfile(next, userId: userId);
  }

  Future<void> reportPost({required String postId, String? userId}) async {
    if (postId.trim().isEmpty) return;
    final p = await getProfile(userId: userId);
    if (p.reportedPostIds.contains(postId)) return;
    final next = p.copyWith(reportedPostIds: {...p.reportedPostIds, postId});
    await setProfile(next, userId: userId);
  }

  Future<void> logSignal({required TruFeedSignal signal, required String postId, required String authorId, String? moodTag, String? category, String? userId}) async {
    if (postId.trim().isEmpty) return;
    final p = await getProfile(userId: userId);

    final now = DateTime.now();
    final seen = [...p.recentSeenPostIds];
    if (!seen.contains(postId)) seen.insert(0, postId);
    if (seen.length > 220) seen.removeRange(220, seen.length);

    Map<String, double> bump(Map<String, double> src, String? key, double delta) {
      final k = (key ?? '').trim().toLowerCase();
      if (k.isEmpty) return src;
      final out = Map<String, double>.from(src);
      out[k] = (out[k] ?? 0) + delta;
      // Soft clamp to keep values stable.
      if ((out[k] ?? 0) > 20) out[k] = 20;
      if ((out[k] ?? 0) < -10) out[k] = -10;
      return out;
    }

    final weight = switch (signal) {
      TruFeedSignal.glow => 1.8,
      TruFeedSignal.react => 1.2,
      TruFeedSignal.commentOpen => 1.0,
      TruFeedSignal.share => 1.4,
      TruFeedSignal.connect => 1.6,
      TruFeedSignal.dismiss => -1.0,
      TruFeedSignal.report => -2.2,
    };

    final next = p.copyWith(
      lastSignalAt: now,
      recentSeenPostIds: seen,
      moodAffinity: bump(p.moodAffinity, moodTag, weight),
      topicAffinity: bump(p.topicAffinity, category, weight * 0.8),
      creatorAffinity: bump(p.creatorAffinity, authorId, weight * 0.9),
    );

    await setProfile(next, userId: userId);
  }
}

enum TruFeedSignal { glow, react, commentOpen, share, connect, dismiss, report }

@immutable
class TruFeedBehaviorProfile {
  final Set<String> hiddenPostIds;
  final Set<String> reportedPostIds;
  final List<String> recentSeenPostIds;
  final Map<String, double> moodAffinity;
  final Map<String, double> topicAffinity;
  final Map<String, double> creatorAffinity;
  final DateTime? lastSignalAt;

  const TruFeedBehaviorProfile({
    this.hiddenPostIds = const <String>{},
    this.reportedPostIds = const <String>{},
    this.recentSeenPostIds = const <String>[],
    this.moodAffinity = const <String, double>{},
    this.topicAffinity = const <String, double>{},
    this.creatorAffinity = const <String, double>{},
    this.lastSignalAt,
  });

  Map<String, dynamic> toJson() => {
        'hiddenPostIds': hiddenPostIds.toList(growable: false),
        'reportedPostIds': reportedPostIds.toList(growable: false),
        'recentSeenPostIds': recentSeenPostIds,
        'moodAffinity': moodAffinity,
        'topicAffinity': topicAffinity,
        'creatorAffinity': creatorAffinity,
        'lastSignalAt': lastSignalAt?.toIso8601String(),
      };

  factory TruFeedBehaviorProfile.fromJson(Map<String, dynamic> json) {
    Map<String, double> mapDouble(dynamic raw) {
      if (raw is! Map) return const <String, double>{};
      final out = <String, double>{};
      for (final e in raw.entries) {
        final k = e.key.toString();
        final v = (e.value is num) ? (e.value as num).toDouble() : double.tryParse(e.value.toString());
        if (k.trim().isEmpty || v == null) continue;
        out[k] = v;
      }
      return out;
    }

    List<String> listString(dynamic raw, {int max = 220}) {
      if (raw is! List) return const <String>[];
      final out = <String>[];
      for (final e in raw) {
        final s = e?.toString() ?? '';
        if (s.trim().isEmpty) continue;
        out.add(s);
        if (out.length >= max) break;
      }
      return out;
    }

    Set<String> setString(dynamic raw, {int max = 700}) => listString(raw, max: max).toSet();

    return TruFeedBehaviorProfile(
      hiddenPostIds: setString(json['hiddenPostIds']),
      reportedPostIds: setString(json['reportedPostIds']),
      recentSeenPostIds: listString(json['recentSeenPostIds']),
      moodAffinity: mapDouble(json['moodAffinity']),
      topicAffinity: mapDouble(json['topicAffinity']),
      creatorAffinity: mapDouble(json['creatorAffinity']),
      lastSignalAt: DateTime.tryParse((json['lastSignalAt'] ?? '').toString()),
    );
  }

  TruFeedBehaviorProfile copyWith({
    Set<String>? hiddenPostIds,
    Set<String>? reportedPostIds,
    List<String>? recentSeenPostIds,
    Map<String, double>? moodAffinity,
    Map<String, double>? topicAffinity,
    Map<String, double>? creatorAffinity,
    DateTime? lastSignalAt,
  }) =>
      TruFeedBehaviorProfile(
        hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
        reportedPostIds: reportedPostIds ?? this.reportedPostIds,
        recentSeenPostIds: recentSeenPostIds ?? this.recentSeenPostIds,
        moodAffinity: moodAffinity ?? this.moodAffinity,
        topicAffinity: topicAffinity ?? this.topicAffinity,
        creatorAffinity: creatorAffinity ?? this.creatorAffinity,
        lastSignalAt: lastSignalAt ?? this.lastSignalAt,
      );
}
