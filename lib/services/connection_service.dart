import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first social graph actions used by feed quick-actions.
///
/// When you later add Supabase tables (follows, sparks, blocks), this service is
/// the single place to switch implementations.
class ConnectionService {
  static const _keyFollows = 'graph_follows_v1';
  static const _keySparks = 'graph_sparks_v1';

  Future<Set<String>> _getSet(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (e) {
      debugPrint('ConnectionService._getSet failed: $e');
      return <String>{};
    }
  }

  Future<void> _setSet(String key, Set<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(values.toList(growable: false)));
    } catch (e) {
      debugPrint('ConnectionService._setSet failed: $e');
    }
  }

  Future<bool> isFollowing(String userId) async => (await _getSet(_keyFollows)).contains(userId);
  Future<bool> hasSparked(String userId) async => (await _getSet(_keySparks)).contains(userId);

  Future<void> toggleFollow(String userId) async {
    final set = await _getSet(_keyFollows);
    if (set.contains(userId)) {
      set.remove(userId);
    } else {
      set.add(userId);
    }
    await _setSet(_keyFollows, set);
  }

  Future<void> sendSpark(String userId) async {
    final set = await _getSet(_keySparks);
    set.add(userId);
    await _setSet(_keySparks, set);
  }
}
