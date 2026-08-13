import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/emotional_governance_service.dart';
import 'package:trulura/services/feed_behavior_service.dart';

/// Multi-layer feed distribution + ranking.
///
/// Goals:
/// - Mode-aware (works with VisibilityService / ParticipationContext)
/// - Emotionally adaptive (intensity vs sensitivity)
/// - Personalization via local behavior signals
/// - Fair creator distribution (avoid repeating same author)
/// - Monetization-aware (boosted slots exist but never override safety)
class FeedDistributionEngine {
  const FeedDistributionEngine();
  static const EmotionalGovernanceService _governance =
      EmotionalGovernanceService();

  List<TruRankedPost> rank({
    required List<Post> candidates,
    required TruDiscoveryFeedKind kind,
    required TruParticipationContext ctx,
    required User? viewer,
    required AppProvider settings,
    required TruFeedBehaviorProfile behavior,
  }) {
    if (candidates.isEmpty) return const <TruRankedPost>[];

    // Hard user controls first.
    final mutedTopics =
        settings.feedMutedTopics.map((e) => e.toLowerCase()).toSet();
    final mutedMoods =
        settings.feedMutedMoods.map((e) => e.toLowerCase()).toSet();

    bool isMuted(Post p) {
      final topic = p.category.trim().toLowerCase();
      final mood = (p.moodTag ?? '').trim().toLowerCase();
      if (mutedTopics.contains(topic)) return true;
      if (mood.isNotEmpty && mutedMoods.any((m) => mood.contains(m))) {
        return true;
      }
      return false;
    }

    final filtered = <Post>[];
    for (final p in candidates) {
      if (behavior.hiddenPostIds.contains(p.id)) continue;
      if (behavior.reportedPostIds.contains(p.id)) continue;
      if (isMuted(p)) continue;
      filtered.add(p);
    }

    if (filtered.isEmpty) return const <TruRankedPost>[];

    final now = DateTime.now();
    final rng = Random(behavior.lastSignalAt?.millisecondsSinceEpoch ??
        now.millisecondsSinceEpoch);
    final governanceState =
        _governance.assess(settings: settings, behavior: behavior, ctx: ctx);
    final presence = settings.emotionalPresenceState;

    // Global stimulation dial (0 calm → 1 intense). Low energy hard-caps intensity.
    final contentIntensity = min(
      settings.feedContentIntensity,
      presence.feedIntensityCap,
    );

    double affinityScore(Map<String, double> m, String key) {
      final v = m[key.toLowerCase()];
      if (v == null) return 0;
      // Soft saturating curve.
      return (v / 6).clamp(-1.5, 2.0);
    }

    double moodAffinity(Post p) {
      final mood = (p.moodTag ?? '').trim().toLowerCase();
      if (mood.isEmpty) return 0;
      // Try substring matches too (e.g. "anxious" vs "anx").
      double best = 0;
      for (final e in behavior.moodAffinity.entries) {
        if (e.key.isEmpty) continue;
        if (mood.contains(e.key) || e.key.contains(mood)) {
          best = max(best, (e.value / 7).clamp(-1.2, 1.8));
        }
      }
      return best;
    }

    double topicAffinity(Post p) {
      final topic = p.category.trim().toLowerCase();
      if (topic.isEmpty) return 0;
      return affinityScore(behavior.topicAffinity, topic);
    }

    double creatorAffinity(Post p) =>
        affinityScore(behavior.creatorAffinity, p.userId);

    double recency(Post p) {
      final ageMin = now.difference(p.createdAt).inMinutes;
      // ~0..1.4 for very recent, decays over ~48h.
      return (1.4 - (ageMin / (60 * 48)) * 1.4).clamp(0.0, 1.4);
    }

    double intensityPenalty(Post p) {
      // Sensitivity high => penalty for heavy posts.
      final sensitivity =
          settings.feedEmotionalSensitivity; // 0 open, 1 protect
      if (ctx.activeMode == TruExperienceMode.vent) {
        return 0; // user chose Vent.
      }

      final intensity = (p.emotionalIntensityScore.clamp(0, 100)) / 100.0;
      // When contentIntensity is low, we become more protective.
      final intensityBias =
          lerpDouble(0.0, 0.18, (1 - contentIntensity).clamp(0.0, 1.0)) ?? 0.1;
      final threshold =
          (lerpDouble(0.85, 0.45, sensitivity) ?? 0.6) - intensityBias;
      if (intensity <= threshold) return 0;
      final over = (intensity - threshold) / max(0.0001, (1 - threshold));
      return over *
          (1.4 + 0.6 * sensitivity + presence.recommendationSoftening * 0.85);
    }

    double boostScore(Post p) {
      if (!p.isBoosted) return 0;
      // Boosting is never allowed to override protected spaces.
      if (ctx.effectivePermissions.suppressVirality) return -0.8;
      // Low energy reduces boosted visibility.
      if (settings.isLowEnergyContext) return -0.25;

      // “Quality” boosting: cap engagement so it cannot runaway.
      final engagement =
          (p.likeCount + p.commentCount * 2 + p.shareCount * 3).toDouble();
      final quality = (min(90, engagement) / 90).clamp(0.0, 1.0);
      final rec = recency(p).clamp(0.0, 1.2);
      final governance = _governance.assessPost(
        post: p,
        state: governanceState,
        behavior: behavior,
      );
      return (0.14 + 0.30 * quality + 0.14 * rec) *
          (governance.rageAmplificationReduced ? 0.20 : 1.0) *
          (governance.quietPresenceProtected ? 0.72 : 1.0) *
          (1.0 - presence.recommendationSoftening * 0.55);
    }

    double kindBias(Post p) {
      final inferred = p.inferredExperienceMode();
      switch (kind) {
        case TruDiscoveryFeedKind.forYou:
          // For You is a blend: primarily current mode, with controlled romance.
          if (inferred == TruExperienceMode.vent) return -0.25;
          if (inferred.isAdultIntent) {
            return -0.4 + 1.4 * settings.feedRomanticVisibility;
          }
          if (inferred == TruExperienceMode.creator) {
            return -0.25 + 0.9 * settings.feedCreatorWeight;
          }
          return 0.25;
        case TruDiscoveryFeedKind.aura:
          return inferred == TruExperienceMode.social ||
                  inferred == TruExperienceMode.friendship ||
                  inferred == TruExperienceMode.creator
              ? 0.55
              : -1.0;
        case TruDiscoveryFeedKind.spark:
          return inferred.isAdultIntent ? 0.75 : -0.85;
        case TruDiscoveryFeedKind.vent:
          return inferred == TruExperienceMode.vent || p.isAnonymous
              ? 0.9
              : -1.2;
        case TruDiscoveryFeedKind.trending:
          // Trending: engagement + recency, but keep it non-toxic.
          final engagement =
              (p.likeCount + p.shareCount * 2 + p.commentCount).toDouble();
          final capped =
              min(80, engagement) / 80; // cap prevents runaway virality.
          final governance = _governance.assessPost(
            post: p,
            state: governanceState,
            behavior: behavior,
          );
          final supportFloor = governance.supportWeighted ? 0.28 : 0.0;
          final dominanceBrake =
              governance.rageAmplificationReduced ? -0.85 : 0.0;
          return 0.28 + supportFloor + capped * 0.62 + dominanceBrake;
      }
    }

    double noveltyBoost(Post p) {
      // Discovery balance: higher => more new creators + topics.
      final discovery = settings.feedDiscoveryBalance;
      final seen = behavior.recentSeenPostIds.contains(p.id);
      if (!seen) return 0.15 + 0.55 * discovery;
      return -0.10 * discovery;
    }

    double humanPacingBias(Post p) {
      final intensity = (p.emotionalIntensityScore.clamp(0, 100)) / 100.0;
      final mood = (p.moodTag ?? '').toLowerCase();
      var bias = 0.0;
      if (presence.isRestorative) {
        if (mood.contains('calm') ||
            mood.contains('heal') ||
            mood.contains('quiet') ||
            mood.contains('ground')) {
          bias += 0.24;
        }
        bias -= intensity * presence.recommendationSoftening;
      } else if (presence.label.contains('glowing')) {
        if (mood.contains('social') ||
            mood.contains('spark') ||
            mood.contains('radiant')) {
          bias += 0.18;
        }
      } else if (presence.label.contains('reflective')) {
        if (mood.contains('reflect') || mood.contains('old soul')) {
          bias += 0.22;
        }
        bias -= intensity * 0.12;
      }
      return bias;
    }

    double emotionalGravity(Post p) {
      final intensity = (p.emotionalIntensityScore.clamp(0, 100)) / 100.0;
      final text =
          '${p.category} ${p.moodTag ?? ''} ${p.content}'.toLowerCase();
      var gravity = intensity * 0.62;
      if (text.contains('confess') ||
          text.contains('vulnerable') ||
          text.contains('healing') ||
          text.contains('milestone') ||
          text.contains('memory') ||
          text.contains('reconnect')) {
        gravity += 0.24;
      }
      if (p.isAnonymous || p.contentType == TruPostContentType.support) {
        gravity += 0.14;
      }
      return gravity.clamp(0.0, 1.0) * presence.gravitySensitivity;
    }

    final scored = <_Scored>[];
    for (final p in filtered) {
      final governance = _governance.assessPost(
        post: p,
        state: governanceState,
        behavior: behavior,
      );
      final rawScore = recency(p) +
          kindBias(p) +
          boostScore(p) +
          moodAffinity(p) * 0.9 +
          topicAffinity(p) * 0.6 +
          creatorAffinity(p) * 0.45 +
          humanPacingBias(p) +
          noveltyBoost(p) -
          intensityPenalty(p);
      final score = rawScore * governance.multiplier -
          governanceState.auraExhaustion * p.emotionalIntensityScore / 180 -
          emotionalGravity(p) * presence.recommendationSoftening * 0.24;

      scored.add(_Scored(p, score: score, gravity: emotionalGravity(p)));
    }

    // Primary sort.
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Fairness pass: reduce same-author clustering and cap repeated creators.
    final out = <TruRankedPost>[];
    final authorStreak = <String, int>{};
    final authorCount = <String, int>{};
    // More discovery => stricter cap (surface more distinct creators).
    final cap = lerpDouble(7, 3, settings.feedDiscoveryBalance.clamp(0.0, 1.0))!
        .round();
    for (final s in scored) {
      final author = s.post.userId;
      final streak = authorStreak[author] ?? 0;
      final total = authorCount[author] ?? 0;
      if (total >= cap && scored.length > 16) {
        // Delay saturated creators rather than removing them.
        continue;
      }
      // If the same author would be repeated too much, probabilistically delay it.
      final streakPenalty =
          streak >= 1 ? (0.20 + 0.18 * streak) * presence.silenceSpacing : 0.0;
      final jitter = (rng.nextDouble() - 0.5) * 0.06;
      final silencePause = s.gravity * 0.18 * presence.silenceSpacing;
      final adjusted = s.score - streakPenalty - silencePause + jitter;

      // Insert with adjusted score to keep list stable.
      int idx = out.indexWhere((e) => e._internalScore < adjusted);
      if (idx == -1) idx = out.length;
      out.insert(
          idx, TruRankedPost._(post: s.post, internalScore: adjusted, why: ''));
      authorStreak[author] = (authorStreak[author] ?? 0) + 1;
      authorCount[author] = (authorCount[author] ?? 0) + 1;
    }

    // If the cap-filter removed too much, re-add remaining while keeping streak penalty.
    if (out.length < min(10, scored.length)) {
      for (final s in scored) {
        if (out.any((e) => e.post.id == s.post.id)) continue;
        final author = s.post.userId;
        final streak = authorStreak[author] ?? 0;
        final streakPenalty = streak >= 1
            ? (0.20 + 0.18 * streak) * presence.silenceSpacing
            : 0.0;
        final silencePause = s.gravity * 0.18 * presence.silenceSpacing;
        final adjusted = s.score -
            streakPenalty -
            silencePause +
            (rng.nextDouble() - 0.5) * 0.04;
        int idx = out.indexWhere((e) => e._internalScore < adjusted);
        if (idx == -1) idx = out.length;
        out.insert(idx,
            TruRankedPost._(post: s.post, internalScore: adjusted, why: ''));
        authorStreak[author] = (authorStreak[author] ?? 0) + 1;
      }
    }

    // Finalize reasons.
    return out.map((e) {
      final p = e.post;
      final inferred = p.inferredExperienceMode();
      final reasons = <String>[];
      reasons.add('Feed: ${kind.label}');
      reasons.add('Mode match: ${ctx.activeMode.name} → ${inferred.name}');
      if ((p.moodTag ?? '').trim().isNotEmpty) {
        reasons.add('Mood tag: ${p.moodTag}');
      }
      reasons.add(
          'Discovery balance: ${(settings.feedDiscoveryBalance * 100).round()}%');
      reasons.add('Presence culture: visibility is never a measure of worth');
      reasons.add('Presence state: ${presence.label}');
      final governance = _governance.assessPost(
        post: p,
        state: governanceState,
        behavior: behavior,
      );
      if (governance.labels.isNotEmpty) {
        reasons.add('Governance: ${governance.labels.join(' | ')}');
      }
      if (settings.feedMutedTopics.isNotEmpty ||
          settings.feedMutedMoods.isNotEmpty) {
        reasons.add('User controls applied (mutes/hides)');
      }
      if (p.isBoosted) {
        reasons.add('Boost flag: capped by emotional governance');
      }
      if (p.isMonetized) {
        reasons.add('Monetization: paced; never in protected spaces');
      }
      reasons.add(
          'Intensity: ${p.emotionalIntensityScore}/100 • sensitivity ${(settings.feedEmotionalSensitivity * 100).round()}%');
      reasons.add(
          'Pacing: silence spacing x${presence.silenceSpacing.toStringAsFixed(2)}');
      final gravity = emotionalGravity(p);
      if (gravity >= 0.44) {
        reasons.add('Emotional gravity: held with slower pacing');
      }
      return e.copyWith(why: reasons.join('\n'));
    }).toList(growable: false);
  }
}

enum TruDiscoveryFeedKind { forYou, aura, spark, vent, trending }

extension TruDiscoveryFeedKindX on TruDiscoveryFeedKind {
  String get label => switch (this) {
        TruDiscoveryFeedKind.forYou => 'For You',
        TruDiscoveryFeedKind.aura => 'Aura',
        TruDiscoveryFeedKind.spark => 'Spark',
        TruDiscoveryFeedKind.vent => 'Vent',
        TruDiscoveryFeedKind.trending => 'Trending',
      };
}

@immutable
class TruRankedPost {
  final Post post;
  final String why;
  final double _internalScore;

  const TruRankedPost._(
      {required this.post, required double internalScore, required this.why})
      : _internalScore = internalScore;

  TruRankedPost copyWith({Post? post, String? why}) => TruRankedPost._(
      post: post ?? this.post,
      internalScore: _internalScore,
      why: why ?? this.why);
}

class _Scored {
  final Post post;
  final double score;
  final double gravity;

  const _Scored(this.post, {required this.score, required this.gravity});
}
