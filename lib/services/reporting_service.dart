import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section 9: Reporting + dispute resolution (local-first).
///
/// Stores user-submitted reports in a local queue. In a production build, these
/// would be forwarded to a server function for human review.
class ReportingService {
  static const String _keyReports = 'safety_reports_v1';
  static const String _keyBlocks = 'safety_blocks_v1';

  Future<List<TruSafetyReport>> getReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyReports);
      if (raw == null) return <TruSafetyReport>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <TruSafetyReport>[];
      return decoded.whereType<Map>().map((e) => TruSafetyReport.fromJson(e.cast<String, dynamic>())).toList();
    } catch (e) {
      debugPrint('ReportingService.getReports failed: $e');
      return <TruSafetyReport>[];
    }
  }

  Future<void> submitReport(TruSafetyReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getReports();
      existing.add(report);
      await prefs.setString(_keyReports, jsonEncode(existing.map((r) => r.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('ReportingService.submitReport failed: $e');
    }
  }

  Future<Set<String>> getBlockedUserIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyBlocks);
      if (raw == null) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (e) {
      debugPrint('ReportingService.getBlockedUserIds failed: $e');
      return <String>{};
    }
  }

  Future<bool> isBlocked(String userId) async => (await getBlockedUserIds()).contains(userId);

  Future<void> blockUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = await getBlockedUserIds();
      set.add(userId);
      await prefs.setString(_keyBlocks, jsonEncode(set.toList(growable: false)));
    } catch (e) {
      debugPrint('ReportingService.blockUser failed: $e');
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = await getBlockedUserIds();
      set.remove(userId);
      await prefs.setString(_keyBlocks, jsonEncode(set.toList(growable: false)));
    } catch (e) {
      debugPrint('ReportingService.unblockUser failed: $e');
    }
  }
}

enum TruSafetyTargetType { user, post, message, chat }

extension TruSafetyTargetTypeX on TruSafetyTargetType {
  static TruSafetyTargetType tryParse(String? raw) {
    for (final v in TruSafetyTargetType.values) {
      if (v.name == raw) return v;
    }
    return TruSafetyTargetType.user;
  }
}

enum TruReportReason {
  harassment,
  hate,
  sexualContent,
  scamOrFraud,
  selfHarm,
  impersonation,
  underage,
  other,
}

extension TruReportReasonX on TruReportReason {
  static TruReportReason tryParse(String? raw) {
    for (final v in TruReportReason.values) {
      if (v.name == raw) return v;
    }
    return TruReportReason.other;
  }

  String get label {
    switch (this) {
      case TruReportReason.harassment:
        return 'Harassment / bullying';
      case TruReportReason.hate:
        return 'Hate or discrimination';
      case TruReportReason.sexualContent:
        return 'Sexual content / coercion';
      case TruReportReason.scamOrFraud:
        return 'Scam / fraud';
      case TruReportReason.selfHarm:
        return 'Self-harm concern';
      case TruReportReason.impersonation:
        return 'Impersonation';
      case TruReportReason.underage:
        return 'Underage user';
      case TruReportReason.other:
        return 'Other';
    }
  }
}

enum TruModerationStatus { queued, reviewing, actionTaken, dismissed }

extension TruModerationStatusX on TruModerationStatus {
  static TruModerationStatus tryParse(String? raw) {
    for (final v in TruModerationStatus.values) {
      if (v.name == raw) return v;
    }
    return TruModerationStatus.queued;
  }
}

@immutable
class TruSafetyReport {
  final String id;
  final TruSafetyTargetType targetType;
  final String targetId;
  final TruReportReason reason;
  final String? details;
  final DateTime createdAt;
  final TruModerationStatus status;

  const TruSafetyReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.details,
    this.status = TruModerationStatus.queued,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType.name,
        'targetId': targetId,
        'reason': reason.name,
        'details': details,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory TruSafetyReport.fromJson(Map<String, dynamic> json) => TruSafetyReport(
        id: (json['id'] ?? '').toString(),
        targetType: TruSafetyTargetTypeX.tryParse(json['targetType'] as String?),
        targetId: (json['targetId'] ?? '').toString(),
        reason: TruReportReasonX.tryParse(json['reason'] as String?),
        details: json['details'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
        status: TruModerationStatusX.tryParse(json['status'] as String?),
      );

  TruSafetyReport copyWith({TruModerationStatus? status}) => TruSafetyReport(
        id: id,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        details: details,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
