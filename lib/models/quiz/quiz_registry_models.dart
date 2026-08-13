import 'package:flutter/foundation.dart';

enum TruQuizCategory {
  onboarding,
  social,
  spark,
  healing,
  identity,
  advanced,
}

enum TruQuizMode {
  onboarding,
  social,
  spark,
  healing,
  identity,
  advanced,
  mixed,
}

enum TruQuizResultType {
  archetype,
  traits,
  compatibility,
  reflectiveInsights,
  attractionProfile,
  readiness,
}

enum TruQuizVisibility {
  privateOnly,
  profileOptIn,
  matchingOnly,
}

enum TruQuizLedgerState {
  confirmed,
  recovery,
  expansion,
}

enum TruQuizUnlockTier {
  open,
  progressive,
  deepening,
}

enum TruQuizEffect {
  feedPersonalization,
  friendshipSuggestions,
  nicheCommunitySuggestions,
  sparkDatingCompatibility,
  attractionOverlays,
  healingArchive,
  truJourney,
  identityReflection,
  emotionalPatterning,
  relationshipReadiness,
  profileCard,
  savedVault,
}

enum TruQuizLauncherSurface {
  onboardingFlow,
  quizLibrary,
  homeAura,
  homeSpark,
  settings,
  profileGrowth,
  profileCompatibility,
  healingVault,
  matchingDeck,
}

@immutable
class TruQuizCategoryMeta {
  final String label;
  final String shortDescription;
  final String longDescription;
  final int plannedScale;
  final bool isLargestBucket;

  const TruQuizCategoryMeta({
    required this.label,
    required this.shortDescription,
    required this.longDescription,
    required this.plannedScale,
    this.isLargestBucket = false,
  });
}

extension TruQuizCategoryX on TruQuizCategory {
  TruQuizCategoryMeta get meta {
    switch (this) {
      case TruQuizCategory.onboarding:
        return const TruQuizCategoryMeta(
          label: 'Onboarding',
          shortDescription: 'Entry tuning, intent, and setup reads.',
          longDescription:
              'Fast entry quizzes that calibrate onboarding, first-launch prompts, and early personalization without locking the system into a tiny starter set.',
          plannedScale: 10,
        );
      case TruQuizCategory.social:
        return const TruQuizCategoryMeta(
          label: 'Social',
          shortDescription: 'Friendship, community, and social energy.',
          longDescription:
              'Social quizzes tune friendship suggestions, communities, posting rhythm, and platonic discovery surfaces across Aura and Explore.',
          plannedScale: 16,
        );
      case TruQuizCategory.spark:
        return const TruQuizCategoryMeta(
          label: 'Spark',
          shortDescription: 'Attraction, dating, chemistry, and romantic fit.',
          longDescription:
              'Spark is the largest master-library bucket and is designed to scale across attraction codes, chemistry, love language profiles, dating signals, and matching layers.',
          plannedScale: 32,
          isLargestBucket: true,
        );
      case TruQuizCategory.healing:
        return const TruQuizCategoryMeta(
          label: 'Healing',
          shortDescription: 'Reflection, repair, and private archives.',
          longDescription:
              'Healing quizzes live in the private vault by default and support reflective archives, emotional repair, and deeper self-awareness.',
          plannedScale: 14,
        );
      case TruQuizCategory.identity:
        return const TruQuizCategoryMeta(
          label: 'Identity',
          shortDescription: 'Emotional identity and inner wiring.',
          longDescription:
              'Identity quizzes map emotional type, attachment tone, self-expression, and inner patterning into profile-aware but user-controlled results.',
          plannedScale: 10,
        );
      case TruQuizCategory.advanced:
        return const TruQuizCategoryMeta(
          label: 'Advanced',
          shortDescription:
              'Compatibility systems and deeper layered matching.',
          longDescription:
              'Advanced quizzes refine compatibility, long-range matching, and multi-layer connection logic once foundational signals already exist.',
          plannedScale: 12,
        );
    }
  }
}

extension TruQuizVisibilityX on TruQuizVisibility {
  String get label {
    switch (this) {
      case TruQuizVisibility.privateOnly:
        return 'Private';
      case TruQuizVisibility.profileOptIn:
        return 'Profile';
      case TruQuizVisibility.matchingOnly:
        return 'Matching only';
    }
  }
}

extension TruQuizLedgerStateX on TruQuizLedgerState {
  String get label {
    switch (this) {
      case TruQuizLedgerState.confirmed:
        return 'CONFIRMED';
      case TruQuizLedgerState.recovery:
        return 'RECOVERY';
      case TruQuizLedgerState.expansion:
        return 'EXPANSION';
    }
  }
}

extension TruQuizUnlockTierX on TruQuizUnlockTier {
  String get label {
    switch (this) {
      case TruQuizUnlockTier.open:
        return 'Open';
      case TruQuizUnlockTier.progressive:
        return 'Progressive';
      case TruQuizUnlockTier.deepening:
        return 'Deepening';
    }
  }
}

extension TruQuizLauncherSurfaceX on TruQuizLauncherSurface {
  String get label {
    switch (this) {
      case TruQuizLauncherSurface.onboardingFlow:
        return 'Onboarding';
      case TruQuizLauncherSurface.quizLibrary:
        return 'Library';
      case TruQuizLauncherSurface.homeAura:
        return 'Aura home';
      case TruQuizLauncherSurface.homeSpark:
        return 'Spark home';
      case TruQuizLauncherSurface.settings:
        return 'Settings';
      case TruQuizLauncherSurface.profileGrowth:
        return 'Profile growth';
      case TruQuizLauncherSurface.profileCompatibility:
        return 'Compatibility';
      case TruQuizLauncherSurface.healingVault:
        return 'Healing vault';
      case TruQuizLauncherSurface.matchingDeck:
        return 'Matching';
    }
  }
}

@immutable
class TruQuizAnswerOption {
  final String id;
  final String label;

  const TruQuizAnswerOption({
    required this.id,
    required this.label,
  });
}

@immutable
class TruQuizQuestionDefinition {
  final String id;
  final String prompt;
  final List<TruQuizAnswerOption> options;

  const TruQuizQuestionDefinition({
    required this.id,
    required this.prompt,
    required this.options,
  });
}

@immutable
class TruQuizRegistryEntry {
  final String quizId;
  final String title;
  final TruQuizCategory category;
  final TruQuizLedgerState ledgerState;
  final String subcategory;
  final TruQuizMode mode;
  final List<TruQuizQuestionDefinition> questionSet;
  final TruQuizResultType resultType;
  final TruQuizVisibility visibilityDefault;
  final Set<TruQuizVisibility> visibilityOptions;
  final Set<TruQuizEffect> effects;
  final Set<TruQuizLauncherSurface> launcherSurfaces;
  final bool isCore;
  final bool isOptional;
  final bool isCanon;
  final bool saveToVaultByDefault;
  final bool supportsProfileCards;
  final bool supportsMatching;
  final TruQuizUnlockTier unlockTier;
  final bool startsUnlocked;
  final List<String> unlockAfterQuizIds;
  final int minimumCompletedQuizzes;
  final int orderIndex;
  final int estimatedMinutes;
  final List<String> tags;
  final String subtitle;

  const TruQuizRegistryEntry({
    required this.quizId,
    required this.title,
    required this.category,
    required this.ledgerState,
    required this.subcategory,
    required this.mode,
    required this.questionSet,
    required this.resultType,
    required this.visibilityDefault,
    required this.visibilityOptions,
    required this.effects,
    required this.launcherSurfaces,
    required this.isCore,
    required this.isOptional,
    required this.isCanon,
    required this.saveToVaultByDefault,
    required this.supportsProfileCards,
    required this.supportsMatching,
    required this.unlockTier,
    required this.startsUnlocked,
    required this.unlockAfterQuizIds,
    required this.minimumCompletedQuizzes,
    required this.orderIndex,
    required this.estimatedMinutes,
    required this.tags,
    required this.subtitle,
  });

  bool get isReady => questionSet.isNotEmpty;

  bool isUnlocked({
    required Set<String> completedQuizIds,
    required int completedQuizCount,
  }) {
    if (startsUnlocked) return true;
    if (unlockAfterQuizIds.isNotEmpty &&
        unlockAfterQuizIds.every(completedQuizIds.contains)) {
      return true;
    }
    if (minimumCompletedQuizzes > 0 &&
        completedQuizCount >= minimumCompletedQuizzes) {
      return true;
    }
    return false;
  }
}

@immutable
class TruStoredQuizResult {
  final String userId;
  final String quizId;
  final TruQuizCategory category;
  final TruQuizLedgerState ledgerState;
  final List<int> answers;
  final String primaryResult;
  final List<String> secondaryResults;
  final String summary;
  final Map<String, int> traits;
  final Map<String, int> discoverySignals;
  final List<String> supportingInsights;
  final TruQuizVisibility visibility;
  final bool selectedForProfileCard;
  final bool savedToVault;
  final bool includeInMatching;
  final List<TruQuizEffect> routedEffects;
  final DateTime completedAt;
  final DateTime updatedAt;

  const TruStoredQuizResult({
    required this.userId,
    required this.quizId,
    required this.category,
    required this.ledgerState,
    required this.answers,
    required this.primaryResult,
    this.secondaryResults = const <String>[],
    this.summary = '',
    this.traits = const <String, int>{},
    this.discoverySignals = const <String, int>{},
    this.supportingInsights = const <String>[],
    this.visibility = TruQuizVisibility.privateOnly,
    this.selectedForProfileCard = false,
    this.savedToVault = true,
    this.includeInMatching = false,
    this.routedEffects = const <TruQuizEffect>[],
    required this.completedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'quizId': quizId,
        'category': category.name,
        'ledgerState': ledgerState.name,
        'answers': answers,
        'primaryResult': primaryResult,
        'secondaryResults': secondaryResults,
        'summary': summary,
        'traits': traits,
        'discoverySignals': discoverySignals,
        'supportingInsights': supportingInsights,
        'visibility': visibility.name,
        'selectedForProfileCard': selectedForProfileCard,
        'savedToVault': savedToVault,
        'includeInMatching': includeInMatching,
        'routedEffects':
            routedEffects.map((effect) => effect.name).toList(growable: false),
        'completedAt': completedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruStoredQuizResult.fromJson(Map<String, dynamic> json) {
    return TruStoredQuizResult(
      userId: (json['userId'] as String?) ?? '',
      quizId: (json['quizId'] as String?) ?? '',
      category: _categoryFromName(json['category'] as String?),
      ledgerState: _ledgerStateFromName(json['ledgerState'] as String?),
      answers: ((json['answers'] as List?) ?? const <Object>[])
          .whereType<num>()
          .map((value) => value.round())
          .toList(growable: false),
      primaryResult: (json['primaryResult'] as String?) ?? '',
      secondaryResults:
          ((json['secondaryResults'] as List?) ?? const <Object>[])
              .whereType<String>()
              .toList(growable: false),
      summary: (json['summary'] as String?) ?? '',
      traits: (json['traits'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).round()),
          ) ??
          const <String, int>{},
      discoverySignals: (json['discoverySignals'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).round()),
          ) ??
          const <String, int>{},
      supportingInsights:
          ((json['supportingInsights'] as List?) ?? const <Object>[])
              .whereType<String>()
              .toList(growable: false),
      visibility: _visibilityFromName(json['visibility'] as String?),
      selectedForProfileCard:
          (json['selectedForProfileCard'] as bool?) ?? false,
      savedToVault: (json['savedToVault'] as bool?) ?? true,
      includeInMatching: (json['includeInMatching'] as bool?) ?? false,
      routedEffects: ((json['routedEffects'] as List?) ?? const <Object>[])
          .whereType<String>()
          .map(_effectFromName)
          .toList(growable: false),
      completedAt: DateTime.tryParse((json['completedAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

TruQuizCategory _categoryFromName(String? raw) {
  for (final value in TruQuizCategory.values) {
    if (value.name == raw) return value;
  }
  return TruQuizCategory.social;
}

TruQuizVisibility _visibilityFromName(String? raw) {
  for (final value in TruQuizVisibility.values) {
    if (value.name == raw) return value;
  }
  return TruQuizVisibility.privateOnly;
}

TruQuizEffect _effectFromName(String raw) {
  for (final value in TruQuizEffect.values) {
    if (value.name == raw) return value;
  }
  return TruQuizEffect.savedVault;
}

TruQuizLedgerState _ledgerStateFromName(String? raw) {
  for (final value in TruQuizLedgerState.values) {
    if (value.name == raw) return value;
  }
  return TruQuizLedgerState.expansion;
}
