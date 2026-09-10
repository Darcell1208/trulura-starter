import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/user_service.dart';

/// Local-first identity / trust preference persistence, scoped to the
/// signed-in account.
///
/// This intentionally avoids any assumption about a `public.users.id == auth.uid()` mirror.
/// If/when you introduce `profiles` / `identity_modes` tables, this service is the
/// correct place to add Supabase read/write without touching the UI.
///
/// ## Why the key is per-account
///
/// These preferences used to live under one device-global key, so a second
/// person signing in on the same device inherited the first person's identity
/// mode, vibe label, and -- the reason this key was reclassified as unsafe to
/// migrate -- their `anonymousOverlayEnabled` setting.
///
/// Inherited anonymity is worse than an inherited ordinary preference. A
/// loosened messaging setting means unwanted messages arrive and the person can
/// react; inherited anonymity means they *publish* under a presentation they
/// never chose, and the post is out before they notice. Same shape as an
/// inherited safety setting, faster consequence.
///
/// ## Why the old value is orphaned rather than migrated
///
/// The old record has no attribution, so claiming it for whoever signs in first
/// would hand one person's presentation choices to another. It is moved to
/// [_supersededKey], which nothing reads, and every account starts from
/// `const TruIdentityPrefs()`. Everything in this key is re-selectable in
/// seconds, which is what makes discarding it cheap enough to prefer.
///
/// Note that the mode/label setters below also mirror into the cached current
/// user and still swallow their failures; that is the separate
/// swallowed-write-failure pass, not something this change addresses.
class IdentityService {
  /// The device-global key this service used to read and write. Dead: it is
  /// moved aside on first access and never read again.
  static const String _legacyGlobalKey = 'identity_prefs_v1';

  /// Where the orphaned global value is parked. Nothing reads this.
  static const String _supersededKey = 'identity_prefs_v1_superseded';

  static String _keyFor(String uid) => 'identity_prefs_v1_$uid';

  String? get _uid {
    try {
      if (!DatabaseService.instance.isInitialized) return null;
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Identity preferences for the signed-in account.
  ///
  /// Returns defaults when signed out. `anonymousOverlayEnabled` defaults
  /// false, so failing this way fails toward posting as yourself rather than
  /// toward an anonymity nobody selected.
  Future<TruIdentityPrefs> getPrefs() async {
    final uid = _uid;
    if (uid == null) {
      try {
        await _orphanLegacyGlobalKey(await SharedPreferences.getInstance());
      } catch (_) {}
      return const TruIdentityPrefs();
    }
    return _getPrefsFor(uid);
  }

  Future<TruIdentityPrefs> _getPrefsFor(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _orphanLegacyGlobalKey(prefs);

      final raw = prefs.getString(_keyFor(uid));
      if (raw == null) return const TruIdentityPrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TruIdentityPrefs.fromJson(json);
    } catch (e) {
      debugPrint('IdentityService.getPrefs failed: ${safeError(e)}');
      return const TruIdentityPrefs();
    }
  }

  /// Returns false if the change did not persist, including when nobody is
  /// signed in.
  Future<bool> setPrefs(TruIdentityPrefs next) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('IdentityService.setPrefs skipped: no signed-in account');
      return false;
    }
    return _setPrefsFor(uid, next);
  }

  /// Reads and writes under an account resolved by the caller.
  ///
  /// The setters below resolve it once and pass it through both halves. Reading
  /// A's prefs and resolving again on the way out means a session change
  /// between the two writes A's identity settings into B's key -- including
  /// anonymousOverlayEnabled, where inheriting the wrong value means somebody
  /// publishes under a presentation they never chose.
  Future<bool> _setPrefsFor(String uid, TruIdentityPrefs next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _orphanLegacyGlobalKey(prefs);
      await prefs.setString(_keyFor(uid), jsonEncode(next.toJson()));
      return true;
    } catch (e) {
      debugPrint('IdentityService.setPrefs failed: $e');
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
      debugPrint('IdentityService: orphaned device-global identity prefs');
    } catch (e) {
      debugPrint('IdentityService._orphanLegacyGlobalKey failed: $e');
    }
  }

  Future<void> setActiveMode(TruIdentityMode mode) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await _getPrefsFor(uid);
    final active = prefs.activeModes.contains(mode) ? prefs.activeModes : <TruIdentityMode>[...prefs.activeModes, mode];
    await _setPrefsFor(uid, prefs.copyWith(activeMode: mode, activeModes: active));
    await _applyToCachedUser((u) => u.copyWith(activeIdentityMode: mode, updatedAt: DateTime.now()));
  }

  Future<void> setModeEnabled({required TruIdentityMode mode, required bool enabled}) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await _getPrefsFor(uid);
    final set = prefs.activeModes.toSet();
    if (enabled) {
      set.add(mode);
    } else {
      set.remove(mode);
    }
    final nextList = set.toList(growable: false);
    final nextActive = prefs.activeMode;
    final activeMode = set.contains(nextActive) ? nextActive : (nextList.isNotEmpty ? nextList.first : TruIdentityMode.social);
    await _setPrefsFor(uid, prefs.copyWith(activeModes: nextList, activeMode: activeMode));
    await _applyToCachedUser((u) => u.copyWith(activeIdentityMode: activeMode, updatedAt: DateTime.now()));
  }

  Future<void> setAnonymousOverlay(bool enabled) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await _getPrefsFor(uid);
    await _setPrefsFor(uid, prefs.copyWith(anonymousOverlayEnabled: enabled));
    await _applyToCachedUser((u) => u.copyWith(anonymousOverlayEnabled: enabled, updatedAt: DateTime.now()));
  }

  Future<void> setVibeLabel(TruTemperament label) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await _getPrefsFor(uid);
    await _setPrefsFor(uid, prefs.copyWith(temperament: label));
    await _applyToCachedUser((u) => u.copyWith(temperament: label, updatedAt: DateTime.now()));
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
  final TruTemperament temperament;

  const TruIdentityPrefs({
    this.activeMode = TruIdentityMode.social,
    this.activeModes = const [TruIdentityMode.social, TruIdentityMode.dating, TruIdentityMode.creator],
    this.anonymousOverlayEnabled = false,
    this.temperament = TruTemperament.oldSoul,
  });

  Map<String, dynamic> toJson() => {
        'activeMode': activeMode.name,
        'activeModes': activeModes.map((e) => e.name).toList(growable: false),
        'anonymousOverlayEnabled': anonymousOverlayEnabled,
        'temperament': temperament.name,
      };

  factory TruIdentityPrefs.fromJson(Map<String, dynamic> json) => TruIdentityPrefs(
        activeMode: TruIdentityModeX.tryParse(json['activeMode'] as String?) ?? TruIdentityMode.social,
        activeModes: (json['activeModes'] as List<dynamic>?)
                ?.map((e) => TruIdentityModeX.tryParse(e as String?))
                .whereType<TruIdentityMode>()
                .toList(growable: false) ??
            const [TruIdentityMode.social, TruIdentityMode.dating, TruIdentityMode.creator],
        anonymousOverlayEnabled: (json['anonymousOverlayEnabled'] as bool?) ?? false,
        temperament: TruTemperamentX.tryParse(json['temperament'] as String?) ?? TruTemperament.oldSoul,
      );

  TruIdentityPrefs copyWith({TruIdentityMode? activeMode, List<TruIdentityMode>? activeModes, bool? anonymousOverlayEnabled, TruTemperament? temperament}) => TruIdentityPrefs(
        activeMode: activeMode ?? this.activeMode,
        activeModes: activeModes ?? this.activeModes,
        anonymousOverlayEnabled: anonymousOverlayEnabled ?? this.anonymousOverlayEnabled,
        temperament: temperament ?? this.temperament,
      );
}
