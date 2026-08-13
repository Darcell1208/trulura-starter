import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/identity/identity_profile.dart';
import 'package:trulura/models/user.dart';

/// Stores per-mode profile overrides.
///
/// Local-first by design; when you wire Supabase/Firebase, this service becomes
/// the single translation layer for:
/// - `profiles` base row
/// - `identity_modes` per-mode activation
class IdentityProfileService {
  static const String _profilesKeyBase = 'identity_profiles_v1';

  String _k(String userId) => '${_profilesKeyBase}_$userId';

  Future<List<TruIdentityProfile>> getAll({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(userId));
      final decoded = raw != null ? jsonDecode(raw) : null;
      if (decoded is! List) return _defaults();
      final parsed = decoded.whereType<Map>().map((e) => TruIdentityProfile.fromJson(e.cast<String, dynamic>())).toList();
      if (parsed.isEmpty) return _defaults();
      return _sanitize(parsed);
    } catch (e) {
      debugPrint('IdentityProfileService.getAll failed: $e');
      return _defaults();
    }
  }

  Future<void> saveAll({required String userId, required List<TruIdentityProfile> profiles}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitized = _sanitize(profiles);
      await prefs.setString(_k(userId), jsonEncode(sanitized.map((e) => e.toJson()).toList(growable: false)));
    } catch (e) {
      debugPrint('IdentityProfileService.saveAll failed: $e');
    }
  }

  Future<TruIdentityProfile> getForMode({required String userId, required TruIdentityMode mode}) async {
    final all = await getAll(userId: userId);
    return all.firstWhere((p) => p.mode == mode, orElse: () => TruIdentityProfile(mode: mode));
  }

  Future<void> setModeActive({required String userId, required TruIdentityMode mode, required bool active}) async {
    final all = await getAll(userId: userId);
    final next = all
        .map((p) => p.mode == mode ? p.copyWith(isActive: active) : p)
        .toList(growable: false);
    await saveAll(userId: userId, profiles: next);
  }

  List<TruIdentityProfile> _defaults() => const [
        TruIdentityProfile(mode: TruIdentityMode.social, profileType: TruProfileType.social, isActive: true),
        TruIdentityProfile(mode: TruIdentityMode.dating, profileType: TruProfileType.dating, isActive: true),
        TruIdentityProfile(mode: TruIdentityMode.creator, profileType: TruProfileType.creator, isActive: true),
        TruIdentityProfile(mode: TruIdentityMode.luxe, profileType: TruProfileType.luxe, isActive: false),
        TruIdentityProfile(mode: TruIdentityMode.friendship, profileType: TruProfileType.social, isActive: false),
        TruIdentityProfile(mode: TruIdentityMode.vent, profileType: TruProfileType.social, isActive: true),
      ];

  List<TruIdentityProfile> _sanitize(List<TruIdentityProfile> input) {
    final byMode = <TruIdentityMode, TruIdentityProfile>{};
    for (final p in input) {
      byMode[p.mode] = p;
    }
    final merged = <TruIdentityProfile>[];
    for (final d in _defaults()) {
      merged.add(byMode[d.mode] ?? d);
    }
    return merged;
  }
}
