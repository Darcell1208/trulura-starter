import 'package:flutter/material.dart';
import 'package:trulura/providers/aura_state.dart';

/// The DR-2 Mood palette: the five confirmed moods, stop-1 -> stop-2.
///
/// Keyed on `enum Mood` deliberately. The older `MoodColors.glow`
/// (`lib/theme/mood_colors.dart`) keys on a *different* vocabulary --
/// cheerful / energetic / calm / romantic / focused / creative -- so four of
/// the five canonical moods fell through to `default: Colors.purpleAccent` and
/// painted an identical dot. Build Status known issue 25 records the
/// measurement. Passing a Mood through a String-keyed switch is what allowed
/// that, so this map takes the enum and the compiler enforces exhaustiveness:
/// a sixth mood becomes a compile error rather than a silent purple.
///
/// The values are Product Owner-confirmed in DR-2
/// (`docs/TruLura_PO_Decision_Record_2026-09-14.md`). Do not edit them to match
/// a screenshot or a design export -- the palette is a Product Owner decision,
/// and these hexes are the record of it.
///
/// Scope caveat, stated rather than hidden: this project already carries
/// several mood-to-colour maps that disagree with each other --
/// `MoodColors.glow`, `AuraStateController.colorForMood`, and
/// `HomeHubScreen._gradientForMood`. This file does not collapse them, and
/// adding it does not reduce that count. It is the DR-2-correct source for the
/// Home mood chip; the consolidation is tracked separately in the Engineering
/// Backlog and is not attempted here.
class MoodPalette {
  const MoodPalette._();

  /// Primary stop. The mood chip's dot uses this.
  static Color stop1(Mood mood) => switch (mood) {
        Mood.reflective => const Color(0xFF8B5CF6),
        Mood.flirty => const Color(0xFFFF4D9D),
        Mood.calm => const Color(0xFF7DD3FC),
        Mood.social => const Color(0xFFFB923C),
        Mood.healing => const Color(0xFF34D399),
      };

  /// Second stop, for gradient treatments that need the pair.
  static Color stop2(Mood mood) => switch (mood) {
        Mood.reflective => const Color(0xFF6366F1),
        Mood.flirty => const Color(0xFFFF7AB8),
        Mood.calm => const Color(0xFF38BDF8),
        Mood.social => const Color(0xFFF59E0B),
        Mood.healing => const Color(0xFF86EFAC),
      };

  /// Parses a stored `mood_tag` into a [Mood], or null when it is absent,
  /// blank, or not one of the five.
  ///
  /// Null means "no mood", and every caller must render that as *no colour*
  /// rather than substituting a fallback. A default here would recreate the
  /// exact bug this file exists to remove: a value nobody chose, painted
  /// confidently enough to be mistaken for data.
  ///
  /// Matching mirrors `MoodSyncService._moodFromTag` -- trimmed, lowercased,
  /// exact enum-name match. That private copy should eventually fold into this
  /// one; until it does, the two must not be allowed to drift apart.
  static Mood? parse(String? tag) {
    final t = (tag ?? '').trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final m in Mood.values) {
      if (m.name == t) return m;
    }
    return null;
  }

  /// Chip-dot colour for a stored tag: null when there is no recognisable
  /// mood, so the caller draws no dot at all.
  static Color? dotFor(String? tag) {
    final mood = parse(tag);
    return mood == null ? null : stop1(mood);
  }
}
