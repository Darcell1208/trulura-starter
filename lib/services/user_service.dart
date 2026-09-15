import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:trulura/models/user.dart';
import 'package:trulura/models/vibe_read.dart';
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

  Future<void> _persistMatchmakingProfile(User user, Set<String> dirty) async {
    final intentDirty = dirty.contains('intents');
    final interestsDirty = dirty.contains('interests');
    if (!intentDirty && !interestsDirty) return;
    final intent = intentDirty ? _firstNonEmpty(user.intents) : null;
    final interests = !interestsDirty
        ? const <String>[]
        : user.interests
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

    // No intent default: payload carries intent only when the user chose one.
    // This used to insert 'Social', recording an answer nobody gave, which
    // then scored as intent's 10 points and read back as their choice.
    await _client.from('matchmaking_profiles').insert({
      'user_id': user.id,
      ...payload,
    });
  }

  /// Persists the onboarding Vibe to `profiles.vibe`.
  ///
  /// Was `_persistMood`, writing `user_states.mood_tag`. That column now has a
  /// single writer -- MoodSyncService -- and a single vocabulary, the `Mood`
  /// enum. This method was the second writer, and it wrote a different
  /// vocabulary entirely.
  ///
  /// `user.moodTags` is not mood. It is the Vibe chosen in
  /// onboarding_vibe_screen.dart, whose own comment admits the stopgap --
  /// "Phase-1: store vibe as a mood tag". Its seven values (Reflective,
  /// Dreamy, Calm, Flirty, Healing, Energetic, Creative) are not a subset of
  /// the five Mood values: Dreamy, Energetic and Creative have no Mood
  /// equivalent, and `social` has no Vibe equivalent.
  ///
  /// The consequence of sharing the column was a silent, per-user failure:
  /// MoodSyncService.currentMood() could not map 'Dreamy' to a Mood, returned
  /// null, and AuraStateController fell back to its Mood.calm placeholder
  /// forever -- for that user only, which is why it survived testing.
  ///
  /// `profiles.vibe` is the correct home: text, nullable, and previously unused
  /// by any code. Note it is NOT `profiles.vibe_status`, which already holds
  /// `TruTemperament` (oldSoul, grounded, ...) -- a third vocabulary again.
  Future<void> _persistVibe(String userId, List<String> moodTags) async {
    final vibe = _firstNonEmpty(moodTags);
    if (vibe == null) return;

    // profiles rows are created by a trigger on auth.users, so the row always
    // exists by the time this runs -- a plain update is enough, and there is no
    // insert fallback of the kind user_states needed.
    await _client
        .from('profiles')
        .update({
          'vibe': vibe,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Writes the temperament to whichever column this database actually has.
  ///
  /// Tries `temperament`, then `vibe_status`, treating a missing-column error
  /// as "try the next name" and anything else as a real failure worth
  /// surfacing. Ordered new-name-first so that once the migration lands the
  /// first attempt succeeds and the fallback costs nothing.
  ///
  /// This exists so the schema and the client can be deployed independently. It
  /// is deliberately narrow: only this one column, only these two names.
  Future<void> _persistTemperament(String userId, String value) async {
    for (final column in const <String>['temperament', 'vibe_status']) {
      try {
        await _client
            .from('profiles')
            .update({column: value})
            .eq('id', userId)
            .select('id');
        return;
      } catch (e) {
        if (!_isMissingColumnError(e, column)) rethrow;
      }
    }
    debugPrint(
      'UserService._persistTemperament: neither temperament nor vibe_status '
      'exists on profiles; temperament not saved.',
    );
  }

  /// Writes only the profile columns whose fields are in [dirty].
  ///
  /// It used to write every column from the whole cached User, so a save that
  /// changed one field also persisted whatever defaults User() had seeded into
  /// the rest -- temperament oldSoul, identity mode social -- as if chosen.
  Future<void> _persistProfile(User user, Set<String> dirty) async {
    final photoUrl = _nullableTrimmed(user.profileImage);
    final basePayload = <String, dynamic>{
      // NULL, not '', for an empty username. profiles.username is UNIQUE and
      // allows many NULLs but only one ''; see
      // 20260914_handle_new_user_null_username.sql.
      if (dirty.contains('username'))
        'username': _nullableTrimmed(user.username),
      if (dirty.contains('name')) 'display_name': user.name.trim(),
      if (dirty.contains('bio')) ...{
        'bio': _nullableTrimmed(user.bio),
        'about_me': _nullableTrimmed(user.bio),
      },
      if (dirty.contains('profileImage')) ...{
        'profile_photo_url': photoUrl,
        'avatar_url': photoUrl,
      },
    };
    if (basePayload.isNotEmpty) {
      await _client.from('profiles').upsert(<String, dynamic>{
        'id': user.id,
        ...basePayload,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    // Temperament is written separately, and tolerantly, on purpose.
    //
    // It used to sit in safePayload, which goes through .upsert() with no
    // error handling at all. That made the column rename in
    // 20260910_rename_vibe_status_to_temperament.sql unshippable: applying it
    // would have failed every profile save with PGRST204 until new Dart
    // reached every client, and there is no moment when those two things are
    // simultaneously true.
    //
    // This tries the new column name first and falls back to the old one, so a
    // single build works against both schemas and the migration can land at any
    // time with no window where a write targets a column that is not there.
    // Once the migration is applied everywhere, delete the fallback -- that is
    // step 3, and it is safe to defer.
    if (dirty.contains('temperament')) {
      await _persistTemperament(user.id, user.temperament.name);
    }

    final optionalPayload = <String, dynamic>{
      if (dirty.contains('socialPreference'))
        'social_preference': _nullableTrimmed(user.socialPreference),
      if (dirty.contains('expressionPromptAnswer'))
        'expression_prompt_answer':
            _nullableTrimmed(user.expressionPromptAnswer),
      if (dirty.contains('expressionVibeTag'))
        'expression_vibe_tag': _nullableTrimmed(user.expressionVibeTag),
      if (dirty.contains('expressionShortPost'))
        'expression_short_post': _nullableTrimmed(user.expressionShortPost),
      if (dirty.contains('activeIdentityMode'))
        'active_identity_mode': user.activeIdentityMode.name,
      if (dirty.contains('anonymousOverlayEnabled'))
        'anonymous_overlay_enabled': user.anonymousOverlayEnabled,
    };
    if (optionalPayload.isNotEmpty) {
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
    }
    // Keys only, never values: safePayload carries display_name, bio, avatar
    // url and whatever else the profile holds, and printing it wrote the user's
    // own profile content to the console on every save.
    debugPrint(
      'UserService._persistProfile wrote columns: '
      '${[...basePayload.keys, ...optionalPayload.keys]..sort()}',
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
      temperament: cached?.temperament ?? TruTemperament.oldSoul,
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

  /// Upper bound on a discovery read. Explore and Sync page through what they
  /// get rather than needing the whole table.
  static const int _discoveryLimit = 200;

  /// Maps a `public.profiles` row into the app's [User].
  ///
  /// Deliberately tolerant: the row comes from `select()` rather than a named
  /// column list, so a column missing from the schema is simply absent rather
  /// than failing the whole query, and the display name falls back through
  /// display_name -> username.
  User _userFromProfileRow(Map<String, dynamic> row) {
    final now = DateTime.now();
    return User.fromJson({
      'id': row['id']?.toString() ?? '',
      'name': row['display_name']?.toString() ??
          row['username']?.toString() ??
          '',
      'username': row['username']?.toString() ?? '',
      'moodTags': User.vibeFromJson(row),
      'bio': row['bio']?.toString() ?? row['about_me']?.toString() ?? '',
      'profile_photo_url': row['profile_photo_url']?.toString() ??
          row['avatar_url']?.toString() ??
          '',
      'createdAt': row['created_at']?.toString() ?? now.toIso8601String(),
      'updatedAt': row['updated_at']?.toString() ?? now.toIso8601String(),
    });
  }

  /// Everyone discoverable, from `public.profiles`.
  ///
  /// Was a Phase-1 stub that returned only the signed-in user, with the
  /// comment "we only guarantee the current user exists". The consequence was
  /// not that discovery looked thin -- it was that Explore rendered the viewer
  /// back to themselves, Sync had no candidates, and every social surface
  /// downstream of this call was untestable. Blocking in particular exists and
  /// cannot be exercised, because the only routes to the block button are a
  /// profile sheet and a chat overflow menu and there was nobody to open
  /// either against.
  ///
  /// Reads `public.profiles_public`, not `public.profiles`. Since
  /// 20260914_profiles_scope_reads.sql a signed-in user can read only their own
  /// row of the table; other people come through the view, which is
  /// owner-executed, carries a ten-column allowlist, and is granted to
  /// `authenticated` only -- the same pattern as posts_feed and vent_feed.
  /// It does not filter by a profile's privacy setting, because no database
  /// column holds one.
  ///
  /// Results are written to the local user cache so [getUserById] can still
  /// resolve names offline.
  Future<List<User>> getAllUsers() async {
    try {
      if (!_supabaseReady) return _getCachedUsers();

      final rows =
          await _client.from('profiles_public').select().limit(_discoveryLimit);
      final users = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(_userFromProfileRow)
          .where((u) => u.id.trim().isNotEmpty)
          .toList();

      if (users.isEmpty) return _getCachedUsers();
      await _cacheUsers(users);
      return users;
    } catch (e) {
      debugPrint('Failed to get users: $e');
      return _getCachedUsers();
    }
  }

  /// One profile by id, from the server, falling back to the local cache.
  ///
  /// Previously cache-only, which is why the Blocked Users screen rendered raw
  /// UUIDs for anyone the device had never cached.
  Future<User?> getUserById(String id) async {
    final wanted = id.trim();
    if (wanted.isEmpty) return null;
    try {
      if (_supabaseReady) {
        // Usually someone else, so the allowlist view; see getAllUsers.
        final row = await _client
            .from('profiles_public')
            .select()
            .eq('id', wanted)
            .maybeSingle();
        if (row != null) {
          final user = _userFromProfileRow(Map<String, dynamic>.from(row));
          if (user.id.trim().isNotEmpty) {
            await _cacheUsers(<User>[user]);
            return user;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get user $wanted from profiles: $e');
    }
    try {
      final cached = await _getCachedUsers();
      for (final u in cached) {
        if (u.id == wanted) return u;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get user: $e');
      return null;
    }
  }

  /// Merges [incoming] into the local user cache by id.
  Future<void> _cacheUsers(List<User> incoming) async {
    if (incoming.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final merged = <String, User>{
        for (final u in await _getCachedUsers()) u.id: u,
        for (final u in incoming) u.id: u,
      };
      await prefs.setString(_usersKey,
          jsonEncode(merged.values.map((u) => u.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to cache users: $e');
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
      ]);
      final profile = results[0];
      final matchmakingProfile = results[1];
      final base = _fromAuthUser(authUser, cached: cached);
      final profileBio =
          (profile?['bio'] ?? profile?['about_me'])?.toString().trim() ?? '';
      final profileAvatar =
          (profile?['profile_photo_url'])?.toString().trim().isNotEmpty == true
              ? profile!['profile_photo_url'].toString().trim()
              : ((profile?['avatar_url'])?.toString().trim() ?? '');
      final intent = matchmakingProfile?['intent']?.toString().trim() ?? '';
      final profileInterests = _stringListOrEmpty(
        _mapOrEmpty(matchmakingProfile?['preferences'])['interests'],
      );
      final merged = base.copyWith(
        name:
            (profile?['display_name']?.toString().trim().isNotEmpty ?? false)
                ? profile!['display_name'].toString().trim()
                : base.name,
        // A fetched row is authoritative for username, empty included. The
        // fallback used to be base.username, which comes from the device-global
        // current_user cache, so a new account on a shared device inherited the
        // previous account's username and saveUser wrote it back -- the same
        // unique collision by another route. The cache stands in only when no
        // row was fetched.
        username: profile == null
            ? base.username
            : (profile['username']?.toString().trim() ?? ''),
        // The matchmaking query succeeded, so its answer is authoritative even
        // when there is no row: no intent, no interests -- not the cache.
        intents: intent.isNotEmpty ? <String>[intent] : const <String>[],
        moodTags: profile == null
            ? base.moodTags
            : User.vibeFromJson(Map<String, dynamic>.from(profile)),
        interests: profileInterests,
        activeIdentityMode: TruIdentityModeX.tryParse(
              profile?['active_identity_mode']?.toString(),
            ) ??
            base.activeIdentityMode,
        anonymousOverlayEnabled:
            (profile?['anonymous_overlay_enabled'] as bool?) ??
            base.anonymousOverlayEnabled,
        // New column name first, old one as fallback, so this build reads
        // correctly either side of the rename migration.
        temperament: TruTemperamentX.tryParse(
              (profile?['temperament'] ?? profile?['vibe_status'])?.toString(),
            ) ??
            base.temperament,
        updatedAt: DateTime.now(),
      );
      // Scored profile fields come from the fetched row, empty included. They
      // used to fall back to the cache, so a value that never reached the
      // server kept scoring as a saved answer -- a default counted as an
      // answer. copyWith cannot clear a field (null keeps the old value),
      // hence the JSON round trip, the same one the local cache relies on.
      // No row fetched at all: keep the cache.
      final user = profile == null
          ? merged
          : User.fromJson({
              ...merged.toJson(),
              'bio': _nullableTrimmed(profileBio),
              'profileImage': _nullableTrimmed(profileAvatar),
              'socialPreference':
                  _nullableTrimmed(profile['social_preference']?.toString()),
              'expressionPromptAnswer': _nullableTrimmed(
                  profile['expression_prompt_answer']?.toString()),
              'expressionVibeTag':
                  _nullableTrimmed(profile['expression_vibe_tag']?.toString()),
              'expressionShortPost': _nullableTrimmed(
                  profile['expression_short_post']?.toString()),
            });
      // Hydrated only when a profiles row was actually read; see saveUser.
      final loaded = profile == null ? user : user.markHydrated();
      await _cacheCurrentUser(loaded);
      return loaded;
    } catch (e) {
      debugPrint('Failed to get current user: $e');
      return null;
    }
  }

  /// Reads this account's saved Vibe for the sign-in routing decision.
  ///
  /// getCurrentUser cannot answer this: it returns null on any error and fills
  /// Vibe from the local cache when no profiles row comes back, so an empty
  /// moodTags there can mean "saved as empty" or "could not read". Only a
  /// successful read of a present row with an empty vibe is [VibeRead.empty].
  Future<VibeRead> readOwnVibe() async {
    try {
      if (!_supabaseReady) return VibeRead.unknown;
      final authUser = AuthService.instance.currentAuthUser;
      if (authUser == null) return VibeRead.unknown;
      final row = await _client
          .from('profiles')
          .select('vibe')
          .eq('id', authUser.id)
          .maybeSingle();
      if (row == null) return VibeRead.unknown;
      final vibe = row['vibe']?.toString().trim() ?? '';
      return vibe.isEmpty ? VibeRead.empty : VibeRead.present;
    } catch (e) {
      debugPrint('UserService.readOwnVibe failed: ${safeError(e)}');
      return VibeRead.unknown;
    }
  }

  Future<void> setCurrentUser(User user) async {
    // Compatibility shim: some onboarding screens still call this.
    // In Supabase mode, "current user" is auth-driven; we keep a cache for UX.
    await _cacheCurrentUser(user);
  }

  /// Saves the fields that changed since [user] was hydrated, and nothing else.
  ///
  /// User() seeds non-null defaults -- temperament oldSoul, identity mode
  /// social, trustScore 70, profileVisibility public -- so "not answered" and
  /// "answered with the default" are the same object. Two rules follow:
  ///
  /// - An unhydrated user (never read back from a profiles row) is refused.
  ///   Its fields cannot be told apart from defaults, so any write would
  ///   persist defaults as chosen.
  /// - A hydrated user writes only its dirty fields: those that differ from
  ///   the snapshot taken when it was read. Untouched fields may still hold a
  ///   default the reader substituted, and are left alone.
  ///
  /// Known-deferred, and not fixed here: User.fromJson substitutes the same
  /// defaults on read, so the app still believes invented values even though
  /// it no longer writes them. The end state is nullable fields with the UI
  /// supplying display defaults.
  Future<void> saveUser(User user) async {
    if (!user.isHydrated) {
      debugPrint(
          'UserService.saveUser skipped: user was not hydrated from profiles');
      return;
    }
    final dirty = user.dirtyFields();
    if (dirty.isEmpty) return;
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
            await _persistProfile(user, dirty);
          } catch (e) {
            debugPrint(
              'UserService.saveUser persist profile failed (non-fatal): $e',
            );
          }
          try {
            await _persistMatchmakingProfile(user, dirty);
          } catch (e) {
            debugPrint(
              'UserService.saveUser persist matchmaking profile failed (non-fatal): $e',
            );
          }
          if (dirty.contains('moodTags')) {
            try {
              await _persistVibe(user.id, user.moodTags);
            } catch (e) {
              debugPrint(
                'UserService.saveUser persist vibe failed (non-fatal): $e',
              );
            }
          }
          if (dirty.contains('name') || dirty.contains('username')) {
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
            .select('preferences')
            .eq('user_id', userId)
            .maybeSingle();
        final mergedPreferences = <String, dynamic>{
          ..._mapOrEmpty(existing?['preferences']),
          'interests': cleaned,
        };
        // Interests only; intent is left as saved, or absent. This used to
        // write 'Social' whenever no intent existed -- an interests save
        // recording an intent the user never chose.
        final payload = <String, dynamic>{
          'active': true,
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
      debugPrint('Failed to read cached current user: ${safeError(e)}');
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
      debugPrint('Failed to read cached users: ${safeError(e)}');
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
