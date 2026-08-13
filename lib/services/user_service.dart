import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:trulura/models/user.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/database_service/database_service.dart';

class UserService {
  // Local cache to keep the app resilient when offline / during early boot.
  static const String _usersKey = 'users_cache';
  static const String _currentUserKey = 'current_user';

  bool get _supabaseReady => DatabaseService.instance.isInitialized;

  sb.SupabaseClient get _client => DatabaseService.instance.client;

  String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  List<String> _stringListOrEmpty(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Object>()
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  Map<String, dynamic> _mapOrEmpty(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }

  String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _isMissingColumnError(Object error, String columnName) {
    final msg = error.toString().toLowerCase();
    final needle = columnName.toLowerCase();
    return msg.contains('42703') ||
        (msg.contains(needle) && msg.contains('does not exist')) ||
        (msg.contains(needle) && msg.contains('could not find')) ||
        (msg.contains('pgrst204') && msg.contains(needle));
  }

  Future<void> _persistMatchmakingProfile(User user) async {
    final intent = _firstNonEmpty(user.intents);
    final interests = user.interests
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (intent == null && interests.isEmpty) return;

    Map<String, dynamic> existingPreferences = <String, dynamic>{};
    try {
      final existing = await _client
          .from('matchmaking_profiles')
          .select('user_id, preferences')
          .eq('user_id', user.id)
          .maybeSingle();
      existingPreferences = _mapOrEmpty(existing?['preferences']);
    } catch (e) {
      debugPrint(
        'UserService._persistMatchmakingProfile read existing preferences failed: $e',
      );
    }

    final mergedPreferences = <String, dynamic>{
      ...existingPreferences,
      if (interests.isNotEmpty) 'interests': interests,
    };

    final payload = <String, dynamic>{
      'active': true,
      'preferences': mergedPreferences,
      if (intent != null) 'intent': intent,
    };

    final updated = await _client
        .from('matchmaking_profiles')
        .update(payload)
        .eq('user_id', user.id)
        .select('user_id');

    if ((updated as List).isNotEmpty) return;

    await _client.from('matchmaking_profiles').insert({
      'user_id': user.id,
      'intent': intent ?? 'Social',
      ...payload,
    });
  }

  Future<void> _persistMood(String userId, List<String> moodTags) async {
    final mood = _firstNonEmpty(moodTags);
    if (mood == null) return;
    final nowIso = DateTime.now().toIso8601String();

    final updated = await _client
        .from('user_states')
        .update({
          'mood_tag': mood,
          'updated_at': nowIso,
        })
        .eq('user_id', userId)
        .select('user_id');

    if ((updated as List).isNotEmpty) return;

    await _client.from('user_states').insert({
      'user_id': userId,
      'active_mode': 'social',
      'mood_tag': mood,
      'energy_level': 'medium',
      'low_energy_mode': false,
      'updated_at': nowIso,
    });
  }

  Future<void> _persistProfile(User user) async {
    final photoUrl = _nullableTrimmed(user.profileImage);
    final safePayload = <String, dynamic>{
      'id': user.id,
      'username': user.username.trim(),
      'display_name': user.name.trim(),
      'bio': _nullableTrimmed(user.bio),
      'about_me': _nullableTrimmed(user.bio),
      'profile_photo_url': photoUrl,
      'avatar_url': photoUrl,
      'vibe_status': user.vibeLabel.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _client.from('profiles').upsert(safePayload);

    final optionalPayload = <String, dynamic>{
      'social_preference': _nullableTrimmed(user.socialPreference),
      'expression_prompt_answer': _nullableTrimmed(user.expressionPromptAnswer),
      'expression_vibe_tag': _nullableTrimmed(user.expressionVibeTag),
      'expression_short_post': _nullableTrimmed(user.expressionShortPost),
      'active_identity_mode': user.activeIdentityMode.name,
      'anonymous_overlay_enabled': user.anonymousOverlayEnabled,
    };
    try {
      await _client
          .from('profiles')
          .update(optionalPayload)
          .eq('id', user.id)
          .select('id');
    } catch (e) {
      if (!_isMissingColumnError(e, 'social_preference') &&
          !_isMissingColumnError(e, 'expression_prompt_answer') &&
          !_isMissingColumnError(e, 'expression_vibe_tag') &&
          !_isMissingColumnError(e, 'expression_short_post') &&
          !_isMissingColumnError(e, 'active_identity_mode') &&
          !_isMissingColumnError(e, 'anonymous_overlay_enabled')) {
        rethrow;
      }
      debugPrint(
        'UserService._persistProfile optional profile columns unavailable yet; saved base profile only.',
      );
    }
    debugPrint(
      'UserService._persistProfile saved base profile: $safePayload',
    );
  }

  /// Auth-only user mapping.
  ///
  /// This project intentionally does **not** depend on a `public.users`/`public.profiles`
  /// mirror table being kept in sync with `auth.users`.
  User _fromAuthUser(sb.User authUser, {User? cached}) {
    final email = authUser.email ?? cached?.email ?? '';
    final meta = authUser.userMetadata ?? const <String, dynamic>{};
    final name = User.publicDisplayNameFrom(
      (meta['name'] as String?) ?? cached?.name,
      email: email,
      fallback: 'New member',
    );
    final now = DateTime.now();
    return User(
      id: authUser.id,
      name: name,
      username: (meta['username'] as String?) ?? cached?.username ?? '',
      email: email,
      bio: cached?.bio,
      profileImage: cached?.profileImage,
      age: cached?.age ?? 18,
      location: cached?.location,
      pronouns: cached?.pronouns,
      languages: cached?.languages ?? const [],
      intents: cached?.intents ?? const [],
      moodTags: cached?.moodTags ?? const [],
      interests: cached?.interests ?? const [],
      socialPreference: cached?.socialPreference,
      expressionPromptAnswer: cached?.expressionPromptAnswer,
      expressionVibeTag: cached?.expressionVibeTag,
      expressionShortPost: cached?.expressionShortPost,
      activeIdentityMode:
          cached?.activeIdentityMode ?? TruIdentityMode.social,
      anonymousOverlayEnabled: cached?.anonymousOverlayEnabled ?? false,
      vibeLabel: cached?.vibeLabel ?? TruVibeLabel.oldSoul,
      verificationLevel:
          cached?.verificationLevel ?? TruVerificationLevel.level0,
      trustScore: cached?.trustScore ?? 70,
      riskLevel: cached?.riskLevel ?? TruRiskLevel.low,
      trustLastUpdated: cached?.trustLastUpdated,
      showVerificationBadge: cached?.showVerificationBadge ?? true,
      showTrustIndicator: cached?.showTrustIndicator ?? true,
      allowScreenshots: cached?.allowScreenshots ?? true,
      messageAutoDelete: cached?.messageAutoDelete ?? false,
      profileVisibility:
          cached?.profileVisibility ?? TruProfileVisibility.public,
      createdAt: cached?.createdAt ?? now,
      updatedAt: cached?.updatedAt ?? now,
    );
  }

  Future<List<User>> getAllUsers() async {
    try {
      // Phase-1: we only guarantee the **current user** exists.
      // This keeps Aura/Explore starters functional without forcing you
      // to build full discovery queries yet.
      final me = await getCurrentUser();
      return me == null ? [] : [me];
    } catch (e) {
      debugPrint('Failed to get users: $e');
      return [];
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      // With auth-only setup, we don't support fetching arbitrary users
      // from a profiles table. For now, we only return cached users.
      final cached = await _getCachedUsers();
      return cached.where((u) => u.id == id).cast<User?>().first;
    } catch (e) {
      debugPrint('Failed to get user: $e');
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      if (!_supabaseReady) return _getCachedCurrentUser();

      final authUser = AuthService.instance.currentAuthUser;
      if (authUser == null) return null;

      final cached = await _getCachedCurrentUser();
      final results = await Future.wait([
        _client.from('profiles').select().eq('id', authUser.id).maybeSingle(),
        _client
            .from('matchmaking_profiles')
            .select('intent, preferences')
            .eq('user_id', authUser.id)
            .eq('active', true)
            .maybeSingle(),
        _client
            .from('user_states')
            .select('mood_tag')
            .eq('user_id', authUser.id)
            .maybeSingle(),
      ]);
      final profile = results[0];
      final matchmakingProfile = results[1];
      final userState = results[2];
      final base = _fromAuthUser(authUser, cached: cached);
      final profileBio =
          (profile?['bio'] ?? profile?['about_me'])?.toString().trim() ?? '';
      final profileAvatar =
          (profile?['profile_photo_url'])?.toString().trim().isNotEmpty == true
              ? profile!['profile_photo_url'].toString().trim()
              : ((profile?['avatar_url'])?.toString().trim() ?? '');
      final intent = matchmakingProfile?['intent']?.toString().trim() ?? '';
      final mood = userState?['mood_tag']?.toString().trim() ?? '';
      final profileInterests = _stringListOrEmpty(
        _mapOrEmpty(matchmakingProfile?['preferences'])['interests'],
      );
      final user = base.copyWith(
        name:
            (profile?['display_name']?.toString().trim().isNotEmpty ?? false)
                ? profile!['display_name'].toString().trim()
                : base.name,
        username:
            (profile?['username']?.toString().trim().isNotEmpty ?? false)
                ? profile!['username'].toString().trim()
                : base.username,
        bio: profileBio.isNotEmpty ? profileBio : base.bio,
        profileImage: profileAvatar.isNotEmpty ? profileAvatar : base.profileImage,
        intents: intent.isNotEmpty ? <String>[intent] : base.intents,
        moodTags: mood.isNotEmpty ? <String>[mood] : base.moodTags,
        interests: profileInterests.isNotEmpty
            ? profileInterests
            : base.interests,
        socialPreference:
            (profile?['social_preference']?.toString().trim().isNotEmpty ??
                    false)
                ? profile!['social_preference'].toString().trim()
                : base.socialPreference,
        expressionPromptAnswer:
            (profile?['expression_prompt_answer']
                        ?.toString()
                        .trim()
                        .isNotEmpty ??
                    false)
                ? profile!['expression_prompt_answer'].toString().trim()
                : base.expressionPromptAnswer,
        expressionVibeTag:
            (profile?['expression_vibe_tag']?.toString().trim().isNotEmpty ??
                    false)
                ? profile!['expression_vibe_tag'].toString().trim()
                : base.expressionVibeTag,
        expressionShortPost:
            (profile?['expression_short_post']
                        ?.toString()
                        .trim()
                        .isNotEmpty ??
                    false)
                ? profile!['expression_short_post'].toString().trim()
                : base.expressionShortPost,
        activeIdentityMode: TruIdentityModeX.tryParse(
              profile?['active_identity_mode']?.toString(),
            ) ??
            base.activeIdentityMode,
        anonymousOverlayEnabled:
            (profile?['anonymous_overlay_enabled'] as bool?) ??
            base.anonymousOverlayEnabled,
        vibeLabel:
            TruVibeLabelX.tryParse(profile?['vibe_status']?.toString()) ??
            base.vibeLabel,
        updatedAt: DateTime.now(),
      );
      await _cacheCurrentUser(user);
      return user;
    } catch (e) {
      debugPrint('Failed to get current user: $e');
      return null;
    }
  }

  Future<void> setCurrentUser(User user) async {
    // Compatibility shim: some onboarding screens still call this.
    // In Supabase mode, "current user" is auth-driven; we keep a cache for UX.
    await _cacheCurrentUser(user);
  }

  Future<void> saveUser(User user) async {
    try {
      // Auth-only setup: persist to local cache so onboarding can work,
      // without requiring any public mirror table.
      await _cacheCurrentUser(user);
      await _cacheUser(user);

      // Optional: best-effort store a few fields in auth.user_metadata.
      // This keeps UX consistent across devices without needing profiles.
      if (_supabaseReady) {
        final authUser = AuthService.instance.currentAuthUser;
        if (authUser != null && authUser.id == user.id) {
          try {
            await _persistProfile(user);
          } catch (e) {
            debugPrint(
              'UserService.saveUser persist profile failed (non-fatal): $e',
            );
          }
          try {
            await _persistMatchmakingProfile(user);
          } catch (e) {
            debugPrint(
              'UserService.saveUser persist matchmaking profile failed (non-fatal): $e',
            );
          }
          try {
            await _persistMood(user.id, user.moodTags);
          } catch (e) {
            debugPrint(
              'UserService.saveUser persist mood failed (non-fatal): $e',
            );
          }
          try {
            await _client.auth.updateUser(
              sb.UserAttributes(
                data: {
                  'name': user.name,
                  'username': user.username,
                },
              ),
            );
          } catch (e) {
            debugPrint(
              'UserService.saveUser updateUser metadata failed (non-fatal): $e',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to save user: $e');
    }
  }

  Future<void> saveInterests({
    required String userId,
    required List<String> interests,
  }) async {
    final cleaned = interests
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    try {
      final current = await getCurrentUser();
      if (current != null && current.id == userId) {
        await saveUser(
          current.copyWith(
            interests: cleaned,
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (_supabaseReady) {
        final existing = await _client
            .from('matchmaking_profiles')
            .select('intent, preferences')
            .eq('user_id', userId)
            .maybeSingle();
        final mergedPreferences = <String, dynamic>{
          ..._mapOrEmpty(existing?['preferences']),
          'interests': cleaned,
        };
        final payload = <String, dynamic>{
          'active': true,
          'intent':
              existing?['intent']?.toString().trim().isNotEmpty == true
                  ? existing!['intent'].toString().trim()
                  : 'Social',
          'preferences': mergedPreferences,
        };
        final updated = await _client
            .from('matchmaking_profiles')
            .update(payload)
            .eq('user_id', userId)
            .select('user_id');
        if ((updated as List).isEmpty) {
          await _client.from('matchmaking_profiles').insert({
            'user_id': userId,
            ...payload,
          });
        }
      }
    } catch (e) {
      debugPrint('UserService.saveInterests failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
    } catch (e) {
      debugPrint('Failed to logout: $e');
    }
  }

  Future<User?> _getCachedCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_currentUserKey);
      if (data == null) return null;
      return User.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to read cached current user: $e');
      return null;
    }
  }

  Future<void> _cacheCurrentUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Failed to cache current user: $e');
    }
  }

  Future<List<User>> _getCachedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_usersKey);
      if (data == null) return [];
      final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      return list.map(User.fromJson).toList();
    } catch (e) {
      debugPrint('Failed to read cached users: $e');
      return [];
    }
  }

  Future<void> _cacheUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getCachedUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      users[idx] = user;
    } else {
      users.add(user);
    }
    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }
}
