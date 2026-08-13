import 'package:flutter/foundation.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';

enum TruQuizType {
  compatibilityTraits,
  deepInsight,
}

enum TruQuizCompletionLevel {
  micro,
  deeper,
}

@immutable
class TruQuizResult {
  final String userId;
  final String quizId;
  final TruQuizType quizType;
  final TruQuizCompletionLevel completionLevel;
  final TruQuizCategory category;
  final TruQuizLedgerState ledgerState;
  final TruQuizResultType resultType;
  final Map<String, int> traitScores;
  final Map<String, int> discoverySignals;
  final List<int> answerIndexes;
  final String? primaryResult;
  final String? secondaryResult;
  final String? secondaryTraitLabel;
  final String? resultSummary;
  final List<String> supportingInsights;
  final TruQuizVisibility visibility;
  final bool savedToVault;
  final bool selectedForProfileCard;
  final bool includeInMatching;
  final List<TruQuizEffect> routedEffects;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TruQuizResult({
    required this.userId,
    required this.quizId,
    this.quizType = TruQuizType.compatibilityTraits,
    this.completionLevel = TruQuizCompletionLevel.deeper,
    this.category = TruQuizCategory.social,
    this.ledgerState = TruQuizLedgerState.expansion,
    this.resultType = TruQuizResultType.compatibility,
    required this.traitScores,
    this.discoverySignals = const <String, int>{},
    this.answerIndexes = const <int>[],
    this.primaryResult,
    this.secondaryResult,
    this.secondaryTraitLabel,
    this.resultSummary,
    this.supportingInsights = const <String>[],
    this.visibility = TruQuizVisibility.privateOnly,
    this.savedToVault = true,
    this.selectedForProfileCard = false,
    this.includeInMatching = false,
    this.routedEffects = const <TruQuizEffect>[],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublic => visibility == TruQuizVisibility.profileOptIn;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'quizId': quizId,
        'quizType': quizType.name,
        'completionLevel': completionLevel.name,
        'category': category.name,
        'ledgerState': ledgerState.name,
        'resultType': resultType.name,
        'traitScores': traitScores,
        'discoverySignals': discoverySignals,
        'answers': answerIndexes,
        'primary_result': primaryResult,
        'secondary_result': secondaryResult,
        'secondary_trait_label': secondaryTraitLabel,
        'result_summary': resultSummary,
        'supporting_insights': supportingInsights,
        'isPublic': isPublic,
        'visibility': visibility.name,
        'savedToVault': savedToVault,
        'selectedForProfileCard': selectedForProfileCard,
        'includeInMatching': includeInMatching,
        'routedEffects':
            routedEffects.map((effect) => effect.name).toList(growable: false),
        'completed_at': updatedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TruQuizResult.fromJson(Map<String, dynamic> json) => TruQuizResult(
        userId: (json['userId'] as String?) ?? '',
        quizId: (json['quizId'] as String?) ?? 'unknown',
        quizType: _quizTypeFromName(json['quizType'] as String?),
        completionLevel: _completionLevelFromName(
          json['completionLevel'] as String?,
        ),
        category: _quizCategoryFromName(json['category'] as String?),
        ledgerState: _quizLedgerStateFromName(json['ledgerState'] as String?),
        resultType: _resultTypeFromName(json['resultType'] as String?),
        traitScores: (json['traitScores'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).round())) ??
            const <String, int>{},
        discoverySignals: (json['discoverySignals'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).round()),
            ) ??
            const <String, int>{},
        answerIndexes: ((json['answers'] as List?) ?? const <Object>[])
            .whereType<num>()
            .map((value) => value.round())
            .toList(growable: false),
        primaryResult:
            (json['primary_result'] as String?)?.trim().isNotEmpty == true
                ? (json['primary_result'] as String?)!.trim()
                : null,
        secondaryResult:
            (json['secondary_result'] as String?)?.trim().isNotEmpty == true
                ? (json['secondary_result'] as String?)!.trim()
                : null,
        secondaryTraitLabel:
            (json['secondary_trait_label'] as String?)?.trim().isNotEmpty ==
                    true
                ? (json['secondary_trait_label'] as String?)!.trim()
                : null,
        resultSummary:
            (json['result_summary'] as String?)?.trim().isNotEmpty == true
                ? (json['result_summary'] as String?)!.trim()
                : null,
        supportingInsights:
            ((json['supporting_insights'] as List?) ?? const <Object>[])
                .whereType<String>()
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
        visibility: _visibilityFromJson(json),
        savedToVault: (json['savedToVault'] as bool?) ?? true,
        selectedForProfileCard: (json['selectedForProfileCard'] as bool?) ??
            ((json['isPublic'] as bool?) ?? false),
        includeInMatching: (json['includeInMatching'] as bool?) ??
            ((json['visibility'] as String?) == 'matchingOnly'),
        routedEffects: ((json['routedEffects'] as List?) ?? const <Object>[])
            .whereType<String>()
            .map(_effectFromName)
            .toList(growable: false),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(
              (json['updatedAt'] as String?) ??
                  (json['completed_at'] as String?) ??
                  '',
            ) ??
            DateTime.now(),
      );

  TruQuizResult copyWith({
    TruQuizType? quizType,
    TruQuizCompletionLevel? completionLevel,
    TruQuizCategory? category,
    TruQuizLedgerState? ledgerState,
    TruQuizResultType? resultType,
    Map<String, int>? traitScores,
    Map<String, int>? discoverySignals,
    List<int>? answerIndexes,
    String? primaryResult,
    String? secondaryResult,
    String? secondaryTraitLabel,
    String? resultSummary,
    List<String>? supportingInsights,
    TruQuizVisibility? visibility,
    bool? savedToVault,
    bool? selectedForProfileCard,
    bool? includeInMatching,
    List<TruQuizEffect>? routedEffects,
    DateTime? updatedAt,
  }) =>
      TruQuizResult(
        userId: userId,
        quizId: quizId,
        quizType: quizType ?? this.quizType,
        completionLevel: completionLevel ?? this.completionLevel,
        category: category ?? this.category,
        ledgerState: ledgerState ?? this.ledgerState,
        resultType: resultType ?? this.resultType,
        traitScores: traitScores ?? this.traitScores,
        discoverySignals: discoverySignals ?? this.discoverySignals,
        answerIndexes: answerIndexes ?? this.answerIndexes,
        primaryResult: primaryResult ?? this.primaryResult,
        secondaryResult: secondaryResult ?? this.secondaryResult,
        secondaryTraitLabel: secondaryTraitLabel ?? this.secondaryTraitLabel,
        resultSummary: resultSummary ?? this.resultSummary,
        supportingInsights: supportingInsights ?? this.supportingInsights,
        visibility: visibility ?? this.visibility,
        savedToVault: savedToVault ?? this.savedToVault,
        selectedForProfileCard:
            selectedForProfileCard ?? this.selectedForProfileCard,
        includeInMatching: includeInMatching ?? this.includeInMatching,
        routedEffects: routedEffects ?? this.routedEffects,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

TruQuizLedgerState _quizLedgerStateFromName(String? raw) {
  for (final value in TruQuizLedgerState.values) {
    if (value.name == raw) return value;
  }
  return TruQuizLedgerState.expansion;
}

TruQuizType _quizTypeFromName(String? raw) {
  for (final value in TruQuizType.values) {
    if (value.name == raw) return value;
  }
  return TruQuizType.compatibilityTraits;
}

TruQuizCompletionLevel _completionLevelFromName(String? raw) {
  for (final value in TruQuizCompletionLevel.values) {
    if (value.name == raw) return value;
  }
  return TruQuizCompletionLevel.deeper;
}

TruQuizCategory _quizCategoryFromName(String? raw) {
  for (final value in TruQuizCategory.values) {
    if (value.name == raw) return value;
  }
  return TruQuizCategory.social;
}

TruQuizResultType _resultTypeFromName(String? raw) {
  for (final value in TruQuizResultType.values) {
    if (value.name == raw) return value;
  }
  return TruQuizResultType.compatibility;
}

TruQuizVisibility _visibilityFromJson(Map<String, dynamic> json) {
  final raw = json['visibility'] as String?;
  for (final value in TruQuizVisibility.values) {
    if (value.name == raw) return value;
  }
  final legacyPublic = (json['isPublic'] as bool?) ?? false;
  return legacyPublic
      ? TruQuizVisibility.profileOptIn
      : TruQuizVisibility.privateOnly;
}

TruQuizEffect _effectFromName(String raw) {
  for (final value in TruQuizEffect.values) {
    if (value.name == raw) return value;
  }
  return TruQuizEffect.savedVault;
}
