import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/profile/quiz_result.dart';

@immutable
class TruDeepQuizDefinition {
  final String quizId;
  final String title;
  final String subtitle;
  final int minQuestions;
  final int maxQuestions;

  const TruDeepQuizDefinition({
    required this.quizId,
    required this.title,
    required this.subtitle,
    required this.minQuestions,
    required this.maxQuestions,
  });
}

@immutable
class TruProfileDeepInsight {
  final String quizId;
  final String title;
  final String primaryResult;
  final List<String> supportingInsights;
  final DateTime completedAt;

  const TruProfileDeepInsight({
    required this.quizId,
    required this.title,
    required this.primaryResult,
    required this.supportingInsights,
    required this.completedAt,
  });
}

class DeepQuizArchiveService {
  static const String whyDidYouStaySoLongQuizId = 'why_did_you_stay_so_long';
  static const String relationshipFlawsQuizId = 'relationship_flaws';
  static const String amIReadyToBeLovedQuizId = 'am_i_ready_to_be_loved';
  static const String emotionalTypeQuizId = 'emotional_type_trulura';
  static const String attractionCodeDeepQuizId = 'attraction_code_deep';
  static const String toxicPatternRecognitionQuizId =
      'toxic_pattern_recognition';

  static const List<TruDeepQuizDefinition> catalog = <TruDeepQuizDefinition>[
    TruDeepQuizDefinition(
      quizId: whyDidYouStaySoLongQuizId,
      title: 'Why Did You Stay So Long',
      subtitle:
          'A reflective archive prompt set about attachment, endurance, and what kept you there.',
      minQuestions: 5,
      maxQuestions: 10,
    ),
    TruDeepQuizDefinition(
      quizId: relationshipFlawsQuizId,
      title: 'Relationship Flaws',
      subtitle:
          'A deeper look at recurring friction patterns, blind spots, and emotional habits.',
      minQuestions: 5,
      maxQuestions: 10,
    ),
    TruDeepQuizDefinition(
      quizId: amIReadyToBeLovedQuizId,
      title: 'Am I Ready to Be Loved',
      subtitle:
          'A gentle readiness archive focused on openness, safety, and reciprocity.',
      minQuestions: 5,
      maxQuestions: 10,
    ),
    TruDeepQuizDefinition(
      quizId: emotionalTypeQuizId,
      title: 'Emotional Type',
      subtitle:
          'A Trulura identity-layer archive for emotional style, needs, and repair language.',
      minQuestions: 5,
      maxQuestions: 10,
    ),
    TruDeepQuizDefinition(
      quizId: attractionCodeDeepQuizId,
      title: 'Attraction Code',
      subtitle:
          'A deeper extension of attraction patterns, chemistry cues, and emotional pull.',
      minQuestions: 5,
      maxQuestions: 10,
    ),
    TruDeepQuizDefinition(
      quizId: toxicPatternRecognitionQuizId,
      title: 'Toxic Pattern Recognition',
      subtitle:
          'A private reflective archive for noticing harm patterns, warning signs, and learned responses.',
      minQuestions: 5,
      maxQuestions: 10,
    ),
  ];

  String _archiveKey(String userId) => 'healing_archive_v1_$userId';

  List<TruQuizResult> _decodeResults(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <TruQuizResult>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <TruQuizResult>[];
      return decoded
          .whereType<Map>()
          .map((entry) => TruQuizResult.fromJson(entry.cast<String, dynamic>()))
          .where((result) => result.quizType == TruQuizType.deepInsight)
          .toList(growable: false);
    } catch (_) {
      return const <TruQuizResult>[];
    }
  }

  Future<List<TruQuizResult>> getArchive({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeResults(prefs.getString(_archiveKey(userId)));
  }

  Future<void> upsertArchiveEntry({
    required String userId,
    required TruQuizResult result,
  }) async {
    final normalized = result.copyWith(
      quizType: TruQuizType.deepInsight,
      completionLevel: TruQuizCompletionLevel.deeper,
      visibility: result.visibility,
      updatedAt: result.updatedAt,
    );
    final current = await getArchive(userId: userId);
    final next = [...current];
    final index = next.indexWhere((entry) => entry.quizId == normalized.quizId);
    if (index == -1) {
      next.add(normalized);
    } else {
      next[index] = normalized;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _archiveKey(userId),
      jsonEncode(next.map((entry) => entry.toJson()).toList(growable: false)),
    );
  }

  TruDeepQuizDefinition? definitionFor(String quizId) {
    for (final quiz in catalog) {
      if (quiz.quizId == quizId) return quiz;
    }
    return null;
  }

  List<TruProfileDeepInsight> visibleProfileInsights(
    List<TruQuizResult> results,
  ) {
    final visible = results.where((result) => result.isPublic).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return visible.map((result) {
      final definition = definitionFor(result.quizId);
      return TruProfileDeepInsight(
        quizId: result.quizId,
        title: definition?.title ?? 'Deep Insight',
        primaryResult: result.primaryResult ?? 'Private reflection saved',
        supportingInsights:
            result.supportingInsights.take(2).toList(growable: false),
        completedAt: result.updatedAt,
      );
    }).toList(growable: false);
  }

  Map<String, int> compatibilityRefinementSignals(List<TruQuizResult> results) {
    final refinements = <String, int>{};
    for (final result in results) {
      for (final entry in result.traitScores.entries) {
        refinements.update(
          entry.key,
          (value) => ((value + entry.value) / 2).round(),
          ifAbsent: () => entry.value,
        );
      }
    }
    return refinements;
  }

  List<String> emotionalInsightThemes(List<TruQuizResult> results) {
    final themes = <String>{};
    for (final result in results) {
      themes.addAll(result.supportingInsights.take(2));
      if (result.primaryResult?.trim().isNotEmpty ?? false) {
        themes.add(result.primaryResult!.trim());
      }
    }
    return themes.toList(growable: false);
  }
}
