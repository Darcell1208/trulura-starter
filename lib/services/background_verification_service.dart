import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 9.17 Optional background verification scaffolding.
///
/// This is a local-first placeholder for third-party integrations.
/// Real integrations should be executed server-side (edge function / cloud function)
/// with strict consent + audit trails.
class BackgroundVerificationService {
  static const _keyBase = 'background_verification_v1';

  String _k(String userId) => '${_keyBase}_$userId';

  Future<TruBackgroundVerification> get(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId));
      if (raw == null) return const TruBackgroundVerification();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const TruBackgroundVerification();
      return TruBackgroundVerification.fromJson(decoded.cast<String, dynamic>());
    } catch (e) {
      debugPrint('BackgroundVerificationService.get failed: $e');
      return const TruBackgroundVerification();
    }
  }

  Future<void> set(String userId, TruBackgroundVerification next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k(userId), jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('BackgroundVerificationService.set failed: $e');
    }
  }
}

enum TruBackgroundCheckStatus { none, requested, verified }

enum TruBackgroundShareScope { private, matchmakingOnly, mutualsOnly }

extension TruBackgroundShareScopeX on TruBackgroundShareScope {
  String get label {
    switch (this) {
      case TruBackgroundShareScope.private:
        return 'Private';
      case TruBackgroundShareScope.matchmakingOnly:
        return 'Sync only';
      case TruBackgroundShareScope.mutualsOnly:
        return 'Mutual connections';
    }
  }
}

@immutable
class TruBackgroundVerification {
  final TruBackgroundCheckStatus status;
  final TruBackgroundShareScope shareScope;
  final DateTime? verifiedAt;

  const TruBackgroundVerification({this.status = TruBackgroundCheckStatus.none, this.shareScope = TruBackgroundShareScope.private, this.verifiedAt});

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'shareScope': shareScope.name,
        'verifiedAt': verifiedAt?.toIso8601String(),
      };

  factory TruBackgroundVerification.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String?;
    final scopeRaw = json['shareScope'] as String?;
    final status = TruBackgroundCheckStatus.values.firstWhere((e) => e.name == statusRaw, orElse: () => TruBackgroundCheckStatus.none);
    final scope = TruBackgroundShareScope.values.firstWhere((e) => e.name == scopeRaw, orElse: () => TruBackgroundShareScope.private);
    return TruBackgroundVerification(
      status: status,
      shareScope: scope,
      verifiedAt: (json['verifiedAt'] as String?) == null ? null : DateTime.tryParse(json['verifiedAt'] as String),
    );
  }

  TruBackgroundVerification copyWith({TruBackgroundCheckStatus? status, TruBackgroundShareScope? shareScope, DateTime? verifiedAt}) =>
      TruBackgroundVerification(status: status ?? this.status, shareScope: shareScope ?? this.shareScope, verifiedAt: verifiedAt ?? this.verifiedAt);
}
