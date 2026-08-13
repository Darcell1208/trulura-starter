import 'package:flutter/foundation.dart';
import 'package:trulura/models/profile/quiz_result.dart';
import 'package:trulura/services/app_settings_service.dart';
import 'package:trulura/services/compatibility_service.dart';

class AppState with ChangeNotifier {
  final CompatibilityService _compat = CompatibilityService();
  final AppSettingsService _settings = AppSettingsService();

  bool _interestQuizCompleted = false;
  bool microQuizCompleted = false;
  bool quizCompleted = false;
  bool deeperQuizCompleted = false;
  Map<String, dynamic> quizResults = <String, dynamic>{};
  TruQuizResult? latestQuizResult;
  TruQuizResult? latestMicroQuizResult;
  TruQuizResult? latestDeeperQuizResult;
  String selectedVibe = 'Old Soul';
  bool isAnonymous = false;
  String currentTab = 'aura';

  String? _hydratedUserId;

  bool get interestQuizCompleted => _interestQuizCompleted;
  bool get basicPersonalizationCompleted => interestQuizCompleted;
  bool get hasPersonalizationQuiz => microQuizCompleted || deeperQuizCompleted;

  void completeQuiz(Map<String, dynamic> results) {
    quizResults = Map<String, dynamic>.from(results);
    quizCompleted = quizResults.isNotEmpty;
    deeperQuizCompleted = quizCompleted;
    microQuizCompleted = microQuizCompleted || deeperQuizCompleted;
    notifyListeners();
  }

  void completeStructuredQuiz(TruQuizResult result) {
    latestQuizResult = result;
    quizResults = Map<String, dynamic>.from(result.traitScores);
    if (result.completionLevel == TruQuizCompletionLevel.deeper) {
      latestDeeperQuizResult = result;
      deeperQuizCompleted = true;
      microQuizCompleted = true;
    } else if (result.completionLevel == TruQuizCompletionLevel.micro) {
      latestMicroQuizResult = result;
      microQuizCompleted = true;
    }
    quizCompleted = hasPersonalizationQuiz;
    notifyListeners();
  }

  void setTab(String tab) {
    final normalized = tab.trim().toLowerCase();
    final next = switch (normalized) {
      'explore' => 'explore',
      'sync' => 'sync',
      _ => 'aura',
    };
    if (next == currentTab) return;
    currentTab = next;
    notifyListeners();
  }

  void setVibe(String vibe) {
    if (vibe == selectedVibe) return;
    selectedVibe = vibe;
    notifyListeners();
  }

  void toggleAnonymous() {
    isAnonymous = !isAnonymous;
    notifyListeners();
  }

  void syncProfileState({
    required String vibe,
    required bool anonymous,
  }) {
    var changed = false;
    if (selectedVibe != vibe) {
      selectedVibe = vibe;
      changed = true;
    }
    if (isAnonymous != anonymous) {
      isAnonymous = anonymous;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> hydrateQuizState({required String? userId}) async {
    if (userId == null) {
      _hydratedUserId = null;
      _interestQuizCompleted = false;
      microQuizCompleted = false;
      quizCompleted = false;
      deeperQuizCompleted = false;
      quizResults = <String, dynamic>{};
      latestQuizResult = null;
      latestMicroQuizResult = null;
      latestDeeperQuizResult = null;
      notifyListeners();
      return;
    }
    if (_hydratedUserId == userId &&
        (_interestQuizCompleted || microQuizCompleted || deeperQuizCompleted)) {
      return;
    }

    final results = await _compat.getQuizResults(userId: userId);
    final latestPersonalization =
        _compat.latestPersonalizationQuizResult(results);
    final latestMicro = _compat.latestMicroQuizResult(results);
    final latestDeeper = _compat.latestDeeperQuizResult(results);
    _hydratedUserId = userId;
    _interestQuizCompleted = await _settings.getInterestQuizCompleted(
      userId: userId,
    );
    latestQuizResult = latestPersonalization;
    latestMicroQuizResult = latestMicro;
    latestDeeperQuizResult = latestDeeper;
    microQuizCompleted = latestMicro != null || latestDeeper != null;
    deeperQuizCompleted = latestDeeper != null;
    quizCompleted = hasPersonalizationQuiz;
    if (latestPersonalization == null) {
      quizResults = <String, dynamic>{};
      notifyListeners();
      return;
    }

    quizResults = Map<String, dynamic>.from(
      latestPersonalization.traitScores,
    );
    notifyListeners();
  }

  Future<void> persistQuizResult({
    required String userId,
    required TruQuizResult result,
  }) async {
    await _compat.upsertQuizResult(result);
    completeStructuredQuiz(result);
    _hydratedUserId = userId;
  }

  Future<void> markInterestQuizCompleted({required String userId}) async {
    await _settings.setInterestQuizCompleted(true, userId: userId);
    _hydratedUserId = userId;
    if (!_interestQuizCompleted) {
      _interestQuizCompleted = true;
      notifyListeners();
    }
  }
}
