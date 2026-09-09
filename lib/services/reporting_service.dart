import 'package:flutter/foundation.dart';
import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:trulura/services/database_service/database_service.dart';

/// Section 9.14: user reporting, backed by `public.reports`.
///
/// Was local-first: reports were appended to a `SharedPreferences` key, which
/// meant the UI thanked the user for a report no human could ever read. They
/// now go to Postgres, where `reports_insert_self` requires
/// `reported_by_user_id = auth.uid()` and `reports_select_own` lets a reporter
/// read back only their own. There is no UPDATE or DELETE policy, so a report
/// cannot be edited or withdrawn once filed, and only `service_role` can move
/// one between statuses.
///
/// Blocks used to live here too. They are now [BlockService] --
/// lib/services/block_service.dart -- because they persist to a different
/// table with different rules, and because the two concepts kept borrowing
/// each other's storage.
class ReportingService {
  static const String _table = 'reports';

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool get _ready => DatabaseService.instance.isInitialized;

  String? get _uid {
    try {
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Which column holds the target for each kind of report.
  ///
  /// The table has four typed target columns rather than a polymorphic
  /// target_type/target_id pair, so each of these carries a real foreign key
  /// and a report cannot name a row that does not exist. See
  /// supabase/migrations/20260908_reports_targets_and_status.sql.
  static String _targetColumn(TruSafetyTargetType type) {
    switch (type) {
      case TruSafetyTargetType.user:
        return 'target_user_id';
      case TruSafetyTargetType.post:
        return 'target_post_id';
      case TruSafetyTargetType.message:
        return 'target_message_id';
      case TruSafetyTargetType.chat:
        return 'target_conversation_id';
    }
  }

  static TruSafetyTargetType? _targetTypeOf(Map<String, dynamic> row) {
    if (row['target_user_id'] != null) return TruSafetyTargetType.user;
    if (row['target_post_id'] != null) return TruSafetyTargetType.post;
    if (row['target_message_id'] != null) return TruSafetyTargetType.message;
    if (row['target_conversation_id'] != null) return TruSafetyTargetType.chat;
    return null;
  }

  static String _targetIdOf(Map<String, dynamic> row, TruSafetyTargetType type) =>
      row[_targetColumn(type)]?.toString() ?? '';

  /// Files [report]. Returns false when it did not reach the server.
  ///
  /// The caller must not thank the user on a false return. The old local
  /// implementation could not fail, so the UI showed "Report submitted" for
  /// every attempt; that was harmless when the destination was a local file
  /// and is a lie now that it is a network write.
  ///
  /// [TruSafetyReport.id] and [TruSafetyReport.status] are ignored on the way
  /// in: the row id is `gen_random_uuid()` and the status defaults to
  /// 'queued', both server-side. A client should not get to choose either.
  Future<bool> submitReport(TruSafetyReport report) async {
    final uid = _uid;
    if (!_ready || uid == null) return false;

    final targetId = report.targetId.trim();
    if (!_uuid.hasMatch(targetId)) {
      // Feed demo content carries ids like 'local' and 'profile-vibe-update'
      // (feed_demo_content_service.dart), and the report route is reachable
      // from a feed card, so this is a real path rather than a defensive
      // nicety. The foreign key would reject it anyway; refusing here means
      // the UI can say so instead of showing a Postgres error.
      // Hashed for the same reason as the block path: who you reported is
      // what reports_select_own protects.
      debugPrint('ReportingService.submitReport refused non-uuid target: '
          '${redactedId(targetId)}');
      return false;
    }

    final details = report.details?.trim();

    try {
      await DatabaseService.instance.client.from(_table).insert({
        'reported_by_user_id': uid,
        _targetColumn(report.targetType): targetId,
        'reason': report.reason.name,
        if (details != null && details.isNotEmpty) 'reason_text': details,
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('ReportingService.submitReport failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('ReportingService.submitReport failed: $e');
      return false;
    }
  }

  /// The reports this user has filed, newest first.
  ///
  /// Nothing in the UI renders these today, and in particular nothing renders
  /// [TruSafetyReport.status]. That is deliberate: the status column exists so
  /// a human triaging reports has somewhere to record a decision, and showing
  /// a permanent 'queued' to the reporter would promise a review nobody is yet
  /// performing.
  Future<List<TruSafetyReport>> getReports() async {
    final uid = _uid;
    if (!_ready || uid == null) return <TruSafetyReport>[];

    try {
      final rows = await DatabaseService.instance.client
          .from(_table)
          .select(
              'id, target_user_id, target_post_id, target_message_id, '
              'target_conversation_id, reason, reason_text, status, created_at')
          .eq('reported_by_user_id', uid)
          .order('created_at', ascending: false);

      final out = <TruSafetyReport>[];
      for (final raw in (rows as List)) {
        final row = (raw as Map).cast<String, dynamic>();
        final type = _targetTypeOf(row);
        // reports_exactly_one_target makes a targetless row impossible, but a
        // row read back with no target would be unusable rather than merely
        // odd, so it is skipped instead of coerced to a default.
        if (type == null) continue;
        out.add(TruSafetyReport(
          id: row['id']?.toString() ?? '',
          targetType: type,
          targetId: _targetIdOf(row, type),
          reason: TruReportReasonX.tryParse(row['reason']?.toString()),
          details: row['reason_text']?.toString(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')
                  ?.toLocal() ??
              DateTime.now(),
          status: TruModerationStatusX.tryParse(row['status']?.toString()),
        ));
      }
      return out;
    } catch (e) {
      debugPrint('ReportingService.getReports failed: $e');
      return <TruSafetyReport>[];
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

/// Report categories.
///
/// `.name` is stored verbatim in `reports.reason`, which carries a CHECK
/// listing these eight values. Adding a case here without the matching
/// migration will fail loudly at insert time rather than silently storing
/// something no reader understands.
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

/// Triage states for a filed report.
///
/// `.name` is stored verbatim in `reports.status`, which carries a CHECK
/// listing these four values and defaults to 'queued'. Only `service_role` can
/// change one -- there is no UPDATE policy for authenticated users.
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
  /// Server-assigned on read; ignored on submit.
  final String id;
  final TruSafetyTargetType targetType;
  final String targetId;
  final TruReportReason reason;
  final String? details;
  final DateTime createdAt;

  /// Internal triage state. Never rendered -- see [ReportingService.getReports].
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
