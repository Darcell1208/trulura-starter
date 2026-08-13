import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section 9: Safety, Trust, Privacy & Compliance (local-first)
///
/// This service stores *user-controlled* safety preferences. It is intentionally
/// local-first, but designed so you can later sync these settings to:
/// - Supabase (profiles/safety_prefs tables)
/// - Firebase (users/{uid}/safety_prefs)
///
/// Without changing the UI layer.
class SafetyCenterService {
  static const String _prefsKey = 'safety_center_prefs_v1';

  Future<TruSafetyCenterPrefs> getPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return const TruSafetyCenterPrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruSafetyCenterPrefs.fromJson(json);
    } catch (e) {
      debugPrint('SafetyCenterService.getPrefs failed: $e');
      return const TruSafetyCenterPrefs();
    }
  }

  Future<void> setPrefs(TruSafetyCenterPrefs next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('SafetyCenterService.setPrefs failed: $e');
    }
  }

  Future<void> setMessageFilteringEnabled(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(messageFilteringEnabled: enabled));
  }

  Future<void> setScamPromptsEnabled(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(scamPromptsEnabled: enabled));
  }

  Future<void> setDmPermission(TruDmPermission permission) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(dmPermission: permission));
  }

  Future<void> setAllowNonMutualSparks(bool allow) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(allowNonMutualSparks: allow));
  }

  Future<void> setAuraShieldEnabled(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(auraShieldEnabled: enabled));
  }

  Future<void> setAntiDoxxingEnabled(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(antiDoxxingEnabled: enabled));
  }

  Future<void> setCrisisSupportEnabled(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(crisisSupportEnabled: enabled));
  }

  Future<void> setEphemeralMessagingEnabled(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(ephemeralMessagingEnabled: enabled));
  }

  Future<void> setShowSafetyMeterDetails(bool show) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(showSafetyMeterDetails: show));
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
