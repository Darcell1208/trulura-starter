import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/user_service.dart';

/// Hidden trust scoring system.
///
/// - Stores an internal score (0–100)
/// - Derives a coarse [TruRiskLevel]
/// - Exposes *labels* only (no numeric public UI)
///
/// This is local-first; later you can replace storage with:
/// - Supabase: `trust_scores (user_id, score, risk_level, last_updated)`
/// - Firebase: a `trust_scores/{uid}` document
class TrustScoreService {
  static const String _keyBase = 'trust_scores_v1';

  String _k(String userId) => '${_keyBase}_$userId';

  Future<int> getScore({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId));
      final decoded = raw != null ? jsonDecode(raw) : null;
      if (decoded is! Map) return 70;
      final score = (decoded['score'] as int?) ?? 70;
      return score.clamp(0, 100);
    } catch (e) {
      debugPrint('TrustScoreService.getScore failed: $e');
      return 70;
    }
  }

  Future<void> setScore({required String userId, required int score}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = score.clamp(0, 100);
      final risk = _riskForScore(s);
      final now = DateTime.now();
      await prefs.setString(_k(userId), jsonEncode({'score': s, 'risk': risk.name, 'lastUpdated': now.toIso8601String()}));

      final me = await UserService().getCurrentUser();
      if (me != null && me.id == userId) {
        await UserService().saveUser(me.copyWith(trustScore: s, riskLevel: risk, trustLastUpdated: now, updatedAt: now));
      }
    } catch (e) {
      debugPrint('TrustScoreService.setScore failed: $e');
    }
  }

  TruRiskLevel _riskForScore(int score) {
    if (score < 30) return TruRiskLevel.high;
    if (score < 55) return TruRiskLevel.medium;
    return TruRiskLevel.low;
  }

  /// Public-facing (optional) indicator label (never numeric).
  ///
  /// If the user hides trust indicators, UI should not display this.
  String? labelFor(User user) {
    if (!user.showTrustIndicator) return null;
    final s = user.trustScore.clamp(0, 100);
    if (user.verificationLevel.index >= TruVerificationLevel.level3.index && s >= 80) return 'Highly Trusted';
    if (user.verificationLevel.index >= TruVerificationLevel.level2.index && s >= 65) return 'Safe to Meet';
    if (user.verificationLevel.index >= TruVerificationLevel.level1.index && s >= 55) return 'Verified';
    if (s >= 55) return 'Trusted';
    return 'Standard';
  }
}
