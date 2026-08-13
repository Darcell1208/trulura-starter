import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/user_service.dart';

/// Local-first identity / trust preference persistence.
///
/// This intentionally avoids any assumption about a `public.users.id == auth.uid()` mirror.
/// If/when you introduce `profiles` / `identity_modes` tables, this service is the
/// correct place to add Supabase read/write without touching the UI.
class IdentityService {
  static const String _identityPrefsKey = 'identity_prefs_v1';

  Future<TruIdentityPrefs> getPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_identityPrefsKey);
      if (raw == null) return const TruIdentityPrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruIdentityPrefs.fromJson(json);
    } catch (e) {
      debugPrint('IdentityService.getPrefs failed: $e');
      return const TruIdentityPrefs();
    }
  }

  Future<void> setPrefs(TruIdentityPrefs next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_identityPrefsKey, jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('IdentityService.setPrefs failed: $e');
    }
  }

  Future<void> setActiveMode(TruIdentityMode mode) async {
    final prefs = await getPrefs();
    final active = prefs.activeModes.contains(mode) ? prefs.activeModes : <TruIdentityMode>[...prefs.activeModes, mode];
    await setPrefs(prefs.copyWith(activeMode: mode, activeModes: active));
    await _applyToCachedUser((u) => u.copyWith(activeIdentityMode: mode, updatedAt: DateTime.now()));
  }

  Future<void> setModeEnabled({required TruIdentityMode mode, required bool enabled}) async {
    final prefs = await getPrefs();
    final set = prefs.activeModes.toSet();
    if (enabled) {
      set.add(mode);
    } else {
      set.remove(mode);
    }
    final nextList = set.toList(growable: false);
    final nextActive = prefs.activeMode;
    final activeMode = set.contains(nextActive) ? nextActive : (nextList.isNotEmpty ? nextList.first : TruIdentityMode.social);
    await setPrefs(prefs.copyWith(activeModes: nextList, activeMode: activeMode));
    await _applyToCachedUser((u) => u.copyWith(activeIdentityMode: activeMode, updatedAt: DateTime.now()));
  }

  Future<void> setAnonymousOverlay(bool enabled) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(anonymousOverlayEnabled: enabled));
    await _applyToCachedUser((u) => u.copyWith(anonymousOverlayEnabled: enabled, updatedAt: DateTime.now()));
  }

  Future<void> setVibeLabel(TruVibeLabel label) async {
    final prefs = await getPrefs();
    await setPrefs(prefs.copyWith(vibeLabel: label));
    await _applyToCachedUser((u) => u.copyWith(vibeLabel: label, updatedAt: DateTime.now()));
  }

  Future<void> setTrustVisibility({bool? showVerification, bool? showTrust}) async {
    await _applyToCachedUser(
      (u) => u.copyWith(
        showVerificationBadge: showVerification ?? u.showVerificationBadge,
        showTrustIndicator: showTrust ?? u.showTrustIndicator,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setPrivacy({bool? allowScreenshots, bool? messageAutoDelete, TruProfileVisibility? profileVisibility}) async {
    await _applyToCachedUser(
      (u) => u.copyWith(
        allowScreenshots: allowScreenshots ?? u.allowScreenshots,
        messageAutoDelete: messageAutoDelete ?? u.messageAutoDelete,
        profileVisibility: profileVisibility ?? u.profileVisibility,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _applyToCachedUser(User Function(User) mapper) async {
    try {
      final me = await UserService().getCurrentUser();
      if (me == null) return;
      await UserService().saveUser(mapper(me));
    } catch (e) {
      debugPrint('IdentityService._applyToCachedUser failed: $e');
    }
  }
}

class TruIdentityPrefs {
  final TruIdentityMode activeMode;
  final List<TruIdentityMode> activeModes;
  final bool anonymousOverlayEnabled;
  final TruVibeLabel vibeLabel;

  const TruIdentityPrefs({
    this.activeMode = TruIdentityMode.social,
    this.activeModes = const [TruIdentityMode.social, TruIdentityMode.dating, TruIdentityMode.creator],
    this.anonymousOverlayEnabled = false,
    this.vibeLabel = TruVibeLabel.oldSoul,
  });

  Map<String, dynamic> toJson() => {
        'activeMode': activeMode.name,
        'activeModes': activeModes.map((e) => e.name).toList(growable: false),
        'anonymousOverlayEnabled': anonymousOverlayEnabled,
        'vibeLabel': vibeLabel.name,
      };

  factory TruIdentityPrefs.fromJson(Map<String, dynamic> json) => TruIdentityPrefs(
        activeMode: TruIdentityModeX.tryParse(json['activeMode'] as String?) ?? TruIdentityMode.social,
        activeModes: (json['activeModes'] as List<dynamic>?)
                ?.map((e) => TruIdentityModeX.tryParse(e as String?))
                .whereType<TruIdentityMode>()
                .toList(growable: false) ??
            const [TruIdentityMode.social, TruIdentityMode.dating, TruIdentityMode.creator],
        anonymousOverlayEnabled: (json['anonymousOverlayEnabled'] as bool?) ?? false,
        vibeLabel: TruVibeLabelX.tryParse(json['vibeLabel'] as String?) ?? TruVibeLabel.oldSoul,
      );

  TruIdentityPrefs copyWith({TruIdentityMode? activeMode, List<TruIdentityMode>? activeModes, bool? anonymousOverlayEnabled, TruVibeLabel? vibeLabel}) => TruIdentityPrefs(
        activeMode: activeMode ?? this.activeMode,
        activeModes: activeModes ?? this.activeModes,
        anonymousOverlayEnabled: anonymousOverlayEnabled ?? this.anonymousOverlayEnabled,
        vibeLabel: vibeLabel ?? this.vibeLabel,
      );
}
