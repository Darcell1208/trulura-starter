import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/message.dart';
import 'package:trulura/services/communication_safety_service.dart';

/// AuraShield (9.16): behavioral intelligence + red-flag detection.
///
/// Local-first, non-invasive heuristics meant to:
/// - surface subtle safety context
/// - reduce visibility / eligibility when patterns escalate
///
/// This is *not* a moderation verdict and avoids stigmatizing labels.
class AuraShieldService {
  static const _userSignalsKey = 'aurashield_user_signals_v1';

  static const Duration _windowShort = Duration(hours: 6);
  static const Duration _windowLong = Duration(days: 21);

  Future<void> recordUserSignal(TruAuraShieldUserSignal signal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userSignalsKey);
      final decoded = raw == null ? null : jsonDecode(raw);
      final list = decoded is List ? decoded.whereType<Map>().map((e) => TruAuraShieldUserSignal.fromJson(e.cast<String, dynamic>())).toList() : <TruAuraShieldUserSignal>[];
      list.add(signal);
      // Keep bounded.
      final now = DateTime.now();
      final trimmed = list.where((e) => now.difference(e.createdAt) <= _windowLong).toList(growable: false);
      await prefs.setString(_userSignalsKey, jsonEncode(trimmed.map((e) => e.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('AuraShieldService.recordUserSignal failed: $e');
    }
  }

  /// Assess a thread using the message timeline (works offline).
  AuraShieldAssessment assessThread({required String viewerUserId, required List<Message> messages}) {
    try {
      if (messages.isEmpty) return const AuraShieldAssessment(level: AuraShieldLevel.low, score: 0, tags: []);

      final now = DateTime.now();
      final otherMsgs = messages.where((m) => m.senderId != viewerUserId).toList(growable: false);
      final allText = otherMsgs.map((m) => m.content).join('\n');

      // Pattern detectors (intentionally conservative).
      final coercion = <RegExp>[
        RegExp(r"\b(send|wire|transfer)\b.*\b(money|cash|crypto|bitcoin)\b", caseSensitive: false),
        RegExp(r"\b(fee|deposit)\b", caseSensitive: false),
        RegExp(r"\b(secret|don't tell|delete this)\b", caseSensitive: false),
        RegExp(r"\b(telegram|whatsapp|snap|kik)\b", caseSensitive: false),
      ];
      final boundary = <RegExp>[
        RegExp(r"\b(you have to|you must|prove it|if you really)\b", caseSensitive: false),
        RegExp(r"\b(stop being dramatic|you're crazy|you're overreacting)\b", caseSensitive: false),
      ];
      final loveBomb = <RegExp>[
        RegExp(r"\b(soulmate|meant to be|can't live without you)\b", caseSensitive: false),
        RegExp(r"\b(you're perfect|obsessed with you|all i need is you)\b", caseSensitive: false),
      ];

      int coercionHits = coercion.where((p) => p.hasMatch(allText)).length;
      int boundaryHits = boundary.where((p) => p.hasMatch(allText)).length;
      int loveHits = loveBomb.where((p) => p.hasMatch(allText)).length;

      // Escalation: many messages in short window (can indicate pressure).
      final shortCount = otherMsgs.where((m) => now.difference(m.timestamp) <= _windowShort).length;
      final escalationScore = (shortCount >= 16) ? 18 : (shortCount >= 10 ? 10 : 0);

      // Basic doxx / personal info attempt (inbound).
      final doxxScore = (_containsPersonalInfo(allText)) ? 14 : 0;

      // Compute score.
      int score = 0;
      score += coercionHits * 18;
      score += boundaryHits * 14;
      score += loveHits * 10;
      score += escalationScore;
      score += doxxScore;
      score = score.clamp(0, 100);

      final tags = <AuraShieldTag>[];
      if (coercionHits > 0) tags.add(AuraShieldTag.coercion);
      if (boundaryHits > 0) tags.add(AuraShieldTag.boundaryPressure);
      if (loveHits > 0 && shortCount >= 10) tags.add(AuraShieldTag.loveBombing);
      if (doxxScore > 0) tags.add(AuraShieldTag.personalInfo);
      if (escalationScore > 0) tags.add(AuraShieldTag.escalation);

      final level = score >= 65
          ? AuraShieldLevel.high
          : (score >= 32 ? AuraShieldLevel.medium : AuraShieldLevel.low);

      return AuraShieldAssessment(level: level, score: score, tags: tags);
    } catch (e) {
      debugPrint('AuraShieldService.assessThread failed: $e');
      return const AuraShieldAssessment(level: AuraShieldLevel.low, score: 0, tags: []);
    }
  }

  /// Whether a user should be down-ranked / suppressed in discovery.
  ///
  /// Local-first heuristic based on the current device’s observed signals.
  Future<bool> shouldSuppressUser(String userId) async {
    try {
      final signals = await _getSignals();
      final now = DateTime.now();
      final relevant = signals.where((e) => e.targetUserId == userId && now.difference(e.createdAt) <= _windowLong).toList(growable: false);
      if (relevant.isEmpty) return false;

      final weight = relevant.fold<int>(0, (a, e) => a + e.type.weight);
      return weight >= 70;
    } catch (e) {
      debugPrint('AuraShieldService.shouldSuppressUser failed: $e');
      return false;
    }
  }

  /// Used by matchmaking: if risk is high, reduce eligibility rather than hard-ban.
  Future<TruMatchSafetyDecision> matchEligibility({required String viewerUserId, required String targetUserId}) async {
    try {
      final signals = await _getSignals();
      final now = DateTime.now();
      final relevant = signals.where((e) => e.targetUserId == targetUserId && now.difference(e.createdAt) <= _windowLong).toList(growable: false);
      final weight = relevant.fold<int>(0, (a, e) => a + e.type.weight);
      if (weight >= 110) return const TruMatchSafetyDecision(restricted: true, reason: 'Safety signals suggest slower pacing for now.');
      if (weight >= 70) return const TruMatchSafetyDecision(restricted: true, reason: 'This connection is temporarily limited by safety filters.');
      return const TruMatchSafetyDecision(restricted: false, reason: null);
    } catch (e) {
      debugPrint('AuraShieldService.matchEligibility failed: $e');
      return const TruMatchSafetyDecision(restricted: false, reason: null);
    }
  }

  Future<void> recordMessageCheck({required String targetUserId, required CommunicationCheckResult check}) async {
    try {
      final types = <TruAuraShieldSignalType>[];
      if (check.flags.contains(TruMessageFlag.money)) types.add(TruAuraShieldSignalType.moneyLanguage);
      if (check.flags.contains(TruMessageFlag.sexual)) types.add(TruAuraShieldSignalType.sexualPressure);
      if (check.flags.contains(TruMessageFlag.possibleDoxxing)) types.add(TruAuraShieldSignalType.personalInfo);
      if (check.flags.contains(TruMessageFlag.crisis)) types.add(TruAuraShieldSignalType.crisisLanguage);
      if (types.isEmpty) return;
      for (final t in types) {
        await recordUserSignal(TruAuraShieldUserSignal(targetUserId: targetUserId, type: t, createdAt: DateTime.now()));
      }
    } catch (e) {
      debugPrint('AuraShieldService.recordMessageCheck failed: $e');
    }
  }

  Future<List<TruAuraShieldUserSignal>> _getSignals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userSignalsKey);
    final decoded = raw == null ? null : jsonDecode(raw);
    if (decoded is! List) return const <TruAuraShieldUserSignal>[];
    return decoded.whereType<Map>().map((e) => TruAuraShieldUserSignal.fromJson(e.cast<String, dynamic>())).toList(growable: false);
  }

  bool _containsPersonalInfo(String text) {
    // Keep conservative; avoid false positives for random number sequences.
    final email = RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b');
    final phone = RegExp(r'(?:\+?\d{1,3}[\s.-]?)?(?:\(\d{2,4}\)[\s.-]?)?\d{3,4}[\s.-]?\d{3,4}');
    final address = RegExp(r'\b(\d{1,5}\s+[A-Za-z0-9 .-]{3,}\s+(street|st|avenue|ave|road|rd|blvd|boulevard|lane|ln|drive|dr))\b', caseSensitive: false);
    return email.hasMatch(text) || address.hasMatch(text) || phone.hasMatch(text);
  }
}

enum AuraShieldLevel { low, medium, high }

enum AuraShieldTag {
  coercion,
  boundaryPressure,
  loveBombing,
  escalation,
  personalInfo,
}

@immutable
class AuraShieldAssessment {
  final AuraShieldLevel level;
  final int score; // 0..100
  final List<AuraShieldTag> tags;

  const AuraShieldAssessment({required this.level, required this.score, required this.tags});

  String get shortLabel {
    switch (level) {
      case AuraShieldLevel.low:
        return 'Stable';
      case AuraShieldLevel.medium:
        return 'Caution';
      case AuraShieldLevel.high:
        return 'Elevated';
    }
  }
}

enum TruAuraShieldSignalType {
  moneyLanguage,
  sexualPressure,
  personalInfo,
  crisisLanguage,
  reported,
  blocked,
}

extension TruAuraShieldSignalTypeX on TruAuraShieldSignalType {
  int get weight {
    switch (this) {
      case TruAuraShieldSignalType.moneyLanguage:
        return 22;
      case TruAuraShieldSignalType.sexualPressure:
        return 18;
      case TruAuraShieldSignalType.personalInfo:
        return 26;
      case TruAuraShieldSignalType.crisisLanguage:
        return 12;
      case TruAuraShieldSignalType.reported:
        return 48;
      case TruAuraShieldSignalType.blocked:
        return 54;
    }
  }
}

@immutable
class TruAuraShieldUserSignal {
  final String targetUserId;
  final TruAuraShieldSignalType type;
  final DateTime createdAt;

  const TruAuraShieldUserSignal({required this.targetUserId, required this.type, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'targetUserId': targetUserId,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TruAuraShieldUserSignal.fromJson(Map<String, dynamic> json) => TruAuraShieldUserSignal(
        targetUserId: (json['targetUserId'] as String?) ?? '',
        type: TruAuraShieldSignalType.values.firstWhere((e) => e.name == (json['type'] as String?), orElse: () => TruAuraShieldSignalType.moneyLanguage),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class TruMatchSafetyDecision {
  final bool restricted;
  final String? reason;

  const TruMatchSafetyDecision({required this.restricted, required this.reason});
}
