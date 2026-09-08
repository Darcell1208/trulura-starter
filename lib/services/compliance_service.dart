import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// Local-first compliance + consent store, scoped to the signed-in account.
///
/// This is intentionally **not** legal advice. It is a product-layer mechanism
/// for gating higher-risk participation surfaces behind explicit user consent.
///
/// When you later add server enforcement, keep this file as the single place
/// to sync (read/write) consent state.
///
/// ## Why the key is per-account
///
/// Consent used to live under one device-global key, `compliance_prefs_v1`.
/// SharedPreferences is per-installation, not per-account, so a second person
/// signing in on the same device inherited the first person's acceptance and
/// was never prompted -- their `termsAcceptedAt` was already set, and adult
/// intent and creator surfaces opened without them ever having agreed to
/// anything. That is the worst instance of a pattern found across seven
/// services in this app: account state stored where device state belongs.
///
/// ## Why the old value is discarded rather than migrated
///
/// The obvious repair -- copy the existing record onto the account that
/// happens to be signed in when the app next launches -- is a guess about who
/// accepted. The local data carries no attribution and never did. A guessed
/// consent record is worse than no record at all, because once written it is
/// indistinguishable from a real one and no later reader can tell it was
/// invented.
///
/// So the old value is orphaned, not migrated: moved to [_supersededKey],
/// which nothing reads, and every account starts from
/// `const TruCompliancePrefs()`. The cost is one re-prompt through a flow that
/// already exists. The cost of the alternative is somebody reaching a gated
/// surface having never consented to it. That asymmetry decides it.
///
/// Contrast BlockService, where the local data was migrated: blocks are
/// decisions that exist nowhere else and cannot be re-made from memory.
/// Consent can be re-given in seconds, and must be re-given by the right
/// person.
class ComplianceService {
  /// The device-global key this service used to read and write. Dead: it is
  /// moved aside on first access and never read again.
  static const _legacyGlobalKey = 'compliance_prefs_v1';

  /// Where the orphaned global value is parked. Nothing reads this; it exists
  /// so the old record survives for inspection rather than being destroyed.
  static const _supersededKey = 'compliance_prefs_v1_superseded';

  static String _keyFor(String uid) => 'compliance_prefs_v1_$uid';

  String? get _uid {
    try {
      if (!DatabaseService.instance.isInitialized) return null;
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Consent for the signed-in account.
  ///
  /// Returns defaults when signed out, which means every gate shows. That is
  /// the safe direction to fail: an unnecessary prompt costs a tap, a skipped
  /// one opens a surface nobody agreed to.
  Future<TruCompliancePrefs> getPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _orphanLegacyGlobalKey(prefs);

      final uid = _uid;
      if (uid == null) return const TruCompliancePrefs();

      final raw = prefs.getString(_keyFor(uid));
      if (raw == null) return const TruCompliancePrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruCompliancePrefs.fromJson(json);
    } catch (e) {
      debugPrint('ComplianceService.getPrefs failed: $e');
      return const TruCompliancePrefs();
    }
  }

  /// Records consent for the signed-in account. Returns false if it did not
  /// persist -- including when nobody is signed in, since there is no account
  /// to attribute the consent to.
  ///
  /// The bool is new. Callers currently discard it, which is the pre-existing
  /// swallowed-write-failure pattern flagged for its own pass; returning it at
  /// least stops this method from being one of the sources.
  Future<bool> setPrefs(TruCompliancePrefs next) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('ComplianceService.setPrefs skipped: no signed-in account');
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await _orphanLegacyGlobalKey(prefs);
      await prefs.setString(_keyFor(uid), jsonEncode(next.toJson()));
      return true;
    } catch (e) {
      debugPrint('ComplianceService.setPrefs failed: $e');
      return false;
    }
  }

  /// Moves the dead device-global record out of the way, once.
  ///
  /// Idempotent and cheap: after the first run the legacy key is gone and
  /// every later call is a single absent-key check. Deliberately not a
  /// migration -- nothing is read out of the orphaned value, by design.
  Future<void> _orphanLegacyGlobalKey(SharedPreferences prefs) async {
    try {
      final legacy = prefs.getString(_legacyGlobalKey);
      if (legacy == null) return;
      // Keep the first orphan if one somehow already exists rather than
      // overwriting it; then remove the legacy key either way so no code path
      // can pick it up.
      if (prefs.getString(_supersededKey) == null) {
        await prefs.setString(_supersededKey, legacy);
      }
      await prefs.remove(_legacyGlobalKey);
      debugPrint('ComplianceService: orphaned device-global consent record');
    } catch (e) {
      debugPrint('ComplianceService._orphanLegacyGlobalKey failed: $e');
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

  /// Returns false if the acceptance did not persist. Already-accepted is
  /// true: the user's intent holds either way.
  Future<bool> acceptTerms() async {
    final prefs = await getPrefs();
    if (prefs.termsAcceptedAt != null) return true;
    return setPrefs(prefs.copyWith(termsAcceptedAt: DateTime.now()));
  }

  /// Returns false if the consent did not persist.
  Future<bool> acceptModeConsent(TruExperienceMode mode) async {
    final prefs = await getPrefs();
    if (prefs.modeConsentAt[mode] != null) return true;
    final next = Map<TruExperienceMode, DateTime>.from(prefs.modeConsentAt);
    next[mode] = DateTime.now();
    return setPrefs(prefs.copyWith(modeConsentAt: next));
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
