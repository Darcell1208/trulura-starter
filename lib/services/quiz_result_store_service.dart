import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';

class QuizResultStoreService {
  String _key(String userId) => 'quiz_result_registry_v1_$userId';

  Future<List<TruStoredQuizResult>> getResults({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.trim().isEmpty) return const <TruStoredQuizResult>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <TruStoredQuizResult>[];
      return decoded
          .whereType<Map>()
          .map((item) => TruStoredQuizResult.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <TruStoredQuizResult>[];
    }
  }

  Future<void> upsertResult(TruStoredQuizResult result) async {
    final current = await getResults(userId: result.userId);
    final next = [...current];
    final index = next.indexWhere((item) => item.quizId == result.quizId);
    if (index == -1) {
      next.add(result);
    } else {
      next[index] = result;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(result.userId),
      jsonEncode(next.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}
