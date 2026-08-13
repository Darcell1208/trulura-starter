import 'package:flutter/foundation.dart';
import 'package:trulura/models/message.dart';

/// Lightweight, local-first safety monitoring.
///
/// This is NOT surveillance. It’s an on-device heuristic that flags common
/// coercion / scam patterns and suggests safer next steps.
class SafetyMonitoringService {
  static final List<RegExp> _redFlagPatterns = <RegExp>[
    RegExp(r'\b(send|wire|transfer)\b.*\b(money|cash|crypto|bitcoin)\b', caseSensitive: false),
    RegExp(r'\b(fee|deposit)\b', caseSensitive: false),
    RegExp(r'\b(telegram|whatsapp|snap|kik)\b', caseSensitive: false),
    RegExp(r"\b(secret|don't tell|delete this)\b", caseSensitive: false),
    RegExp(r'\b(nudes?|explicit|onlyfans)\b', caseSensitive: false),
    RegExp(r'\b(come over|your place|my place)\b.*\b(now|tonight)\b', caseSensitive: false),
  ];

  SafetyAssessment assess({required List<Message> messages}) {
    try {
      if (messages.isEmpty) return const SafetyAssessment(level: SafetyRiskLevel.none, reasons: []);

      final text = messages.map((m) => m.content).join('\n');
      final hits = <String>[];
      for (final p in _redFlagPatterns) {
        if (p.hasMatch(text)) hits.add(p.pattern);
      }

      final level = hits.isEmpty
          ? SafetyRiskLevel.none
          : (hits.length >= 2 ? SafetyRiskLevel.elevated : SafetyRiskLevel.caution);

      final reasons = <String>[];
      if (hits.any((e) => e.contains('money') || e.contains('fee') || e.contains('deposit'))) {
        reasons.add('Money / deposit language');
      }
      if (hits.any((e) => e.contains('telegram') || e.contains('whatsapp') || e.contains('snap'))) {
        reasons.add('Pressure to move off-platform');
      }
      if (hits.any((e) => e.contains('secret') || e.contains('delete'))) {
        reasons.add('Secrecy / deletion requests');
      }
      if (hits.any((e) => e.contains('come over'))) {
        reasons.add('Fast escalation to private meetup');
      }

      return SafetyAssessment(level: level, reasons: reasons.take(3).toList(growable: false));
    } catch (e) {
      debugPrint('SafetyMonitoringService.assess failed: $e');
      return const SafetyAssessment(level: SafetyRiskLevel.none, reasons: []);
    }
  }
}

enum SafetyRiskLevel { none, caution, elevated }

@immutable
class SafetyAssessment {
  final SafetyRiskLevel level;
  final List<String> reasons;

  const SafetyAssessment({required this.level, required this.reasons});
}
