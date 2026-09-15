import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/experience/experience_mode.dart';

class PostService {
  /// The old device-global feed cache. Dead: deleted on first access.
  ///
  /// It held server rows for whoever last loaded the feed on this device, and
  /// those rows carry `post_privacy`, so a followers-only post cached for one
  /// account could render for the next account to sign in.
  static const String _legacyGlobalPostsKey = 'posts_cache';

  static String _postsCacheKeyFor(String uid) => 'posts_cache_$uid';

  /// The main feed. Since 20260908_vent_containment this view EXCLUDES Vent.
  static const String _feedView = 'posts_feed';

  /// The Vent environment's own feed. Returns only Vent, and nothing else does.
  ///
  /// Containment is a property of these two views, not of the client asking
  /// correctly -- a caller that forgets now gets a feed with no Vent in it
  /// rather than one that quietly leaks. Both carry the same privacy predicate.
  static const String _ventFeedView = 'vent_feed';
  static const String _reactionsTable = 'post_reactions';
  static const String _defaultReactionType = 'glow';

  bool get _supabaseReady => DatabaseService.instance.isInitialized;

  /// The account the cache belongs to, or null when signed out.
  String? get _cacheUid {
    try {
      if (!DatabaseService.instance.isInitialized) return null;
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeUuid(String value) =>
      RegExp(r'^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')
          .hasMatch(value);

  String _normalizePrivacy(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'public':
        return 'public';
      case 'friends':
      case 'followers':
        return 'followers';
      case 'private':
        return 'private';
      default:
        return 'public';
    }
  }

  String _normalizePostType(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v.isEmpty) return 'general';

    switch (v) {
      case 'general':
      case 'text':
      case 'image':
      case 'video':
      case 'link':
        return v;
      default:
        return 'general';
    }
  }

  /// Feed bucket a post belongs to. This is a different axis from
  /// [_normalizePostType], which describes the post's *format*.
  ///
  /// Persisted in `posts.category`. Without it the Vent bucket cannot round
  /// trip: writes would drop it and reads would have nothing to filter on.
  String _normalizeCategory(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'vent':
        return 'Vent';
      case 'mood':
        return 'Mood';
      default:
        return 'ForYou';
    }
  }

  /// Maps the app `Post` model to your current live `posts` table schema.
  ///
  /// Intentionally does **not** send `created_at` / `updated_at` because many
  /// Supabase schemas use DB defaults + triggers for those, and sending columns
  /// that don't exist will fail with `PGRST204`.
  Map<String, dynamic> _toRow(Post post) => {
        if (_looksLikeUuid(post.id)) 'id': post.id,
        'user_id': post.userId,
        'content_text': post.content,
        'image_url': post.imageUrl,
        'post_type': _normalizePostType(post.type),
        'mood_tag': post.moodTag,
        'post_privacy': _normalizePrivacy(post.privacy),
        'is_anonymous': post.isAnonymous,
        'category': _normalizeCategory(post.category),
        // Optional: if your posts table includes this column, we will persist it.
        // If it doesn't exist yet, we auto-retry inserts without it.
        if (post.experienceMode != null)
          'experience_mode': post.experienceMode!.name,
      };

  String? _currentUserIdOrNull() {
    try {
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (e) {
      debugPrint('PostService: failed reading current user id: $e');
      return null;
    }
  }

  /// Returns the glow count per post id.
  ///
  /// Uses a simple select and aggregates on the client to avoid DB-side RPC.
  Future<Map<String, int>> getReactionCounts(
      {required List<String> postIds,
      String reactionType = _defaultReactionType}) async {
    if (!_supabaseReady) return <String, int>{};
    final validPostIds = postIds.where(_looksLikeUuid).toList(growable: false);
    if (validPostIds.isEmpty) return <String, int>{};

    try {
      final rows = await DatabaseService.instance.client
          .from(_reactionsTable)
          .select('post_id')
          .inFilter('post_id', validPostIds)
          .eq('reaction_type', reactionType);

      final counts = <String, int>{};
      for (final r in (rows as List)) {
        final id = (r as Map)['post_id']?.toString();
        if (id == null || id.isEmpty) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('PostService: getReactionCounts failed: $e');
      return <String, int>{};
    }
  }

  /// Returns the set of post ids the current user has reacted to (e.g. glowed).
  Future<Set<String>> getMyReactedPostIds(
      {required List<String> postIds,
      String reactionType = _defaultReactionType}) async {
    if (!_supabaseReady) return <String>{};
    final validPostIds = postIds.where(_looksLikeUuid).toList(growable: false);
    if (validPostIds.isEmpty) return <String>{};
    final userId = _currentUserIdOrNull();
    if (userId == null) return <String>{};

    try {
      final rows = await DatabaseService.instance.client
          .from(_reactionsTable)
          .select('post_id')
          .inFilter('post_id', validPostIds)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType);

      final ids = <String>{};
      for (final r in (rows as List)) {
        final id = (r as Map)['post_id']?.toString();
        if (id == null || id.isEmpty) continue;
        ids.add(id);
      }
      return ids;
    } catch (e) {
      debugPrint('PostService: getMyReactedPostIds failed: $e');
      return <String>{};
    }
  }

  /// Legacy toggle helper kept for older callers.
  ///
  /// Returns `true` if the reaction is present after the operation.
  Future<bool> toggleReactionLegacy(
      {required String postId,
      String reactionType = _defaultReactionType}) async {
    if (!_supabaseReady) throw Exception('Database not initialized');
    final userId = _currentUserIdOrNull();
    if (userId == null) throw Exception('User not logged in');
    if (postId.isEmpty) throw Exception('Invalid post id');

    try {
      final existing = await DatabaseService.instance.client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        await DatabaseService.instance.client
            .from(_reactionsTable)
            .delete()
            .eq('id', existing['id'].toString());
        return false;
      }

      await DatabaseService.instance.client.from(_reactionsTable).insert({
        'post_id': postId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
      return true;
    } catch (e) {
      debugPrint('PostService: toggleReaction failed: $e');
      rethrow;
    }
  }

  /// Generic reaction toggle helper (e.g. heart, laugh, glow).
  ///
  /// This matches the `post_reactions` schema: (post_id, user_id, reaction_type).
  ///
  /// Note: We keep the older `toggleReaction(...) -> bool` API above for existing
  /// callers, but this method matches the newer "void + required reactionType"
  /// signature used by the FeedCard reaction sheet.
  Future<void> toggleReaction(
      {required String postId, required String reactionType}) async {
    final client = DatabaseService.instance.client;
    final currentUser = client.auth.currentUser;

    if (!_supabaseReady) throw Exception('Database not initialized');
    if (currentUser == null) throw Exception('User not logged in');
    if (postId.isEmpty) throw Exception('Invalid post id');

    try {
      final existing = await client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .eq('reaction_type', reactionType)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        await client
            .from(_reactionsTable)
            .delete()
            .eq('id', existing['id'].toString());
      } else {
        await client.from(_reactionsTable).insert({
          'post_id': postId,
          'user_id': currentUser.id,
          'reaction_type': reactionType,
        });
      }
    } catch (e) {
      debugPrint('PostService: toggleReaction failed: $e');
      rethrow;
    }
  }

  /// Count reactions of a given type for a single post.
  Future<int> getReactionCount(
      {required String postId, required String reactionType}) async {
    if (!_supabaseReady) return 0;
    if (postId.isEmpty) return 0;

    try {
      final rows = await DatabaseService.instance.client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('reaction_type', reactionType);
      return (rows as List).length;
    } catch (e) {
      debugPrint('PostService: getReactionCount failed: $e');
      return 0;
    }
  }

  /// Whether the current user has reacted with a specific type.
  Future<bool> hasReactedWith(
      {required String postId, required String reactionType}) async {
    if (!_supabaseReady) return false;
    if (postId.isEmpty) return false;

    final client = DatabaseService.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final row = await client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .eq('reaction_type', reactionType)
          .maybeSingle();
      return row != null;
    } catch (e) {
      debugPrint('PostService: hasReactedWith failed: $e');
      return false;
    }
  }

  /// Fast-path Glow toggle (insert/delete) using the `post_reactions` table.
  ///
  /// This mirrors the SQL constraint: unique (post_id, user_id, reaction_type).
  Future<void> toggleGlow(String postId) async {
    final client = DatabaseService.instance.client;
    final currentUser = client.auth.currentUser;

    if (!_supabaseReady) throw Exception('Database not initialized');
    if (currentUser == null) throw Exception('User not logged in');
    if (postId.isEmpty) throw Exception('Invalid post id');

    try {
      final existing = await client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .eq('reaction_type', _defaultReactionType)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        await client
            .from(_reactionsTable)
            .delete()
            .eq('id', existing['id'].toString());
      } else {
        await client.from(_reactionsTable).insert({
          'post_id': postId,
          'user_id': currentUser.id,
          'reaction_type': _defaultReactionType,
        });
      }
    } catch (e) {
      debugPrint('PostService: toggleGlow failed: $e');
      rethrow;
    }
  }

  /// Returns Glow reaction count for a single post.
  Future<int> getGlowCount(String postId) async {
    if (!_supabaseReady) return 0;
    if (postId.isEmpty) return 0;

    try {
      final rows = await DatabaseService.instance.client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('reaction_type', _defaultReactionType);
      return (rows as List).length;
    } catch (e) {
      debugPrint('PostService: getGlowCount failed: $e');
      return 0;
    }
  }

  /// Whether the currently signed-in user has Glowed this post.
  Future<bool> hasGlowed(String postId) async {
    if (!_supabaseReady) return false;
    if (postId.isEmpty) return false;

    final client = DatabaseService.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final row = await client
          .from(_reactionsTable)
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .eq('reaction_type', _defaultReactionType)
          .maybeSingle();
      return row != null;
    } catch (e) {
      debugPrint('PostService: hasGlowed failed: $e');
      return false;
    }
  }

  /// Fetches the Aura feed from the anonymizing posts view.
  ///
  /// Anonymous rows deliberately return `user_id = null` from `posts_feed`.
  /// Writes still target `posts`; reads should not bypass this view.
  /// Reads the Vent environment. Separate view, same shape, same privacy rules.
  Future<List<Map<String, dynamic>>> fetchVentFeed() async {
    if (!_supabaseReady) throw StateError('Vent feed is not initialized.');
    final client = DatabaseService.instance.client;
    final account = client.auth.currentUser?.id;
    if (account == null) throw StateError('Sign in to load Vent.');
    if (kDebugMode) {
      debugPrint('VentFeed: request account=${redactedId(account)}');
    }
    final rows = await client
        .from(_ventFeedView)
        .select()
        .order('created_at', ascending: false);
    if (client.auth.currentUser?.id != account) {
      throw StateError('Account changed while loading Vent.');
    }
    final result = List<Map<String, dynamic>>.from(rows as List);
    if (kDebugMode) {
      debugPrint(
          'VentFeed: response account=${redactedId(account)} rows=${result.length}');
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchAuraFeed() async {
    if (!_supabaseReady) return [];

    // Select every column rather than naming them. An explicit column list
    // fails outright against a schema missing any one of them, which forced a
    // per-column fallback; `select()` simply omits absent columns from the
    // returned rows, and _fromAuraRow already tolerates nulls. This also means
    // newly added columns (like `category`) need no change here.
    final rows = await DatabaseService.instance.client
        .from(_feedView)
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Maps a Supabase `posts` row (with optional `profiles:profile_id (...)` join)
  /// into the app's `Post` model.
  ///
  /// Kept public so realtime feed streams can reuse the same mapping.
  Post fromAuraRow(Map<String, dynamic> row) {
    return _fromAuraRow(row);
  }

  Post _fromAuraRow(Map<String, dynamic> row) {
    final mood = (row['mood_tag'] as String?)?.trim();

    final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString()) ??
        DateTime.now();
    final type = _normalizePostType(row['post_type'] as String?);
    final content = (row['content_text'] as String?) ?? '';
    return Post(
      id: row['id'].toString(),
      userId: row['user_id']?.toString() ?? '',
      user: null,
      content: content,
      caption: type == 'image' || type == 'video' ? content : null,
      imageUrl: row['image_url'] as String?,
      type: type,
      textStyle: type == 'text' ? 'serif' : null,
      moodTag: (mood?.isEmpty ?? true) ? null : mood,
      privacy: _normalizePrivacy(row['post_privacy'] as String?),
      category: _normalizeCategory(row['category'] as String?),
      isAnonymous: (row['is_anonymous'] as bool?) ?? false,
      experienceMode:
          TruExperienceModeX.tryParse(row['experience_mode']?.toString()),
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Future<List<Post>> getAllPosts() async {
    try {
      if (!_supabaseReady) return _readCachedPosts();

      // Capture the account BEFORE the fetch and cache under that same id.
      //
      // _cachePosts used to resolve the account itself, at write time, which
      // meant a sign-out and sign-in during the round trip filed one account's
      // feed under the next account's key -- reintroducing the cross-account
      // disclosure 7ecb53e closed, by a slower route. These rows carry
      // post_privacy, so the destination has to be decided by whose read this
      // was, not by whoever happens to be signed in when it returns.
      final uid = _cacheUid;
      final rows = await fetchAuraFeed();
      final posts = rows.map(fromAuraRow).toList(growable: false);

      await _cachePostsFor(uid, posts);
      return posts;
    } catch (e) {
      debugPrint('Failed to get posts: $e');
      return _readCachedPosts();
    }
  }

  /// Posts for one feed bucket.
  ///
  /// 'Vent' reads the vent_feed view rather than filtering the main feed.
  /// After 20260908_vent_containment posts_feed excludes Vent entirely, so the
  /// old client-side filter would return nothing forever -- and the filter was
  /// never the containment anyway, it was the thing standing in for it.
  ///
  /// Vent results are NOT written to the feed cache. That cache is read by
  /// getAllPosts as the main feed's fallback, and letting Vent rows into it
  /// would reintroduce the leak through the back door on the next offline read.
  Future<List<Post>> getPostsByCategory(String category) async {
    // A failed protected-feed read is not a successfully loaded empty feed.
    // Let the Sanctuary show its retry state; never substitute the main cache.
    if (category == 'Vent') {
      final rows = await fetchVentFeed();
      return rows.map(fromAuraRow).toList(growable: false);
    }
    try {
      final posts = await getAllPosts();
      if (category == 'ForYou') return posts;
      return posts.where((p) => p.category == category).toList();
    } catch (e) {
      debugPrint('Failed to get posts by category: $e');
      return [];
    }
  }

  Future<void> savePost(Post post) async {
    try {
      if (!_supabaseReady) {
        final cached = await _readCachedPosts();
        cached.insert(0, post);
        await _cachePosts(cached);
        return;
      }

      final currentUser = DatabaseService.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      Future<void> attemptInsert(Map<String, dynamic> row) async {
        if (kDebugMode) {
          // Column names only. This used to print the whole row, which meant
          // the text of every post -- including private, anonymous Vent posts
          // -- was written to the browser console, together with the author's
          // user_id. Vent content in a console defeats the point of Vent.
          debugPrint('PostService: inserting into posts, columns: '
              '${row.keys.toList()..sort()}');
        }
        await DatabaseService.instance.client.from('posts').insert(row);
      }

      final row = {..._toRow(post), 'user_id': currentUser.id};
      try {
        await attemptInsert(row);
      } catch (e) {
        // PGRST204 means the schema is missing a column we sent. `category`
        // and `experience_mode` are both optional; drop whichever one the
        // error names and retry once.
        final msg = e.toString();
        const optionalColumns = ['category', 'experience_mode'];
        final missing = optionalColumns
            .where((c) => msg.contains(c) && row.containsKey(c))
            .toList(growable: false);
        if (msg.contains('PGRST204') && missing.isNotEmpty) {
          debugPrint(
              'PostService: posts is missing $missing; retrying insert without them.');
          final fallback = Map<String, dynamic>.from(row)
            ..removeWhere((key, _) => missing.contains(key));
          await attemptInsert(fallback);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Failed to save post: $e');
      rethrow;
    }
  }

  /// The feed cache for the signed-in account.
  ///
  /// Returns empty when signed out rather than falling back to a shared cache.
  /// An empty feed is a worse first paint; showing another account's cached
  /// rows is a disclosure.
  Future<List<Post>> _readCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _dropLegacyGlobalCache(prefs);

      final uid = _cacheUid;
      if (uid == null) return [];

      final data = prefs.getString(_postsCacheKeyFor(uid));
      if (data == null) return [];
      final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      return list.map(Post.fromJson).toList();
    } catch (e) {
      debugPrint('Failed to read cached posts: ${safeError(e)}');
      return [];
    }
  }

  /// Caches under whoever is signed in now. Only safe when the read that
  /// produced [posts] cannot have spanned a session change; prefer
  /// [_cachePostsFor] with an account captured before the read.
  Future<void> _cachePosts(List<Post> posts) async =>
      _cachePostsFor(_cacheUid, posts);

  /// Caches [posts] under [uid], the account the read was made for.
  ///
  /// A null uid writes nothing: there is no account to file the feed under, and
  /// falling back to a shared key is what this whole change removed.
  Future<void> _cachePostsFor(String? uid, List<Post> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _dropLegacyGlobalCache(prefs);

      if (uid == null) return;

      await prefs.setString(_postsCacheKeyFor(uid),
          jsonEncode(posts.map((p) => p.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to cache posts: $e');
    }
  }

  /// Deletes the old device-global feed cache outright, once.
  ///
  /// Deleted rather than orphaned, which is the opposite of how consent,
  /// safety and identity prefs were handled in 4ff6dae and c78a37a. Those hold
  /// decisions; this holds a copy of server rows that re-fetch on the next
  /// load. Keeping a stale copy of other people's posts on disk under a dead
  /// key has a cost and no benefit -- these rows carry `post_privacy`, so a
  /// non-public post cached for one account must not survive where another
  /// account's code could reach it.
  ///
  /// Caveat on "re-fetch on the next load": [savePost] writes a post straight
  /// into this cache when Supabase was never initialised, and nothing ever
  /// pushes it to the server afterwards. Such a post is already destroyed by
  /// the next successful feed load, since [_cachePosts] replaces the list
  /// wholesale with the server's. So this delete loses nothing the app does
  /// not already lose on its own -- but that pre-existing hole is real and
  /// belongs with the swallowed-write-failure work, not here.
  Future<void> _dropLegacyGlobalCache(SharedPreferences prefs) async {
    try {
      if (!prefs.containsKey(_legacyGlobalPostsKey)) return;
      await prefs.remove(_legacyGlobalPostsKey);
      debugPrint('PostService: dropped device-global feed cache');
    } catch (e) {
      debugPrint('PostService._dropLegacyGlobalCache failed: $e');
    }
  }
}
