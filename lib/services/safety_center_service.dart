import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// Section 9: Safety, Trust, Privacy & Compliance (local-first)
///
/// This service stores *user-controlled* safety preferences, scoped to the
/// signed-in account. It is intentionally local-first, but designed so you can
/// later sync these settings to:
/// - Supabase (profiles/safety_prefs tables)
/// - Firebase (users/{uid}/safety_prefs)
///
/// Without changing the UI layer.
///
/// ## Why the key is per-account
///
/// These settings used to live under one device-global key. SharedPreferences
/// is per-installation, not per-account, so a second person signing in on the
/// same device silently ran the first person's safety posture -- who may DM
/// them, whether AuraShield is on, whether anti-doxxing and crisis prompts
/// fire. None of that is a device property; all of it is a decision a
/// particular person made about their own exposure.
///
/// ## Why the old value is orphaned rather than migrated
///
/// The old record carries no attribution -- nothing on disk says which account
/// chose those settings. Claiming it for whoever signs in first would hand one
/// person's exposure decisions to another, which is the bug rather than the
/// fix. So the value is moved to [_supersededKey], which nothing reads, and
/// every account starts from `const TruSafetyCenterPrefs()`.
///
/// The defaults are the protective end of every field except one:
/// message filtering, AuraShield, anti-doxxing and crisis support all default
/// on, `dmPermission` defaults to followers-only, and ephemeral messaging
/// defaults off. The exception is [TruSafetyCenterPrefs.allowNonMutualSparks],
/// which defaults true -- so the one concrete regression from starting fresh is
/// that somebody who had turned non-mutual sparks off gets them back on. That
/// is visible in the Safety Center screen and reversible in one tap, which is
/// why it does not outweigh the attribution problem.
class SafetyCenterService {
  /// The device-global key this service used to read and write. Dead: it is
  /// moved aside on first access and never read again.
  static const String _legacyGlobalKey = 'safety_center_prefs_v1';

  /// Where the orphaned global value is parked. Nothing reads this.
  static const String _supersededKey = 'safety_center_prefs_v1_superseded';

  static String _keyFor(String uid) => 'safety_center_prefs_v1_$uid';

  String? get _uid {
    try {
      if (!DatabaseService.instance.isInitialized) return null;
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Safety preferences for the signed-in account.
  ///
  /// Returns defaults when signed out. Every protection defaults on, so
  /// failing this way fails safe.
  Future<TruSafetyCenterPrefs> getPrefs() async {
    final uid = _uid;
    if (uid == null) {
      try {
        await _orphanLegacyGlobalKey(await SharedPreferences.getInstance());
      } catch (_) {}
      return const TruSafetyCenterPrefs();
    }
    return _getPrefsFor(uid);
  }

  Future<TruSafetyCenterPrefs> _getPrefsFor(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _orphanLegacyGlobalKey(prefs);

      final raw = prefs.getString(_keyFor(uid));
      if (raw == null) return const TruSafetyCenterPrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruSafetyCenterPrefs.fromJson(json);
    } catch (e) {
      debugPrint('SafetyCenterService.getPrefs failed: $e');
      return const TruSafetyCenterPrefs();
    }
  }

  /// Returns false if the change did not persist, including when nobody is
  /// signed in. Callers still discard this -- see the swallowed-write-failure
  /// pass -- but a setting that silently failed to save is worth knowing about
  /// on a safety screen especially.
  Future<bool> setPrefs(TruSafetyCenterPrefs next) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('SafetyCenterService.setPrefs skipped: no signed-in account');
      return false;
    }
    return _setPrefsFor(uid, next);
  }

  Future<bool> _setPrefsFor(String uid, TruSafetyCenterPrefs next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _orphanLegacyGlobalKey(prefs);
      await prefs.setString(_keyFor(uid), jsonEncode(next.toJson()));
      return true;
    } catch (e) {
      debugPrint('SafetyCenterService.setPrefs failed: $e');
      return false;
    }
  }

  /// Moves the dead device-global record out of the way, once. Idempotent.
  Future<void> _orphanLegacyGlobalKey(SharedPreferences prefs) async {
    try {
      final legacy = prefs.getString(_legacyGlobalKey);
      if (legacy == null) return;
      if (prefs.getString(_supersededKey) == null) {
        await prefs.setString(_supersededKey, legacy);
      }
      await prefs.remove(_legacyGlobalKey);
      debugPrint('SafetyCenterService: orphaned device-global safety prefs');
    } catch (e) {
      debugPrint('SafetyCenterService._orphanLegacyGlobalKey failed: $e');
    }
  }

  // Each setter below resolves the account ONCE and uses it for both the read
  // and the write. Reading A's prefs and then resolving the account again on
  // the way out means a session change between the two writes A's safety
  // posture into B's key -- the cross-account inheritance c78a37a closed,
  // arriving through a narrower door.
  Future<bool> setMessageFilteringEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(messageFilteringEnabled: enabled));
  }

  Future<bool> setScamPromptsEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(scamPromptsEnabled: enabled));
  }

  Future<bool> setDmPermission(TruDmPermission permission) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(dmPermission: permission));
  }

  Future<bool> setAllowNonMutualSparks(bool allow) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(allowNonMutualSparks: allow));
  }

  Future<bool> setAuraShieldEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(auraShieldEnabled: enabled));
  }

  Future<bool> setAntiDoxxingEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(antiDoxxingEnabled: enabled));
  }

  Future<bool> setCrisisSupportEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(crisisSupportEnabled: enabled));
  }

  Future<bool> setEphemeralMessagingEnabled(bool enabled) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(ephemeralMessagingEnabled: enabled));
  }

  Future<bool> setShowSafetyMeterDetails(bool show) async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await _getPrefsFor(uid);
    return _setPrefsFor(uid, prefs.copyWith(showSafetyMeterDetails: show));
  }
}

enum TruDmPermission {
  everyone,
  followersOnly,
  mutualsOnly,
  verifiedOnly,
}

extension TruDmPermissionX on TruDmPermission {
  static TruDmPermission tryParse(String? raw) {
    if (raw == 'matchesOnly') return TruDmPermission.verifiedOnly;
    for (final v in TruDmPermission.values) {
      if (v.name == raw) return v;
    }
    return TruDmPermission.followersOnly;
  }

  String get label {
    switch (this) {
      case TruDmPermission.everyone:
        return 'Everyone';
      case TruDmPermission.followersOnly:
        return 'Followers only';
      case TruDmPermission.mutualsOnly:
        return 'Mutuals only';
      case TruDmPermission.verifiedOnly:
        return 'Verified only';
    }
  }

  String get helper {
    switch (this) {
      case TruDmPermission.everyone:
        return 'Anyone can message you.';
      case TruDmPermission.followersOnly:
        return 'Only people you follow can message you.';
      case TruDmPermission.mutualsOnly:
        return 'Only people you follow + who follow you can message you.';
      case TruDmPermission.verifiedOnly:
        return 'Only verified people can message you first.';
    }
  }
}

@immutable
class TruSafetyCenterPrefs {
  /// Filters potentially unsafe language locally before sending.
  final bool messageFilteringEnabled;

  /// Shows gentle "safety prompts" in chat when risk patterns are detected.
  final bool scamPromptsEnabled;

  /// Who is allowed to start direct messages with you.
  final TruDmPermission dmPermission;

  /// Whether non-mutual sparks are allowed (social pressure reduction).
  final bool allowNonMutualSparks;

  /// AuraShield (behavioral intelligence) controls.
  final bool auraShieldEnabled;

  /// Anti-doxxing protections in chat (detect/confirm personal info sharing).
  final bool antiDoxxingEnabled;

  /// Crisis support prompts when distress language is detected.
  final bool crisisSupportEnabled;

  /// Ephemeral messaging availability in chat.
  final bool ephemeralMessagingEnabled;

  /// Whether the Safety Meter can show expanded detail (user-controlled).
  final bool showSafetyMeterDetails;

  const TruSafetyCenterPrefs({
    this.messageFilteringEnabled = true,
    this.scamPromptsEnabled = true,
    this.dmPermission = TruDmPermission.followersOnly,
    this.allowNonMutualSparks = true,
    this.auraShieldEnabled = true,
    this.antiDoxxingEnabled = true,
    this.crisisSupportEnabled = true,
    this.ephemeralMessagingEnabled = false,
    this.showSafetyMeterDetails = false,
  });

  Map<String, dynamic> toJson() => {
        'messageFilteringEnabled': messageFilteringEnabled,
        'scamPromptsEnabled': scamPromptsEnabled,
        'dmPermission': dmPermission.name,
        'allowNonMutualSparks': allowNonMutualSparks,
        'auraShieldEnabled': auraShieldEnabled,
        'antiDoxxingEnabled': antiDoxxingEnabled,
        'crisisSupportEnabled': crisisSupportEnabled,
        'ephemeralMessagingEnabled': ephemeralMessagingEnabled,
        'showSafetyMeterDetails': showSafetyMeterDetails,
      };

  factory TruSafetyCenterPrefs.fromJson(Map<String, dynamic> json) => TruSafetyCenterPrefs(
        messageFilteringEnabled: (json['messageFilteringEnabled'] as bool?) ?? true,
        scamPromptsEnabled: (json['scamPromptsEnabled'] as bool?) ?? true,
        dmPermission: TruDmPermissionX.tryParse(json['dmPermission'] as String?),
        allowNonMutualSparks: (json['allowNonMutualSparks'] as bool?) ?? true,
        auraShieldEnabled: (json['auraShieldEnabled'] as bool?) ?? true,
        antiDoxxingEnabled: (json['antiDoxxingEnabled'] as bool?) ?? true,
        crisisSupportEnabled: (json['crisisSupportEnabled'] as bool?) ?? true,
        ephemeralMessagingEnabled: (json['ephemeralMessagingEnabled'] as bool?) ?? false,
        showSafetyMeterDetails: (json['showSafetyMeterDetails'] as bool?) ?? false,
      );

  TruSafetyCenterPrefs copyWith({
    bool? messageFilteringEnabled,
    bool? scamPromptsEnabled,
    TruDmPermission? dmPermission,
    bool? allowNonMutualSparks,
    bool? auraShieldEnabled,
    bool? antiDoxxingEnabled,
    bool? crisisSupportEnabled,
    bool? ephemeralMessagingEnabled,
    bool? showSafetyMeterDetails,
  }) =>
      TruSafetyCenterPrefs(
        messageFilteringEnabled: messageFilteringEnabled ?? this.messageFilteringEnabled,
        scamPromptsEnabled: scamPromptsEnabled ?? this.scamPromptsEnabled,
        dmPermission: dmPermission ?? this.dmPermission,
        allowNonMutualSparks: allowNonMutualSparks ?? this.allowNonMutualSparks,
        auraShieldEnabled: auraShieldEnabled ?? this.auraShieldEnabled,
        antiDoxxingEnabled: antiDoxxingEnabled ?? this.antiDoxxingEnabled,
        crisisSupportEnabled: crisisSupportEnabled ?? this.crisisSupportEnabled,
        ephemeralMessagingEnabled: ephemeralMessagingEnabled ?? this.ephemeralMessagingEnabled,
        showSafetyMeterDetails: showSafetyMeterDetails ?? this.showSafetyMeterDetails,
      );
}
