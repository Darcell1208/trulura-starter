import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OpenAI proxy configuration + client.
///
/// Values are resolved at runtime from environment variables.
///
/// IMPORTANT: `endpoint` is used directly (do not append /v1/chat/completions).
class TruOpenAI {
  static const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

  static bool get isConfigured => apiKey.trim().isNotEmpty && endpoint.trim().isNotEmpty;

  Future<List<String>> suggestReplies({required String postText, required String mood, required String mode, required String feedTab, int count = 4}) async {
    if (!isConfigured) {
      throw Exception('OpenAI not configured');
    }

    final uri = Uri.parse(endpoint);
    final system = {
      'role': 'system',
      'content': 'You generate short, emotionally intelligent reply suggestions. Output must be a JSON object.'
    };

    final user = {
      'role': 'user',
      'content': 'Return EXACTLY this JSON format: {"suggestions": ["..."]}.\n\nContext:\n- feed_tab: $feedTab\n- user_mode: $mode\n- mood_state: $mood\n\nPost text:\n"""$postText"""\n\nRules:\n- $count suggestions\n- 6–14 words each\n- supportive, non-toxic, not sexual, not manipulative\n- no emojis\n- no hashtags'
    };

    try {
      final resp = await http.post(
        uri,
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [system, user],
          'temperature': 0.6,
        }),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('OpenAI suggestReplies failed ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}');
        throw Exception('OpenAI request failed');
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final content = (((decoded['choices'] as List?)?.firstOrNull as Map?)?['message'] as Map?)?['content']?.toString();
      if (content == null || content.trim().isEmpty) throw Exception('OpenAI returned empty content');

      final obj = jsonDecode(content) as Map<String, dynamic>;
      final suggestions = (obj['suggestions'] as List?)?.map((e) => e?.toString() ?? '').where((e) => e.trim().isNotEmpty).toList(growable: false) ?? const <String>[];
      if (suggestions.isEmpty) throw Exception('OpenAI returned no suggestions');
      return suggestions.take(count).toList(growable: false);
    } catch (e) {
      debugPrint('OpenAI suggestReplies error: $e');
      rethrow;
    }
  }

  Future<List<String>> suggestMatchConciergeTips({
    required String viewerName,
    required String targetName,
    required String purpose,
    required String stage,
    required List<String> compatibilityReasons,
    required bool lowEnergyMode,
    int count = 5,
  }) async {
    if (!isConfigured) throw Exception('OpenAI not configured');

    final uri = Uri.parse(endpoint);
    final system = {
      'role': 'system',
      'content': 'You are an emotionally intelligent matchmaking concierge. Output must be a JSON object.'
    };

    final user = {
      'role': 'user',
      'content': 'Return EXACTLY this JSON format: {"tips": ["..."]}.'
          '\n\nContext:'
          '\n- viewer: $viewerName'
          '\n- target: $targetName'
          '\n- purpose: $purpose'
          '\n- stage: $stage'
          '\n- low_energy: $lowEnergyMode'
          '\n- compatibility_reasons: ${compatibilityReasons.take(4).join(', ')}'
          '\n\nRules:'
          '\n- $count tips'
          '\n- 9–18 words each'
          '\n- gentle, non-manipulative, non-sexual'
          '\n- include at least 1 boundary/consent tip'
          '\n- include at least 1 concrete next-step suggestion'
          '\n- no emojis'
          '\n- no moralizing'
    };

    try {
      final resp = await http.post(
        uri,
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [system, user],
          'temperature': 0.55,
        }),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('OpenAI suggestMatchConciergeTips failed ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}');
        throw Exception('OpenAI request failed');
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final content = (((decoded['choices'] as List?)?.firstOrNull as Map?)?['message'] as Map?)?['content']?.toString();
      if (content == null || content.trim().isEmpty) throw Exception('OpenAI returned empty content');

      final obj = jsonDecode(content) as Map<String, dynamic>;
      final tips = (obj['tips'] as List?)?.map((e) => e?.toString() ?? '').where((e) => e.trim().isNotEmpty).toList(growable: false) ?? const <String>[];
      if (tips.isEmpty) throw Exception('OpenAI returned no tips');
      return tips.take(count).toList(growable: false);
    } catch (e) {
      debugPrint('OpenAI suggestMatchConciergeTips error: $e');
      rethrow;
    }
  }
}

extension _FirstOrNullX on List {
  Object? get firstOrNull => isEmpty ? null : first;
}
