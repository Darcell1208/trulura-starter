import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/experience/experience_mode.dart';

/// Local-first compliance + consent store.
///
/// This is intentionally **not** legal advice. It is a product-layer mechanism
/// for gating higher-risk participation surfaces behind explicit user consent.
///
/// When you later add server enforcement, keep this file as the single place
/// to sync (read/write) consent state.
class ComplianceService {
  static const _prefsKey = 'compliance_prefs_v1';

  Future<TruCompliancePrefs> getPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return const TruCompliancePrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruCompliancePrefs.fromJson(json);
    } catch (e) {
      debugPrint('ComplianceService.getPrefs failed: $e');
      return const TruCompliancePrefs();
    }
  }

  Future<void> setPrefs(TruCompliancePrefs next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('ComplianceService.setPrefs failed: $e');
    }
  }

  /// Returns a requirement if the mode needs explicit consent (terms + context).
  Future<TruComplianceRequirement?> requirementForMode(TruExperienceMode mode) async {
    // Only gate higher-risk contexts.
    if (!(mode.isAdultIntent || mode == TruExperienceMode.creator)) return null;

    final prefs = await getPrefs();
    final termsOk = prefs.termsAcceptedAt != null;
    final modeConsentOk = prefs.modeConsentAt[mode] != null;

    if (termsOk && modeConsentOk) return null;
    return TruComplianceRequirement(
      mode: mode,
      requiresTerms: !termsOk,
      requiresModeConsent: !modeConsentOk,
    );
  }

  Future<void> acceptTerms() async {
    final prefs = await getPrefs();
    if (prefs.termsAcceptedAt != null) return;
    await setPrefs(prefs.copyWith(termsAcceptedAt: DateTime.now()));
  }

  Future<void> acceptModeConsent(TruExperienceMode mode) async {
    final prefs = await getPrefs();
    if (prefs.modeConsentAt[mode] != null) return;
    final next = Map<TruExperienceMode, DateTime>.from(prefs.modeConsentAt);
    next[mode] = DateTime.now();
    await setPrefs(prefs.copyWith(modeConsentAt: next));
  }
}

@immutable
class TruComplianceRequirement {
  final TruExperienceMode mode;
  final bool requiresTerms;
  final bool requiresModeConsent;

  const TruComplianceRequirement({required this.mode, required this.requiresTerms, required this.requiresModeConsent});
}

@immutable
class TruCompliancePrefs {
  final DateTime? termsAcceptedAt;

  /// Per-mode explicit consent timestamps.
  final Map<TruExperienceMode, DateTime> modeConsentAt;

  const TruCompliancePrefs({this.termsAcceptedAt, this.modeConsentAt = const {}});

  Map<String, dynamic> toJson() => {
        'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
        'modeConsentAt': modeConsentAt.map((k, v) => MapEntry(k.name, v.toIso8601String())),
      };

  factory TruCompliancePrefs.fromJson(Map<String, dynamic> json) {
    final modeMap = <TruExperienceMode, DateTime>{};
    final rawModes = json['modeConsentAt'];
    if (rawModes is Map) {
      for (final entry in rawModes.entries) {
        final mode = TruExperienceModeX.tryParse(entry.key.toString());
        final ts = DateTime.tryParse(entry.value.toString());
        if (mode != null && ts != null) modeMap[mode] = ts;
      }
    }
    return TruCompliancePrefs(
      termsAcceptedAt: DateTime.tryParse((json['termsAcceptedAt'] ?? '').toString()),
      modeConsentAt: modeMap,
    );
  }

  TruCompliancePrefs copyWith({DateTime? termsAcceptedAt, Map<TruExperienceMode, DateTime>? modeConsentAt}) => TruCompliancePrefs(
        termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
        modeConsentAt: modeConsentAt ?? this.modeConsentAt,
      );
}
