import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-thread privacy / retention controls (local-first).
class ChatThreadPrefsService {
  static const _keyBase = 'chat_thread_prefs_v1';

  String _k(String chatId) => '${_keyBase}_$chatId';

  Future<TruChatThreadPrefs> getPrefs(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k(chatId));
      if (raw == null) return const TruChatThreadPrefs();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const TruChatThreadPrefs();
      return TruChatThreadPrefs.fromJson(decoded.cast<String, dynamic>());
    } catch (e) {
      debugPrint('ChatThreadPrefsService.getPrefs failed: $e');
      return const TruChatThreadPrefs();
    }
  }

  Future<void> setPrefs(String chatId, TruChatThreadPrefs next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_k(chatId), jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('ChatThreadPrefsService.setPrefs failed: $e');
    }
  }
}

enum TruEphemeralTtl { off, oneHour, oneDay, sevenDays }

extension TruEphemeralTtlX on TruEphemeralTtl {
  String get label {
    switch (this) {
      case TruEphemeralTtl.off:
        return 'Off';
      case TruEphemeralTtl.oneHour:
        return '1 hour';
      case TruEphemeralTtl.oneDay:
        return '24 hours';
      case TruEphemeralTtl.sevenDays:
        return '7 days';
    }
  }

  Duration? get duration {
    switch (this) {
      case TruEphemeralTtl.off:
        return null;
      case TruEphemeralTtl.oneHour:
        return const Duration(hours: 1);
      case TruEphemeralTtl.oneDay:
        return const Duration(days: 1);
      case TruEphemeralTtl.sevenDays:
        return const Duration(days: 7);
    }
  }
}

@immutable
class TruChatThreadPrefs {
  final TruEphemeralTtl ephemeralTtl;

  const TruChatThreadPrefs({this.ephemeralTtl = TruEphemeralTtl.off});

  Map<String, dynamic> toJson() => {'ephemeralTtl': ephemeralTtl.name};

  factory TruChatThreadPrefs.fromJson(Map<String, dynamic> json) {
    final raw = json['ephemeralTtl'] as String?;
    final ttl = TruEphemeralTtl.values.firstWhere((e) => e.name == raw, orElse: () => TruEphemeralTtl.off);
    return TruChatThreadPrefs(ephemeralTtl: ttl);
  }

  TruChatThreadPrefs copyWith({TruEphemeralTtl? ephemeralTtl}) => TruChatThreadPrefs(ephemeralTtl: ephemeralTtl ?? this.ephemeralTtl);
}
