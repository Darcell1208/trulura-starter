import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// Local settings persistence for TruLura.
///
/// With no backend connected, we treat “account-level” as:
/// - Stored per current user id when available
/// - Otherwise stored as a global (pre-auth) preference
class AppSettingsService {
  static const _softModeGateCompletedKey = 'soft_mode_gate_completed';
  static const _softModeEnabledGlobalKey = 'soft_mode_enabled_global';
  static const _creatorModeEnabledGlobalKey = 'creator_mode_enabled_global';
  static const _creatorApprovedGlobalKey = 'creator_approved_global';
  static const _creatorOnboardingCompleteGlobalKey =
      'creator_onboarding_complete_global';
  static const _hasAdvancedVerificationGlobalKey =
      'has_advanced_verification_global';
  static const _hasBackgroundVerificationGlobalKey =
      'has_background_verification_global';
  static const _hasLuxeInviteGlobalKey = 'has_luxe_invite_global';
  static const _hasLuxeSubscriptionGlobalKey =
      'has_luxe_subscription_global';
  static const _showLivesInFeedGlobalKey = 'show_lives_in_feed_global';
  static const _livesInFeedFrequencyGlobalKey = 'lives_in_feed_frequency_global';

  static const _glowScaleGlobalKey = 'glow_scale_global';

  // Feed personalization (Section 4)
  static const _feedContentIntensityGlobalKey = 'feed_content_intensity_global';
  static const _feedCreatorWeightGlobalKey = 'feed_creator_weight_global';
  static const _feedRomanticVisibilityGlobalKey = 'feed_romantic_visibility_global';
  static const _feedEmotionalSensitivityGlobalKey = 'feed_emotional_sensitivity_global';
  static const _feedTabOrderGlobalKey = 'feed_tab_order_global';

  // Section 7: intelligent distribution user controls
  static const _feedDiscoveryBalanceGlobalKey = 'feed_discovery_balance_global';
  static const _feedMutedTopicsGlobalKey = 'feed_muted_topics_global';
  static const _feedMutedMoodsGlobalKey = 'feed_muted_moods_global';

  // Section 7 (expanded): UI + smart switching controls
  static const _smartFeedSwitchingEnabledGlobalKey = 'smart_feed_switching_enabled_global';
  static const _moodAdaptiveUiEnabledGlobalKey = 'mood_adaptive_ui_enabled_global';
  static const _transparencyExplainersEnabledGlobalKey = 'transparency_explainers_enabled_global';
  static const _lowEnergyFeedEnabledGlobalKey = 'low_energy_feed_enabled_global';

  static const _useModeGlobalKey = 'use_mode_global';
  static const _fullSyncModeEnabledGlobalKey = 'full_sync_mode_enabled_global';
  static const _askVibeAtStartupGlobalKey = 'ask_vibe_at_startup_global';
  static const _askIntentAtStartupGlobalKey = 'ask_intent_at_startup_global';
  static const _rememberMoodIntentGlobalKey =
      'remember_mood_intent_global';
  static const _appearanceModeGlobalKey = 'appearance_mode_global';
  // Future extension point:
  // - background theme packs
  // - softer neutral variants
  // - personalized palette presets
  static const _dismissedHomePromptsGlobalKey =
      'dismissed_home_prompts_global';
  static const _dismissedHomePromptsStatusesGlobalKey =
      'dismissed_home_prompts_statuses_global';
  static const _interestQuizCompletedGlobalKey =
      'interest_quiz_completed_global';

  String _userKey(String base, String userId) => '${base}_$userId';

  double _clamp01(double v) => v.clamp(0.0, 1.0);
  bool get _supabaseReady => DatabaseService.instance.isInitialized;
  SupabaseClient get _client => DatabaseService.instance.client;

  Future<Map<String, dynamic>?> _getUserSettingsRow(String userId) async {
    if (!_supabaseReady) return null;
    return await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<void> _upsertUserSettings(
    String userId,
    Map<String, dynamic> values,
  ) async {
    if (!_supabaseReady) return;
    final payload = <String, dynamic>{
      ...values,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final updated = await _client
        .from('user_settings')
        .update(payload)
        .eq('user_id', userId)
        .select('user_id');
    if ((updated as List).isNotEmpty) return;
    await _client.from('user_settings').insert({
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
      ...payload,
    });
  }

  Future<bool> getSmartFeedSwitchingEnabled({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(_userKey('smart_feed_switching_enabled', userId));
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_smartFeedSwitchingEnabledGlobalKey) ?? true;
    } catch (e) {
      debugPrint('Failed to get Smart Feed Switching enabled: $e');
      return true;
    }
  }

  Future<void> setSmartFeedSwitchingEnabled(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setBool(_userKey('smart_feed_switching_enabled', userId), enabled);
      await prefs.setBool(_smartFeedSwitchingEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Smart Feed Switching enabled: $e');
    }
  }

  Future<bool> getMoodAdaptiveUiEnabled({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(_userKey('mood_adaptive_ui_enabled', userId));
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_moodAdaptiveUiEnabledGlobalKey) ?? true;
    } catch (e) {
      debugPrint('Failed to get Mood-adaptive UI enabled: $e');
      return true;
    }
  }

  Future<void> setMoodAdaptiveUiEnabled(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setBool(_userKey('mood_adaptive_ui_enabled', userId), enabled);
      await prefs.setBool(_moodAdaptiveUiEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Mood-adaptive UI enabled: $e');
    }
  }

  Future<bool> getTransparencyExplainersEnabled({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(_userKey('transparency_explainers_enabled', userId));
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_transparencyExplainersEnabledGlobalKey) ?? true;
    } catch (e) {
      debugPrint('Failed to get Transparency explainers enabled: $e');
      return true;
    }
  }

  Future<void> setTransparencyExplainersEnabled(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setBool(_userKey('transparency_explainers_enabled', userId), enabled);
      await prefs.setBool(_transparencyExplainersEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Transparency explainers enabled: $e');
    }
  }

  Future<bool> getLowEnergyFeedEnabled({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(_userKey('low_energy_feed_enabled', userId));
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_lowEnergyFeedEnabledGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Low Energy feed enabled: $e');
      return false;
    }
  }

  Future<void> setLowEnergyFeedEnabled(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setBool(_userKey('low_energy_feed_enabled', userId), enabled);
      await prefs.setBool(_lowEnergyFeedEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Low Energy feed enabled: $e');
    }
  }

  Future<double> getFeedContentIntensity({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getDouble(_userKey('feed_content_intensity', userId));
        if (perUser != null) return _clamp01(perUser);
      }
      return _clamp01(prefs.getDouble(_feedContentIntensityGlobalKey) ?? 0.65);
    } catch (e) {
      debugPrint('Failed to get Feed content intensity: $e');
      return 0.65;
    }
  }

  Future<void> setFeedContentIntensity(double value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = _clamp01(value);
      if (userId != null) await prefs.setDouble(_userKey('feed_content_intensity', userId), v);
      await prefs.setDouble(_feedContentIntensityGlobalKey, v);
    } catch (e) {
      debugPrint('Failed to set Feed content intensity: $e');
    }
  }

  Future<double> getFeedCreatorWeight({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getDouble(_userKey('feed_creator_weight', userId));
        if (perUser != null) return _clamp01(perUser);
      }
      return _clamp01(prefs.getDouble(_feedCreatorWeightGlobalKey) ?? 0.35);
    } catch (e) {
      debugPrint('Failed to get Feed creator weight: $e');
      return 0.35;
    }
  }

  Future<void> setFeedCreatorWeight(double value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = _clamp01(value);
      if (userId != null) await prefs.setDouble(_userKey('feed_creator_weight', userId), v);
      await prefs.setDouble(_feedCreatorWeightGlobalKey, v);
    } catch (e) {
      debugPrint('Failed to set Feed creator weight: $e');
    }
  }

  Future<double> getFeedRomanticVisibility({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getDouble(_userKey('feed_romantic_visibility', userId));
        if (perUser != null) return _clamp01(perUser);
      }
      return _clamp01(prefs.getDouble(_feedRomanticVisibilityGlobalKey) ?? 0.55);
    } catch (e) {
      debugPrint('Failed to get Feed romantic visibility: $e');
      return 0.55;
    }
  }

  Future<void> setFeedRomanticVisibility(double value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = _clamp01(value);
      if (userId != null) await prefs.setDouble(_userKey('feed_romantic_visibility', userId), v);
      await prefs.setDouble(_feedRomanticVisibilityGlobalKey, v);
    } catch (e) {
      debugPrint('Failed to set Feed romantic visibility: $e');
    }
  }

  Future<double> getFeedEmotionalSensitivity({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getDouble(_userKey('feed_emotional_sensitivity', userId));
        if (perUser != null) return _clamp01(perUser);
      }
      return _clamp01(prefs.getDouble(_feedEmotionalSensitivityGlobalKey) ?? 0.55);
    } catch (e) {
      debugPrint('Failed to get Feed emotional sensitivity: $e');
      return 0.55;
    }
  }

  Future<void> setFeedEmotionalSensitivity(double value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = _clamp01(value);
      if (userId != null) await prefs.setDouble(_userKey('feed_emotional_sensitivity', userId), v);
      await prefs.setDouble(_feedEmotionalSensitivityGlobalKey, v);
    } catch (e) {
      debugPrint('Failed to set Feed emotional sensitivity: $e');
    }
  }

  Future<List<String>> getFeedTabOrder({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getStringList(_userKey('feed_tab_order', userId));
        if (perUser != null && perUser.isNotEmpty) return perUser;
      }
      final global = prefs.getStringList(_feedTabOrderGlobalKey);
      if (global != null && global.isNotEmpty) return global;
      return const ['for_you', 'aura', 'spark', 'vent', 'trending'];
    } catch (e) {
      debugPrint('Failed to get Feed tab order: $e');
      return const ['for_you', 'aura', 'spark', 'vent', 'trending'];
    }
  }

  Future<double> getFeedDiscoveryBalance({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getDouble(_userKey('feed_discovery_balance', userId));
        if (perUser != null) return _clamp01(perUser);
      }
      return _clamp01(prefs.getDouble(_feedDiscoveryBalanceGlobalKey) ?? 0.45);
    } catch (e) {
      debugPrint('Failed to get Feed discovery balance: $e');
      return 0.45;
    }
  }

  Future<void> setFeedDiscoveryBalance(double value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = _clamp01(value);
      if (userId != null) await prefs.setDouble(_userKey('feed_discovery_balance', userId), v);
      await prefs.setDouble(_feedDiscoveryBalanceGlobalKey, v);
    } catch (e) {
      debugPrint('Failed to set Feed discovery balance: $e');
    }
  }

  Future<List<String>> getFeedMutedTopics({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getStringList(_userKey('feed_muted_topics', userId));
        if (perUser != null) return perUser;
      }
      return prefs.getStringList(_feedMutedTopicsGlobalKey) ?? const <String>[];
    } catch (e) {
      debugPrint('Failed to get Feed muted topics: $e');
      return const <String>[];
    }
  }

  Future<void> setFeedMutedTopics(List<String> value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitized = value.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
      if (userId != null) await prefs.setStringList(_userKey('feed_muted_topics', userId), sanitized);
      await prefs.setStringList(_feedMutedTopicsGlobalKey, sanitized);
    } catch (e) {
      debugPrint('Failed to set Feed muted topics: $e');
    }
  }

  Future<List<String>> getFeedMutedMoods({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getStringList(_userKey('feed_muted_moods', userId));
        if (perUser != null) return perUser;
      }
      return prefs.getStringList(_feedMutedMoodsGlobalKey) ?? const <String>[];
    } catch (e) {
      debugPrint('Failed to get Feed muted moods: $e');
      return const <String>[];
    }
  }

  Future<void> setFeedMutedMoods(List<String> value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitized = value.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
      if (userId != null) await prefs.setStringList(_userKey('feed_muted_moods', userId), sanitized);
      await prefs.setStringList(_feedMutedMoodsGlobalKey, sanitized);
    } catch (e) {
      debugPrint('Failed to set Feed muted moods: $e');
    }
  }

  Future<void> setFeedTabOrder(List<String> order, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitized = order.where((e) => e.trim().isNotEmpty).toList(growable: false);
      if (userId != null) await prefs.setStringList(_userKey('feed_tab_order', userId), sanitized);
      await prefs.setStringList(_feedTabOrderGlobalKey, sanitized);
    } catch (e) {
      debugPrint('Failed to set Feed tab order: $e');
    }
  }

  Future<double> getGlowScale({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('glow_scale', userId);
        final perUser = prefs.getDouble(key);
        if (perUser != null) return perUser;
      }
      return prefs.getDouble(_glowScaleGlobalKey) ?? 1.0;
    } catch (e) {
      debugPrint('Failed to get Glow Scale: $e');
      return 1.0;
    }
  }

  Future<void> setGlowScale(double value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setDouble(_userKey('glow_scale', userId), value);
      await prefs.setDouble(_glowScaleGlobalKey, value);
    } catch (e) {
      debugPrint('Failed to set Glow Scale: $e');
    }
  }

  Future<String> getUseMode({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('use_mode', userId);
        final perUser = prefs.getString(key);
        if (perUser != null) return perUser;
      }
      return prefs.getString(_useModeGlobalKey) ?? 'both';
    } catch (e) {
      debugPrint('Failed to get Use Mode: $e');
      return 'both';
    }
  }

  Future<void> setUseMode(String value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setString(_userKey('use_mode', userId), value);
      await prefs.setString(_useModeGlobalKey, value);
    } catch (e) {
      debugPrint('Failed to set Use Mode: $e');
    }
  }

  Future<bool> getFullSyncModeEnabled({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('full_sync_mode_enabled', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_fullSyncModeEnabledGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Full Sync Mode enabled: $e');
      return false;
    }
  }

  Future<void> setFullSyncModeEnabled(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setBool(_userKey('full_sync_mode_enabled', userId), enabled);
      await prefs.setBool(_fullSyncModeEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Full Sync Mode enabled: $e');
    }
  }

  Future<bool> getAskVibeAtStartup({String? userId}) async {
    try {
      if (userId != null) {
        final row = await _getUserSettingsRow(userId);
        final remote = row?['ask_vibe_at_startup'];
        if (remote is bool) return remote;
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(
          _userKey('ask_vibe_at_startup', userId),
        );
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_askVibeAtStartupGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Ask Vibe At Startup: $e');
      return false;
    }
  }

  Future<void> setAskVibeAtStartup(bool enabled, {String? userId}) async {
    try {
      if (userId != null) {
        await _upsertUserSettings(userId, {
          'ask_vibe_at_startup': enabled,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('ask_vibe_at_startup', userId),
          enabled,
        );
      }
      await prefs.setBool(_askVibeAtStartupGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Ask Vibe At Startup: $e');
    }
  }

  Future<bool> getAskIntentAtStartup({String? userId}) async {
    try {
      if (userId != null) {
        final row = await _getUserSettingsRow(userId);
        final remote = row?['ask_intent_at_startup'];
        if (remote is bool) return remote;
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(
          _userKey('ask_intent_at_startup', userId),
        );
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_askIntentAtStartupGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Ask Intent At Startup: $e');
      return false;
    }
  }

  Future<void> setAskIntentAtStartup(bool enabled, {String? userId}) async {
    try {
      if (userId != null) {
        await _upsertUserSettings(userId, {
          'ask_intent_at_startup': enabled,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('ask_intent_at_startup', userId),
          enabled,
        );
      }
      await prefs.setBool(_askIntentAtStartupGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Ask Intent At Startup: $e');
    }
  }

  Future<bool> getRememberMoodIntent({String? userId}) async {
    try {
      if (userId != null) {
        final row = await _getUserSettingsRow(userId);
        final remoteIntent = row?['remember_last_intent'];
        final remoteVibe = row?['remember_last_vibe'];
        if (remoteIntent is bool && remoteVibe is bool) {
          return remoteIntent && remoteVibe;
        }
        if (remoteIntent is bool) return remoteIntent;
        if (remoteVibe is bool) return remoteVibe;
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getBool(
          _userKey('remember_mood_intent', userId),
        );
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_rememberMoodIntentGlobalKey) ?? true;
    } catch (e) {
      debugPrint('Failed to get Remember Mood/Intent: $e');
      return true;
    }
  }

  Future<void> setRememberMoodIntent(bool enabled, {String? userId}) async {
    try {
      if (userId != null) {
        await _upsertUserSettings(userId, {
          'remember_last_intent': enabled,
          'remember_last_vibe': enabled,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(_userKey('remember_mood_intent', userId), enabled);
      }
      await prefs.setBool(_rememberMoodIntentGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Remember Mood/Intent: $e');
    }
  }

  Future<String> getAppearanceMode({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final perUser = prefs.getString(_userKey('appearance_mode', userId));
        if (perUser != null && perUser.trim().isNotEmpty) return perUser;
      }
      return prefs.getString(_appearanceModeGlobalKey) ?? 'trulura';
    } catch (e) {
      debugPrint('Failed to get appearance mode: $e');
      return 'trulura';
    }
  }

  Future<void> setAppearanceMode(String mode, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setString(_userKey('appearance_mode', userId), mode);
      }
      await prefs.setString(_appearanceModeGlobalKey, mode);
    } catch (e) {
      debugPrint('Failed to set appearance mode: $e');
    }
  }

  Future<Map<String, String>> getDismissedHomePromptStatuses({
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final perUserStatusesKey = userId == null
          ? null
          : _userKey('dismissed_home_prompts_statuses', userId);
      final rawStatuses = perUserStatusesKey == null
          ? prefs.getString(_dismissedHomePromptsStatusesGlobalKey)
          : prefs.getString(perUserStatusesKey) ??
              prefs.getString(_dismissedHomePromptsStatusesGlobalKey);
      if (rawStatuses != null && rawStatuses.isNotEmpty) {
        final decoded = jsonDecode(rawStatuses);
        if (decoded is Map) {
          final statuses = decoded.map(
            (key, value) => MapEntry(
              key.toString().trim(),
              value.toString().trim(),
            ),
          );
          return statuses
            ..removeWhere(
              (key, value) =>
                  key.isEmpty ||
                  (value != 'permanent' && value != 'next_login'),
            );
        }
      }

      if (userId != null) {
        final perUser = prefs.getStringList(
          _userKey('dismissed_home_prompts', userId),
        );
        if (perUser != null) {
          return {
            for (final promptId in perUser)
              if (promptId.trim().isNotEmpty) promptId.trim(): 'permanent',
          };
        }
      }
      final global = prefs.getStringList(_dismissedHomePromptsGlobalKey) ??
          const <String>[];
      return {
        for (final promptId in global)
          if (promptId.trim().isNotEmpty) promptId.trim(): 'permanent',
      };
    } catch (e) {
      debugPrint('Failed to get dismissed home prompt statuses: $e');
      return const <String, String>{};
    }
  }

  Future<void> setDismissedHomePromptStatuses(
    Map<String, String> statuses, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitized = <String, String>{};
      for (final entry in statuses.entries) {
        final promptId = entry.key.trim();
        final status = entry.value.trim();
        if (promptId.isEmpty) continue;
        if (status != 'permanent' && status != 'next_login') continue;
        sanitized[promptId] = status;
      }
      final encoded = jsonEncode(sanitized);
      if (userId != null) {
        await prefs.setString(
          _userKey('dismissed_home_prompts_statuses', userId),
          encoded,
        );
        await prefs.remove(_userKey('dismissed_home_prompts', userId));
      }
      await prefs.setString(_dismissedHomePromptsStatusesGlobalKey, encoded);
      await prefs.remove(_dismissedHomePromptsGlobalKey);
    } catch (e) {
      debugPrint('Failed to set dismissed home prompt statuses: $e');
    }
  }

  Future<bool> getInterestQuizCompleted({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCompleted = userId != null
          ? (prefs.getBool(
                  _userKey('interest_quiz_completed', userId),
                ) ??
              prefs.getBool(_interestQuizCompletedGlobalKey) ??
              false)
          : (prefs.getBool(_interestQuizCompletedGlobalKey) ?? false);

      if (userId != null) {
        final row = await _getUserSettingsRow(userId);
        final remote = row?['interest_quiz_completed'];
        if (remote is bool) {
          if (remote || !localCompleted) return remote;
          try {
            await _upsertUserSettings(userId, {
              'interest_quiz_completed': true,
            });
          } catch (e) {
            debugPrint(
              'AppSettingsService.getInterestQuizCompleted remote backfill skipped: $e',
            );
          }
          return true;
        }
        if (localCompleted) {
          try {
            await _upsertUserSettings(userId, {
              'interest_quiz_completed': true,
            });
          } catch (e) {
            debugPrint(
              'AppSettingsService.getInterestQuizCompleted remote sync skipped: $e',
            );
          }
        }
      }
      return localCompleted;
    } catch (e) {
      debugPrint('Failed to get interest quiz completion: $e');
      return false;
    }
  }

  Future<void> setInterestQuizCompleted(
    bool completed, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('interest_quiz_completed', userId),
          completed,
        );
      }
      await prefs.setBool(_interestQuizCompletedGlobalKey, completed);
      if (userId != null) {
        try {
          await _upsertUserSettings(userId, {
            'interest_quiz_completed': completed,
          });
        } catch (e) {
          debugPrint(
            'AppSettingsService.setInterestQuizCompleted remote sync skipped: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to set interest quiz completion: $e');
    }
  }

  Future<bool> getSoftModeGateCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_softModeGateCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Soft Mode gate: $e');
      return false;
    }
  }

  Future<void> setSoftModeGateCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_softModeGateCompletedKey, completed);
    } catch (e) {
      debugPrint('Failed to set Soft Mode gate: $e');
    }
  }

  Future<bool> getSoftModeEnabled({String? userId}) async {
    try {
      if (userId != null) {
        final row = await _getUserSettingsRow(userId);
        final remote = row?['soft_mode_enabled'];
        if (remote is bool) return remote;
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('soft_mode_enabled', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_softModeEnabledGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Soft Mode enabled: $e');
      return false;
    }
  }

  Future<void> setSoftModeEnabled(bool enabled, {String? userId}) async {
    try {
      if (userId != null) {
        await _upsertUserSettings(userId, {
          'soft_mode_enabled': enabled,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(_userKey('soft_mode_enabled', userId), enabled);
      }
      await prefs.setBool(_softModeEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Soft Mode enabled: $e');
    }
  }

  Future<bool> getCreatorModeEnabled({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('creator_mode_enabled', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_creatorModeEnabledGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Creator Mode enabled: $e');
      return false;
    }
  }

  Future<void> setCreatorModeEnabled(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(_userKey('creator_mode_enabled', userId), enabled);
      }
      await prefs.setBool(_creatorModeEnabledGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Creator Mode enabled: $e');
    }
  }

  Future<bool> getCreatorApproved({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('creator_approved', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_creatorApprovedGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Creator approved: $e');
      return false;
    }
  }

  Future<void> setCreatorApproved(bool approved, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(_userKey('creator_approved', userId), approved);
      }
      await prefs.setBool(_creatorApprovedGlobalKey, approved);
    } catch (e) {
      debugPrint('Failed to set Creator approved: $e');
    }
  }

  Future<bool> getCreatorOnboardingComplete({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('creator_onboarding_complete', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_creatorOnboardingCompleteGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Creator onboarding completion: $e');
      return false;
    }
  }

  Future<void> setCreatorOnboardingComplete(
    bool completed, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('creator_onboarding_complete', userId),
          completed,
        );
      }
      await prefs.setBool(_creatorOnboardingCompleteGlobalKey, completed);
    } catch (e) {
      debugPrint('Failed to set Creator onboarding completion: $e');
    }
  }

  Future<bool> getHasAdvancedVerification({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('has_advanced_verification', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_hasAdvancedVerificationGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get advanced verification state: $e');
      return false;
    }
  }

  Future<void> setHasAdvancedVerification(
    bool enabled, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('has_advanced_verification', userId),
          enabled,
        );
      }
      await prefs.setBool(_hasAdvancedVerificationGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set advanced verification state: $e');
    }
  }

  Future<bool> getHasBackgroundVerification({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('has_background_verification', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_hasBackgroundVerificationGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get background verification state: $e');
      return false;
    }
  }

  Future<void> setHasBackgroundVerification(
    bool enabled, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('has_background_verification', userId),
          enabled,
        );
      }
      await prefs.setBool(_hasBackgroundVerificationGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set background verification state: $e');
    }
  }

  Future<bool> getHasLuxeInvite({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('has_luxe_invite', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_hasLuxeInviteGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Luxe invite state: $e');
      return false;
    }
  }

  Future<void> setHasLuxeInvite(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(_userKey('has_luxe_invite', userId), enabled);
      }
      await prefs.setBool(_hasLuxeInviteGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Luxe invite state: $e');
    }
  }

  Future<bool> getHasLuxeSubscription({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('has_luxe_subscription', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_hasLuxeSubscriptionGlobalKey) ?? false;
    } catch (e) {
      debugPrint('Failed to get Luxe subscription state: $e');
      return false;
    }
  }

  Future<void> setHasLuxeSubscription(
    bool enabled, {
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setBool(
          _userKey('has_luxe_subscription', userId),
          enabled,
        );
      }
      await prefs.setBool(_hasLuxeSubscriptionGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Luxe subscription state: $e');
    }
  }

  Future<bool> getShowLivesInFeed({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('show_lives_in_feed', userId);
        final perUser = prefs.getBool(key);
        if (perUser != null) return perUser;
      }
      return prefs.getBool(_showLivesInFeedGlobalKey) ?? true;
    } catch (e) {
      debugPrint('Failed to get Show Lives in Feed: $e');
      return true;
    }
  }

  Future<void> setShowLivesInFeed(bool enabled, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setBool(_userKey('show_lives_in_feed', userId), enabled);
      await prefs.setBool(_showLivesInFeedGlobalKey, enabled);
    } catch (e) {
      debugPrint('Failed to set Show Lives in Feed: $e');
    }
  }

  /// Frequency hint used for future feed insertion rules.
  ///
  /// Allowed values: "Rare", "Normal", "Often".
  Future<String> getLivesInFeedFrequency({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        final key = _userKey('lives_in_feed_frequency', userId);
        final perUser = prefs.getString(key);
        if (perUser != null) return perUser;
      }
      return prefs.getString(_livesInFeedFrequencyGlobalKey) ?? 'Normal';
    } catch (e) {
      debugPrint('Failed to get Lives in Feed frequency: $e');
      return 'Normal';
    }
  }

  Future<void> setLivesInFeedFrequency(String value, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setString(_userKey('lives_in_feed_frequency', userId), value);
      await prefs.setString(_livesInFeedFrequencyGlobalKey, value);
    } catch (e) {
      debugPrint('Failed to set Lives in Feed frequency: $e');
    }
  }
}
