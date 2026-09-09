import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// What a one-time local-block migration actually did.
///
/// Every count is reported rather than summed into a single "ok" so a caller --
/// and a log line -- can tell the difference between "nothing to do" and
/// "three blocks were dropped because those accounts no longer exist".
@immutable
class BlockMigrationOutcome {
  /// Rows newly written to `public.blocks`.
  final int migrated;

  /// Rows already present on the server. Not an error: the unique index on
  /// (user_id, blocked_user_id) makes re-running this harmless.
  final int alreadyPresent;

  /// Local entries that were not UUIDs at all, so never referenced a real
  /// person. Feed demo content uses ids like 'local' and
  /// 'profile-vibe-update', and the block action is reachable from any feed
  /// card, so these are expected rather than corrupt.
  final int droppedMalformed;

  /// Local entries that were well-formed UUIDs with no matching `profiles`
  /// row -- an account that has since been deleted.
  final int droppedMissingUser;

  /// Entries that failed for a reason this code does not understand
  /// (offline, transport, an unexpected Postgres error). Non-zero means the
  /// migration did NOT complete and will be retried on the next launch.
  final int failed;

  const BlockMigrationOutcome({
    this.migrated = 0,
    this.alreadyPresent = 0,
    this.droppedMalformed = 0,
    this.droppedMissingUser = 0,
    this.failed = 0,
  });

  /// True when every local entry reached a definite resolution, so the marker
  /// can be set and the migration never needs to run again for this account.
  bool get isComplete => failed == 0;

  int get considered =>
      migrated + alreadyPresent + droppedMalformed + droppedMissingUser + failed;

  @override
  String toString() => 'BlockMigrationOutcome(migrated: $migrated, '
      'alreadyPresent: $alreadyPresent, droppedMalformed: $droppedMalformed, '
      'droppedMissingUser: $droppedMissingUser, failed: $failed)';
}

/// Blocks, backed by `public.blocks`.
///
/// Replaces the block half of [ReportingService], which stored blocks in a
/// device-global `SharedPreferences` key. That made a block a property of one
/// installation: reinstall or sign in on a second device and every block was
/// gone. The server table is now the source of truth.
///
/// ## What a block does and does not do
///
/// After Feature 5 phase 2 a block is durable and private to its owner --
/// `blocks_select_by_owner` means the blocked person cannot see that they were
/// blocked. It does NOT yet stop them from messaging: `messages` and
/// `conversations` RLS do not consult this table. Enforcement is phase 3, held
/// until persistence is verified in the running app. Until then the only thing
/// stopping an interaction is the client-side checks in
/// chat_thread_screen.dart and trulura_profile_preview_sheet.dart. Do not
/// describe blocking as enforced before phase 3 lands.
///
/// ## Local storage, after the migration
///
/// Three local keys are involved, and none is authoritative:
///
/// - [_legacyLocalKey] is the pre-migration set. It is consumed -- moved, not
///   deleted -- by the first account that migrates successfully.
/// - [_legacyClaimedKeyPrefix] + uid is where that list is moved to. Keeping it
///   means a botched migration stays recoverable; moving it means no second
///   account can import the same blocks.
/// - [_cacheKeyPrefix] + uid is a read-through cache of the server set, so an
///   offline launch still knows who is blocked. It is only ever written from a
///   server response.
class BlockService {
  static const String _table = 'blocks';

  /// The pre-Supabase key written by the old ReportingService.
  ///
  /// This key is NOT namespaced by account -- it predates auth. On a device
  /// where two accounts have signed in, it holds both users' blocks commingled
  /// with no way to tell them apart. That much is inherent to the data.
  ///
  /// What is not inherent, and what an earlier version of this file got wrong:
  /// a per-uid completion marker alone does NOT stop the list being imported
  /// more than once. The marker only records that *this* account has run the
  /// migration. Account B signing in on the same device finds no marker of its
  /// own, reads the same untouched key, and imports account A's blocks as its
  /// own -- silently telling B it has blocked people it has never met.
  ///
  /// So the list is consumed, not merely read: on the first successful
  /// migration it is moved to [_legacyClaimedKeyPrefix] + uid and removed from
  /// here. Moving rather than deleting keeps a botched migration recoverable,
  /// which is why this is not a plain `remove`.
  static const String _legacyLocalKey = 'safety_blocks_v1';

  /// Where the legacy list goes once an account has claimed it. Nothing reads
  /// this; it exists so the data survives for manual recovery.
  static const String _legacyClaimedKeyPrefix = 'safety_blocks_legacy_claimed_v1_';

  static const String _cacheKeyPrefix = 'safety_blocks_cache_v1_';

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Postgres SQLSTATEs this service interprets rather than merely logs.
  static const String _uniqueViolation = '23505';
  static const String _foreignKeyViolation = '23503';

  bool get _ready => DatabaseService.instance.isInitialized;

  String? get _uid {
    try {
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static String _markerKey(String uid) => 'safety_blocks_migrated_v1_$uid';

  static String _cacheKey(String uid) => '$_cacheKeyPrefix$uid';

  /// The ids this user has blocked.
  ///
  /// Falls back to the local cache when the server cannot be reached, so a
  /// block keeps working offline. Returns an empty set when signed out --
  /// blocks belong to an account, and there is no account to read them for.
  Future<Set<String>> blockedUserIds() async {
    final uid = _uid;
    if (!_ready || uid == null) return <String>{};

    try {
      final rows = await DatabaseService.instance.client
          .from(_table)
          .select('blocked_user_id')
          .eq('user_id', uid);

      final ids = (rows as List)
          .map((row) => row['blocked_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      await _writeCache(uid, ids);
      return ids;
    } catch (e) {
      debugPrint('BlockService.blockedUserIds failed, using cache: $e');
      return _readCache(uid);
    }
  }

  Future<bool> isBlocked(String userId) async =>
      (await blockedUserIds()).contains(userId);

  /// Blocks [userId]. Returns false when the block did not persist.
  ///
  /// A caller that gets false must not tell the user they were blocked. The
  /// old local implementation could not fail, so every call site assumed
  /// success; that assumption stops being safe the moment this is a network
  /// write.
  ///
  /// An already-blocked user counts as success -- the unique index rejects the
  /// duplicate, but the user's intent ("this person is blocked") holds either
  /// way.
  Future<bool> blockUser(String userId) async {
    final uid = _uid;
    if (!_ready || uid == null) return false;

    final target = userId.trim();
    if (!_uuid.hasMatch(target)) {
      // Hashed: who you tried to block is exactly what blocks_select_by_owner
      // exists to keep private, and a raw id here would put it in the console.
      debugPrint('BlockService.blockUser refused non-uuid target: '
          '${redactedId(target)}');
      return false;
    }
    if (target == uid) {
      debugPrint('BlockService.blockUser refused self-block');
      return false;
    }

    try {
      await DatabaseService.instance.client
          .from(_table)
          .insert({'user_id': uid, 'blocked_user_id': target});
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolation) {
        await _addToCache(uid, target);
        return true;
      }
      debugPrint('BlockService.blockUser failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BlockService.blockUser failed: $e');
      return false;
    }

    await _addToCache(uid, target);
    return true;
  }

  /// Unblocks [userId]. Returns false when the removal did not persist.
  Future<bool> unblockUser(String userId) async {
    final uid = _uid;
    if (!_ready || uid == null) return false;

    try {
      await DatabaseService.instance.client
          .from(_table)
          .delete()
          .eq('user_id', uid)
          .eq('blocked_user_id', userId.trim());
    } catch (e) {
      debugPrint('BlockService.unblockUser failed: $e');
      return false;
    }

    await _removeFromCache(uid, userId.trim());
    return true;
  }

  /// Moves this device's pre-Supabase blocks onto the server, once per account.
  ///
  /// Safe to call on every launch: it returns immediately once the per-uid
  /// marker is set, and the unique index makes a partial re-run idempotent.
  ///
  /// The marker is written only when every entry reached a definite outcome.
  /// An offline launch therefore leaves the migration pending rather than
  /// silently discarding blocks it could not write -- these are real decisions
  /// a person made about their own safety, and losing one to a dropped
  /// connection is not an acceptable failure mode.
  ///
  /// Rows are written one at a time rather than as a batch. A batch insert
  /// fails as a unit, so one stale id would take the whole set down with it;
  /// per-row writes let each entry succeed or be classified on its own. Local
  /// block sets are small, so the extra round trips cost little.
  Future<BlockMigrationOutcome> migrateLocalBlocksIfNeeded() async {
    final uid = _uid;
    if (!_ready || uid == null) return const BlockMigrationOutcome();

    SharedPreferences? maybePrefs;
    try {
      maybePrefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('BlockService.migrateLocalBlocksIfNeeded prefs failed: $e');
    }
    if (maybePrefs == null) return const BlockMigrationOutcome(failed: 1);
    final prefs = maybePrefs;

    if (prefs.getBool(_markerKey(uid)) ?? false) {
      return const BlockMigrationOutcome();
    }

    final local = _readLegacyLocal(prefs);
    if (local.isEmpty) {
      await prefs.setBool(_markerKey(uid), true);
      return const BlockMigrationOutcome();
    }

    var migrated = 0;
    var alreadyPresent = 0;
    var droppedMalformed = 0;
    var droppedMissingUser = 0;
    var failed = 0;

    final client = DatabaseService.instance.client;

    for (final raw in local) {
      final target = raw.trim();

      // Never referenced a person: demo-content ids, 'local', leftovers.
      if (!_uuid.hasMatch(target)) {
        droppedMalformed++;
        continue;
      }

      // A self-block cannot exist server-side (blocks_no_self_block) and means
      // nothing anyway. Counted as malformed rather than failed.
      if (target == uid) {
        droppedMalformed++;
        continue;
      }

      try {
        await client
            .from(_table)
            .insert({'user_id': uid, 'blocked_user_id': target});
        migrated++;
      } on PostgrestException catch (e) {
        switch (e.code) {
          case _uniqueViolation:
            alreadyPresent++;
            break;
          case _foreignKeyViolation:
            // The blocked account no longer has a profiles row. No server row
            // is needed: blocks_blocked_user_id_fkey is ON DELETE CASCADE, so
            // the schema already treats "profile deleted" as "block gone", and
            // a deleted account cannot interact with anyone. The decision
            // itself survives under the claimed-legacy key for this account.
            droppedMissingUser++;
            break;
          default:
            debugPrint('BlockService migration row failed: ${e.code} ${e.message}');
            failed++;
        }
      } catch (e) {
        debugPrint('BlockService migration row failed: $e');
        failed++;
      }
    }

    final outcome = BlockMigrationOutcome(
      migrated: migrated,
      alreadyPresent: alreadyPresent,
      droppedMalformed: droppedMalformed,
      droppedMissingUser: droppedMissingUser,
      failed: failed,
    );

    if (outcome.isComplete) {
      // Claim BEFORE marking done, and only mark done if the claim landed.
      //
      // The reverse order reopened the bug this migration exists to close: if
      // the process died between setting the marker and consuming the legacy
      // key, this account would never run again -- the marker says done -- and
      // safety_blocks_v1 would still be sitting there for the next account to
      // import as its own. The marker records that the work happened; the
      // claim IS the work, so the claim goes first.
      //
      // Failing to claim now leaves the marker unset and the whole migration
      // re-runs next launch. That is cheap and safe: every insert is idempotent
      // against the unique index on (user_id, blocked_user_id), so a re-run
      // reports the rows as alreadyPresent rather than duplicating them.
      if (await _claimLegacyLocal(prefs, uid, local)) {
        await prefs.setBool(_markerKey(uid), true);
      }
    }

    debugPrint('BlockService.migrateLocalBlocksIfNeeded: $outcome');
    return outcome;
  }

  /// Moves the legacy list out of the device-global key and under [uid].
  ///
  /// Called only after a fully successful migration. Until this runs the key
  /// stays put, so an interrupted migration re-reads it on the next launch
  /// rather than losing it.
  ///
  /// The move is write-then-remove, in that order: if the process dies between
  /// the two, the list exists in both places and the next launch re-imports it
  /// into the same account, which the unique index makes a no-op. The reverse
  /// order could lose it entirely.
  /// Returns false if the legacy key could not be consumed.
  ///
  /// The caller must not set the completion marker on false: the blocks are
  /// already safe on the server, but the shared list is still sitting there for
  /// another account to claim, and only a re-run can clear it.
  Future<bool> _claimLegacyLocal(
      SharedPreferences prefs, String uid, Set<String> claimed) async {
    try {
      await prefs.setString('$_legacyClaimedKeyPrefix$uid',
          jsonEncode(claimed.toList(growable: false)));
      await prefs.remove(_legacyLocalKey);
      return true;
    } catch (e) {
      debugPrint('BlockService._claimLegacyLocal failed: $e');
      return false;
    }
  }

  Set<String> _readLegacyLocal(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_legacyLocalKey);
      if (raw == null) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (e) {
      debugPrint('BlockService._readLegacyLocal failed: ${safeError(e)}');
      return <String>{};
    }
  }

  Future<Set<String>> _readCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(uid));
      if (raw == null) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (e) {
      debugPrint('BlockService._readCache failed: ${safeError(e)}');
      return <String>{};
    }
  }

  Future<void> _writeCache(String uid, Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey(uid), jsonEncode(ids.toList(growable: false)));
    } catch (e) {
      debugPrint('BlockService._writeCache failed: $e');
    }
  }

  Future<void> _addToCache(String uid, String id) async {
    final ids = await _readCache(uid);
    ids.add(id);
    await _writeCache(uid, ids);
  }

  Future<void> _removeFromCache(String uid, String id) async {
    final ids = await _readCache(uid);
    ids.remove(id);
    await _writeCache(uid, ids);
  }
}
