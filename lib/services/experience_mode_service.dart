import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/experience/experience_mode.dart';

/// Local-first persistence for Experience Modes.
///
/// This is the right place to add Supabase/Firebase persistence later without
/// changing UI or controllers.
class ExperienceModeService {
  static const String _keyBase = 'experience_modes_v1';
  static const String _activeKeyBase = 'experience_active_mode_v1';

  String _key(String? userId) => userId == null ? _keyBase : '${_keyBase}_$userId';
  String _activeKey(String? userId) => userId == null ? _activeKeyBase : '${_activeKeyBase}_$userId';

  Future<Map<TruExperienceMode, ExperienceModeState>> getModes({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null) return _defaults();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return _defaults();

      final map = <TruExperienceMode, ExperienceModeState>{};
      for (final e in decoded) {
        if (e is! Map) continue;
        final state = ExperienceModeState.fromJson(e.cast<String, dynamic>());
        map[state.mode] = state;
      }

      // Ensure every mode exists.
      final now = DateTime.now();
      for (final m in TruExperienceMode.values) {
        map.putIfAbsent(m, () => ExperienceModeState(mode: m, isEnabled: m == TruExperienceMode.social, visibility: TruVisibilityLevel.public, createdAt: now, updatedAt: now));
      }
      return map;
    } catch (e) {
      debugPrint('ExperienceModeService.getModes failed: $e');
      return _defaults();
    }
  }

  Future<TruExperienceMode> getActiveMode({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_activeKey(userId));
      final parsed = TruExperienceModeX.tryParse(raw);
      return parsed ?? TruExperienceMode.social;
    } catch (e) {
      debugPrint('ExperienceModeService.getActiveMode failed: $e');
      return TruExperienceMode.social;
    }
  }

  Future<void> setActiveMode(TruExperienceMode mode, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeKey(userId), mode.name);
    } catch (e) {
      debugPrint('ExperienceModeService.setActiveMode failed: $e');
    }
  }

  Future<void> setModes(Map<TruExperienceMode, ExperienceModeState> modes, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = modes.values.map((s) => s.toJson()).toList();
      await prefs.setString(_key(userId), jsonEncode(list));
    } catch (e) {
      debugPrint('ExperienceModeService.setModes failed: $e');
    }
  }

  Map<TruExperienceMode, ExperienceModeState> _defaults() {
    final now = DateTime.now();
    return {
      for (final m in TruExperienceMode.values)
        m: ExperienceModeState(mode: m, isEnabled: m == TruExperienceMode.social, visibility: TruVisibilityLevel.public, createdAt: now, updatedAt: now)
    };
  }
}
