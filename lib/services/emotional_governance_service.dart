import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/feed_behavior_service.dart';

/// Canonical emotional governance layer for TruLura.
///
/// This service is intentionally local-first and non-punitive. It does not
/// decide human worth, public status, or hard sanctions. It only tunes pacing,
/// visibility distribution, and protective friction so the ecosystem behaves
/// like sustainable emotional infrastructure instead of an engagement contest.
class EmotionalGovernanceService {
  const EmotionalGovernanceService();

  TruEmotionalGovernanceState assess({
    required AppProvider settings,
    required TruFeedBehaviorProfile behavior,
    required TruParticipationContext ctx,
  }) {
    final now = DateTime.now();
    final recentSignals = behavior.lastSignalAt == null
        ? 0
        : max(0, 8 - now.difference(behavior.lastSignalAt!).inHours);
    final affinityLoad = behavior.moodAffinity.values
        .fold<double>(0, (sum, v) => sum + v.abs())
        .clamp(0, 42);
    final supportLoad =
        (behavior.topicAffinity['support'] ?? 0) + (behavior.topicAffinity['vent'] ?? 0);
    final lowEnergy = settings.isLowEnergyContext;
    final sensitivity = settings.feedEmotionalSensitivity;
    final creatorLoad = settings.feedCreatorWeight;

    final exhaustion = ((lowEnergy ? 0.34 : 0.0) +
            sensitivity * 0.28 +
            min(0.22, affinityLoad / 190) +
            min(0.18, recentSignals / 40) +
            (ctx.activeMode == TruExperienceMode.vent ? 0.14 : 0.0))
        .clamp(0.0, 1.0);

    final supportFatigue = (supportLoad / 16 + (lowEnergy ? 0.18 : 0.0))
        .clamp(0.0, 1.0);

    final creatorFatigue =
        (creatorLoad > 0.66 ? (creatorLoad - 0.66) * 1.7 : 0.0)
            .clamp(0.0, 1.0);

    final protectiveFriction = max(exhaustion, supportFatigue * 0.86);
    return TruEmotionalGovernanceState(
      auraExhaustion: exhaustion,
      supportFatigue: supportFatigue,
      creatorFatigue: creatorFatigue,
      protectiveFriction: protectiveFriction,
      lowStimulation: lowEnergy || exhaustion >= 0.58,
      recommendedMode: exhaustion >= 0.62
          ? TruExperienceMode.vent
          : supportFatigue >= 0.56
              ? TruExperienceMode.social
              : ctx.activeMode,
    );
  }

  TruPostGovernance assessPost({
    required Post post,
    required TruEmotionalGovernanceState state,
    required TruFeedBehaviorProfile behavior,
  }) {
    final category = post.category.toLowerCase();
    final content = '${post.content} ${post.caption ?? ''}'.toLowerCase();
    final mood = (post.moodTag ?? '').toLowerCase();
    final engagement =
        post.likeCount + post.commentCount * 2 + post.shareCount * 3;
    final intensity = post.emotionalIntensityScore.clamp(0, 100) / 100.0;
    final inferred = post.inferredExperienceMode();

    final support =
        post.contentType == TruPostContentType.support ||
        inferred == TruExperienceMode.vent ||
        post.isAnonymous ||
        category.contains('support') ||
        category.contains('vent') ||
        mood.contains('healing') ||
        mood.contains('calm') ||
        content.contains('support') ||
        content.contains('holding space');

    final traumaFarmSignals = [
      'trauma',
      'destroyed',
      'exposed',
      'humiliated',
      'rage',
      'hate',
    ].where(content.contains).length;

    final rageAmplification =
        traumaFarmSignals >= 2 || mood.contains('angry') || category.contains('drama');

    final quietUser = engagement <= 2 && !post.isBoosted;
    final highDominance = engagement >= 90 || post.isBoosted;
    final repeatedCreator = (behavior.creatorAffinity[post.userId] ?? 0) >= 8;

    final valueProtection = support || quietUser ? 0.18 : 0.0;
    final overloadPenalty = intensity > 0.72 && state.lowStimulation
        ? (intensity - 0.72) * 1.8
        : 0.0;
    final dominancePenalty =
        highDominance ? 0.18 + min(0.28, engagement / 420) : 0.0;
    final creatorFatiguePenalty =
        post.isCreatorContent || repeatedCreator ? state.creatorFatigue * 0.34 : 0.0;
    final ragePenalty = rageAmplification ? 0.50 + state.protectiveFriction * 0.22 : 0.0;
    final supportBoost = support && !rageAmplification
        ? 0.20 + (state.supportFatigue < 0.64 ? 0.10 : 0.0)
        : 0.0;
    final quietBoost = quietUser ? 0.14 + state.protectiveFriction * 0.12 : 0.0;

    final multiplier = (1.0 +
            valueProtection +
            supportBoost +
            quietBoost -
            overloadPenalty -
            dominancePenalty -
            creatorFatiguePenalty -
            ragePenalty)
        .clamp(0.28, 1.34);

    final friction = max(overloadPenalty, max(ragePenalty, creatorFatiguePenalty));
    final labels = <String>[
      if (quietUser) 'quiet presence protected',
      if (support) 'support labor valued',
      if (highDominance) 'anti-dominance cap',
      if (state.lowStimulation) 'low-stimulation pacing',
      if (rageAmplification) 'rage amplification reduced',
      if (post.isCreatorContent && state.creatorFatigue > 0.25)
        'creator cooldown respected',
      if (friction > 0.30) 'protective friction active',
    ];

    return TruPostGovernance(
      multiplier: multiplier.toDouble(),
      protectiveFriction: friction.clamp(0.0, 1.0).toDouble(),
      supportWeighted: support,
      quietPresenceProtected: quietUser,
      rageAmplificationReduced: rageAmplification,
      labels: labels,
    );
  }
}

@immutable
class TruEmotionalGovernanceState {
  final double auraExhaustion;
  final double supportFatigue;
  final double creatorFatigue;
  final double protectiveFriction;
  final bool lowStimulation;
  final TruExperienceMode recommendedMode;

  const TruEmotionalGovernanceState({
    required this.auraExhaustion,
    required this.supportFatigue,
    required this.creatorFatigue,
    required this.protectiveFriction,
    required this.lowStimulation,
    required this.recommendedMode,
  });
}

@immutable
class TruPostGovernance {
  final double multiplier;
  final double protectiveFriction;
  final bool supportWeighted;
  final bool quietPresenceProtected;
  final bool rageAmplificationReduced;
  final List<String> labels;

  const TruPostGovernance({
    required this.multiplier,
    required this.protectiveFriction,
    required this.supportWeighted,
    required this.quietPresenceProtected,
    required this.rageAmplificationReduced,
    required this.labels,
  });
}
