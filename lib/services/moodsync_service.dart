import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:trulura/providers/aura_state.dart' show Mood;
import 'package:trulura/services/database_service/database_service.dart';

/// One recorded mood, as stored in `public.mood_states`.
@immutable
class MoodEntry {
  final Mood mood;
  final int? intensity;
  final DateTime recordedAt;

  const MoodEntry({
    required this.mood,
    required this.intensity,
    required this.recordedAt,
  });
}

/// The pattern derived from a run of [MoodEntry]s.
///
/// Deliberately NOT named `AuraPattern`. Per the Product Owner decision in
/// `docs/TruLura_PO_Decision_Aura_Architecture.md`, Aura is the persistent
/// identity model (Layer 1) and its current expression (Layer 2, `AuraState`);
/// Mood is a voluntary, time-limited declaration that feeds *into* Aura State
/// as one input among several. A statistic computed from mood is a mood
/// statistic. Naming it `Aura*` would recreate exactly the one-word-many-objects
/// collision that record exists to prevent.
///
/// This is an input Aura State may consume. It is not Aura.
@immutable
class MoodPattern {
  /// The most frequently recorded mood in the window, or null if no entries.
  final Mood? dominant;

  /// Share of entries in the window matching [dominant], 0.0-1.0.
  ///
  /// High means a settled emotional state; low means the user moved between
  /// moods a lot. Callers decide what to do with that -- this service does not
  /// label anyone as "unstable".
  final double consistency;

  /// How many entries the pattern was derived from. Callers should treat a
  /// small number as weak evidence; the service does not hide that behind an
  /// average.
  final int sampleSize;

  const MoodPattern({
    required this.dominant,
    required this.consistency,
    required this.sampleSize,
  });

  static const MoodPattern empty =
      MoodPattern(dominant: null, consistency: 0, sampleSize: 0);
}

/// Reads and writes the user's mood, and derives a pattern from its history.
///
/// Storage split, confirmed against the live schema rather than assumed:
///
/// - `user_states` (user_id PK, one row per user) is the CURRENT state. It is
///   already live -- app_provider.dart and user_service.dart read `mood_tag`
///   from it -- so this service writes the same column rather than introducing
///   a competing source of truth.
/// - `mood_states` (user_id, mood, intensity, created_at) is the HISTORY.
///
/// `moods` and `mood_events` are deliberately not used: they are keyed by
/// `device_id`, predate auth, and nothing in the app has a device id concept.
class MoodSyncService {
  static const String _currentTable = 'user_states';
  static const String _historyTable = 'mood_states';

  bool get _ready => DatabaseService.instance.isInitialized;

  String? get _uid {
    try {
      return DatabaseService.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static Mood? _moodFromTag(String? tag) {
    final t = (tag ?? '').trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final m in Mood.values) {
      if (m.name == t) return m;
    }
    return null;
  }

  /// Parses a timestamp column into device-local time.
  ///
  /// `mood_states.created_at` is `timestamptz` once
  /// 20260907_moodsync_foundation is applied, in which case PostgREST sends an
  /// explicit offset and this is a plain `toLocal()`. Until then the column is
  /// naive and arrives with no suffix, which `DateTime.parse` would read as
  /// device-local while the server writes UTC. Handling both means this service
  /// is correct either side of that migration.
  static DateTime _parseTimestamp(dynamic raw) {
    final text = raw?.toString() ?? '';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc || RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$').hasMatch(text)) {
      return parsed.toLocal();
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour,
            parsed.minute, parsed.second, parsed.millisecond, parsed.microsecond)
        .toLocal();
  }

  /// Records [mood] as the user's current state and appends it to their history.
  ///
  /// Returns false when there is nothing to write to -- not signed in, or
  /// Supabase unavailable -- so a caller can keep local UI state without
  /// pretending it persisted.
  ///
  /// The two writes are not atomic. The history append is attempted second and
  /// its failure is logged rather than thrown: losing one history row is worth
  /// less than failing a mood change the user already saw take effect. The
  /// current-state write failing IS surfaced, because that is the value every
  /// other feature reads.
  Future<bool> recordMood(Mood mood, {int? intensity}) async {
    if (!_ready) return false;
    final uid = _uid;
    if (uid == null) return false;

    final client = DatabaseService.instance.client;

    try {
      // Matches the update-then-insert shape UserService._persistMood already
      // uses on this table, rather than upsert: user_states has a UNIQUE on
      // user_id, and an upsert would need to name the conflict target and
      // would overwrite active_mode / energy_level defaults on insert.
      final updated = await client
          .from(_currentTable)
          .update({
            'mood_tag': mood.name,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', uid)
          .select('user_id');

      if ((updated as List).isEmpty) {
        await client.from(_currentTable).insert({
          'user_id': uid,
          'active_mode': 'social',
          'mood_tag': mood.name,
          'energy_level': 'medium',
          'low_energy_mode': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('MoodSyncService.recordMood current-state failed: ${e.code} ${e.message}');
      return false;
    }

    try {
      // created_at is deliberately omitted so the column default wins and the
      // timestamp is the server's, not the device's -- the same reason
      // ChatService omits it when inserting messages.
      await client.from(_historyTable).insert({
        'user_id': uid,
        'mood': mood.name,
        if (intensity != null) 'intensity': intensity,
      });
    } on PostgrestException catch (e) {
      debugPrint('MoodSyncService.recordMood history append failed: ${e.code} ${e.message}');
    }

    return true;
  }

  /// The user's current mood, or null if unset or unrecognised.
  Future<Mood?> currentMood() async {
    if (!_ready) return null;
    final uid = _uid;
    if (uid == null) return null;
    try {
      final row = await DatabaseService.instance.client
          .from(_currentTable)
          .select('mood_tag')
          .eq('user_id', uid)
          .maybeSingle();
      return _moodFromTag(row?['mood_tag']?.toString());
    } catch (e) {
      debugPrint('MoodSyncService.currentMood failed: $e');
      return null;
    }
  }

  /// The user's recorded moods, newest first.
  ///
  /// RLS restricts this to the caller's own rows; there is no path here to read
  /// anybody else's emotional history.
  Future<List<MoodEntry>> history({int limit = 60}) async {
    if (!_ready) return const <MoodEntry>[];
    final uid = _uid;
    if (uid == null) return const <MoodEntry>[];
    try {
      final rows = await DatabaseService.instance.client
          .from(_historyTable)
          .select('mood, intensity, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);

      final out = <MoodEntry>[];
      for (final row in (rows as List).whereType<Map<String, dynamic>>()) {
        final mood = _moodFromTag(row['mood']?.toString());
        // Skip rather than guess: a tag that no longer maps to a Mood is a
        // renamed or retired value, and inventing a substitute would corrupt
        // the pattern derived below.
        if (mood == null) continue;
        out.add(MoodEntry(
          mood: mood,
          intensity: row['intensity'] is int ? row['intensity'] as int : null,
          recordedAt: _parseTimestamp(row['created_at']),
        ));
      }
      return out;
    } catch (e) {
      debugPrint('MoodSyncService.history failed: $e');
      return const <MoodEntry>[];
    }
  }

  /// Derives the mood pattern from moods recorded within [window].
  ///
  /// Returns [MoodPattern.empty] when there is nothing in the window. Callers
  /// must handle that rather than treating it as a neutral mood -- "no data"
  /// and "calm" are different states, and conflating them would let a silent
  /// read failure look like a real emotional signal.
  Future<MoodPattern> moodPattern({
    Duration window = const Duration(days: 14),
    int limit = 60,
  }) async {
    final entries = await history(limit: limit);
    final cutoff = DateTime.now().subtract(window);
    final inWindow =
        entries.where((e) => e.recordedAt.isAfter(cutoff)).toList(growable: false);
    if (inWindow.isEmpty) return MoodPattern.empty;

    final counts = <Mood, int>{};
    for (final e in inWindow) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }

    var dominant = inWindow.first.mood;
    var best = 0;
    for (final entry in counts.entries) {
      // Strict > means ties go to whichever mood this loop reaches first.
      // That is Dart Map insertion order, i.e. the order moods first appear in
      // the history rows -- NOT Mood.values order. It is deterministic for a
      // given result set, which is what matters: the alternative is a pattern
      // that flickers between equally-frequent moods on every read.
      if (entry.value > best) {
        best = entry.value;
        dominant = entry.key;
      }
    }

    return MoodPattern(
      dominant: dominant,
      consistency: best / inWindow.length,
      sampleSize: inWindow.length,
    );
  }
}
