import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// Local-first social graph actions used by feed quick-actions, scoped to the
/// signed-in account.
///
/// When you later add Supabase tables (follows, sparks), this service is the
/// single place to switch implementations. Blocks already moved -- see
/// BlockService and public.blocks.
///
/// ## Why the keys are per-account, and why these are claimed not orphaned
///
/// Follows and sparks used to live under two device-global keys, so a second
/// person signing in on the same device inherited the first person's social
/// graph: the feed showed them as already following accounts they had never
/// chosen.
///
/// Unlike consent, safety and identity preferences -- which were discarded on
/// the way to per-account keys, because a guessed record of someone's consent
/// is worse than none -- these are claimed by the first account that runs. The
/// difference is recoverability. There is no follows or sparks table on the
/// server; this file is the only place either has ever been stored. Discarding
/// them silently unfollows everyone with no way to reconstruct who was there.
///
/// The caveat that comes with claiming, stated because it is easy to read
/// consume-and-claim as a solved problem: on a device where two accounts have
/// signed in, the local data has no attribution, so the first account to launch
/// after this change claims a graph that may belong to someone else. Claiming
/// bounds the damage -- it happens at most once rather than repeating for every
/// subsequent account -- but it cannot identify the rightful owner, because
/// nothing on disk can. That trade is acceptable here and was not acceptable
/// for consent.
class ConnectionService {
  /// The old device-global keys. Consumed by the first account to run, then
  /// removed so no second account can claim them.
  static const _legacyFollowsKey = 'graph_follows_v1';
  static const _legacySparksKey = 'graph_sparks_v1';

  static String _followsKeyFor(String uid) => 'graph_follows_v1_$uid';
  static String _sparksKeyFor(String uid) => 'graph_sparks_v1_$uid';

  String? get _uid {
    try {
      if (!DatabaseService.instance.isInitialized) return null;
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Set<String> _decode(String? raw) {
    if (raw == null) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (e) {
      debugPrint('ConnectionService._decode failed: $e');
      return <String>{};
    }
  }

  /// Moves both device-global sets under [uid], once.
  ///
  /// Merges rather than overwrites, so an account that already has its own set
  /// keeps it and gains the unclaimed entries instead of losing either.
  ///
  /// Write-then-remove, in that order: if the process dies between the two,
  /// the entries exist in both places and the next launch merges the same
  /// values into the same account, which is a no-op on a set. The reverse
  /// order could lose them.
  Future<void> _claimLegacy(SharedPreferences prefs, String uid) async {
    for (final pair in <List<String>>[
      <String>[_legacyFollowsKey, _followsKeyFor(uid)],
      <String>[_legacySparksKey, _sparksKeyFor(uid)],
    ]) {
      final legacyKey = pair[0];
      final ownKey = pair[1];
      try {
        final legacyRaw = prefs.getString(legacyKey);
        if (legacyRaw == null) continue;
        final merged = _decode(prefs.getString(ownKey))..addAll(_decode(legacyRaw));
        await prefs.setString(ownKey, jsonEncode(merged.toList(growable: false)));
        await prefs.remove(legacyKey);
        debugPrint(
            'ConnectionService: claimed $legacyKey for ${redactedId(uid)}');
      } catch (e) {
        debugPrint('ConnectionService._claimLegacy failed for $legacyKey: $e');
      }
    }
  }

  /// Reads one of this account's sets. Empty when signed out -- there is no
  /// account whose graph it would be.
  Future<Set<String>> _getSet(String Function(String uid) keyFor) async {
    final uid = _uid;
    if (uid == null) return <String>{};
    return _getSetFor(uid, keyFor);
  }

  Future<Set<String>> _getSetFor(
      String uid, String Function(String uid) keyFor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _claimLegacy(prefs, uid);
      return _decode(prefs.getString(keyFor(uid)));
    } catch (e) {
      debugPrint('ConnectionService._getSetFor failed: $e');
      return <String>{};
    }
  }

  /// Returns false if the write did not persist, including when signed out.
  Future<bool> _setSetFor(
      String uid, String Function(String uid) keyFor, Set<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _claimLegacy(prefs, uid);
      await prefs.setString(
          keyFor(uid), jsonEncode(values.toList(growable: false)));
      return true;
    } catch (e) {
      debugPrint('ConnectionService._setSetFor failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Connection requests -- the one part of this service that is server-backed.
  // ---------------------------------------------------------------------

  /// `public.spark_interactions`, the table a connection request lives in.
  ///
  /// It already existed, correctly scoped, with nothing in the app touching it.
  /// Verified against the live database before wiring:
  ///
  ///   spark_interactions (id, from_user_id, to_user_id, post_id, created_at)
  ///   spark_insert_from_self / spark_interactions_insert_sender  [INSERT]
  ///     with check: from_user_id = auth.uid()
  ///   spark_select_involving_me / ..._select_participants        [SELECT]
  ///     using: auth.uid() = from_user_id OR auth.uid() = to_user_id
  ///   spark_delete_from_self                                     [DELETE]
  ///
  /// The SELECT predicate is what makes this worth using: **the recipient can
  /// read the row.** That is the difference between a request that exists and
  /// the previous behaviour, where Explore added an id to a screen-local set,
  /// said "Connection request sent", and the other account never heard about
  /// it. `post_id` is nullable, so a person-to-person request with no post
  /// attached is a valid row.
  static const String _connectionsTable = 'spark_interactions';

  /// Sends a connection request to [toUserId]. False if it did not persist.
  ///
  /// Checks for an existing request first because the table has **no unique
  /// constraint** on (from_user_id, to_user_id) -- verified -- so nothing at
  /// the database level stops a second tap creating a duplicate row. The check
  /// is a courtesy, not a guarantee: two taps racing each other can still both
  /// insert. Worth a partial unique index if this stays.
  Future<bool> sendConnectionRequest(String toUserId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('ConnectionService.sendConnectionRequest: no signed-in account');
      return false;
    }
    final target = toUserId.trim();
    if (target.isEmpty || target == uid) return false;

    try {
      final client = DatabaseService.instance.client;
      final existing = await client
          .from(_connectionsTable)
          .select('id')
          .eq('from_user_id', uid)
          .eq('to_user_id', target)
          .limit(1);
      if ((existing as List).isNotEmpty) return true;

      await client.from(_connectionsTable).insert({
        'from_user_id': uid,
        'to_user_id': target,
      });
      return true;
    } catch (e) {
      debugPrint(
          'ConnectionService.sendConnectionRequest failed for ${redactedId(target)}: ${safeError(e)}');
      return false;
    }
  }

  /// Ids this account has already sent a request to.
  ///
  /// Read from the server rather than from screen state, so "Sent" reflects a
  /// row that exists rather than a tap that happened.
  Future<Set<String>> sentConnectionTargets() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    try {
      final rows = await DatabaseService.instance.client
          .from(_connectionsTable)
          .select('to_user_id')
          .eq('from_user_id', uid);
      return (rows as List)
          .map((r) => r['to_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('ConnectionService.sentConnectionTargets failed: ${safeError(e)}');
      return <String>{};
    }
  }

  /// Requests sent TO this account. Nothing renders these yet -- Pulse is a
  /// fixed demonstration list -- but the rows are readable, which is the half
  /// that was missing.
  Future<Set<String>> incomingConnectionRequests() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    try {
      final rows = await DatabaseService.instance.client
          .from(_connectionsTable)
          .select('from_user_id')
          .eq('to_user_id', uid);
      return (rows as List)
          .map((r) => r['from_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('ConnectionService.incomingConnectionRequests failed: ${safeError(e)}');
      return <String>{};
    }
  }

  Future<bool> isFollowing(String userId) async =>
      (await _getSet(_followsKeyFor)).contains(userId);

  Future<bool> hasSparked(String userId) async =>
      (await _getSet(_sparksKeyFor)).contains(userId);

  /// Returns false if the change did not persist. Callers currently fire this
  /// through `unawaited` and show the new state optimistically, which is the
  /// separate swallowed-write-failure pass.
  ///
  /// The account is resolved ONCE and used for both the read and the write.
  /// Resolving it twice -- read A's follows, then resolve again on the way out
  /// -- means a sign-out between the two writes A's graph into B's key, which
  /// is the cross-account leak 48025ab set out to close arriving through a
  /// narrower door.
  Future<bool> toggleFollow(String userId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('ConnectionService.toggleFollow skipped: no signed-in account');
      return false;
    }
    final set = await _getSetFor(uid, _followsKeyFor);
    if (set.contains(userId)) {
      set.remove(userId);
    } else {
      set.add(userId);
    }
    return _setSetFor(uid, _followsKeyFor, set);
  }

  /// Returns false if the spark did not persist. Resolves the account once,
  /// for the same reason as [toggleFollow].
  Future<bool> sendSpark(String userId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('ConnectionService.sendSpark skipped: no signed-in account');
      return false;
    }
    final set = await _getSetFor(uid, _sparksKeyFor);
    set.add(userId);
    return _setSetFor(uid, _sparksKeyFor, set);
  }
}
