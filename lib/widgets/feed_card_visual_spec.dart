import 'package:trulura/widgets/feed_card_presentation.dart';
import 'package:flutter/material.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_icon.dart';

/// Immutable card appearance, independent of the screen displaying it.
///
/// [fromPost] preserves the existing appearance derivation. Feed-lane width,
/// staggered margins, and list offsets remain the caller's responsibility.
@immutable
class FeedCardVisualSpec {
  final FeedCardPresentation? presentation;
  final String label;
  final TruLuraGlyph glyph;
  final Color accentA;
  final Color accentB;
  final double radius;
  final double leftInset;
  final double topLift;
  final double bottomBreath;
  final int seed;
  final double emotionalWeight;
  final double motionTempo;
  final double floatRange;
  final double compression;
  final double gravity;

  const FeedCardVisualSpec({
    this.presentation,
    required this.label,
    required this.glyph,
    required this.accentA,
    required this.accentB,
    required this.radius,
    required this.leftInset,
    required this.topLift,
    required this.bottomBreath,
    required this.seed,
    required this.emotionalWeight,
    required this.motionTempo,
    required this.floatRange,
    required this.compression,
    this.gravity = 0.34,
  });

  FeedCardVisualSpec withPresentation(FeedCardPresentation value,
          {Color? accentB}) =>
      FeedCardVisualSpec(
          presentation: value,
          label: label,
          glyph: glyph,
          accentA: accentA,
          accentB: accentB ?? this.accentB,
          radius: radius,
          leftInset: leftInset,
          topLift: topLift,
          bottomBreath: bottomBreath,
          seed: seed,
          emotionalWeight: emotionalWeight,
          motionTempo: motionTempo,
          floatRange: floatRange,
          compression: compression,
          gravity: gravity);

  bool get hasTypeLabel => label.isNotEmpty;

  static FeedCardVisualSpec fromPost(Post post, TruLuraMode mode) {
    final p = kTruLuraPalettes[mode]!;
    final category = post.category.toLowerCase();
    final type = post.type.toLowerCase();
    final mood = (post.moodTag ?? '').toLowerCase();
    final seed = '${post.id}|${post.userId}|${post.content}'.hashCode.abs();
    final gravity = _gravityFor(post);

    if (mood.contains('flirt') ||
        mood.contains('romance') ||
        mood.contains('spark') ||
        mood.contains('crush')) {
      return FeedCardVisualSpec(
        label: 'Warm signal',
        glyph: TruLuraGlyph.heartOutline,
        accentA: TruLuraTokens.auraPink,
        accentB: TruLuraBrandColors.syncRose,
        radius: 30,
        leftInset: seed.isEven ? 2 : 5,
        topLift: 1,
        bottomBreath: 9,
        seed: seed,
        emotionalWeight: 0.68,
        motionTempo: 1.12,
        floatRange: 1.2,
        compression: 0.84,
        gravity: gravity,
      );
    }
    if (mood.contains('reflect') ||
        mood.contains('ground') ||
        mood.contains('old soul') ||
        mood.contains('quiet')) {
      return FeedCardVisualSpec(
        label: 'Reflective note',
        glyph: TruLuraGlyph.moon,
        accentA: TruLuraTokens.auraViolet,
        accentB: TruLuraBrandColors.neonBlue,
        radius: 29,
        leftInset: seed.isEven ? 0 : 4,
        topLift: 5,
        bottomBreath: 10,
        seed: seed,
        emotionalWeight: 0.82,
        motionTempo: 0.62,
        floatRange: 0.7,
        compression: 1.06,
        gravity: gravity,
      );
    }
    if (mood.contains('social') ||
        mood.contains('radiant') ||
        mood.contains('party') ||
        mood.contains('community')) {
      return FeedCardVisualSpec(
        label: 'Social wave',
        glyph: TruLuraGlyph.groups,
        accentA: TruLuraTokens.auraCyan,
        accentB: TruLuraTokens.auraPink,
        radius: 28,
        leftInset: seed.isEven ? 6 : 1,
        topLift: 0,
        bottomBreath: 8,
        seed: seed,
        emotionalWeight: 0.58,
        motionTempo: 1.18,
        floatRange: 1.5,
        compression: 0.76,
        gravity: gravity,
      );
    }
    if (post.contentType == TruPostContentType.support ||
        post.isAnonymous ||
        mood.contains('heal') ||
        mood.contains('calm') ||
        category.contains('support') ||
        category.contains('vent')) {
      return FeedCardVisualSpec(
        label: post.isAnonymous ? 'Soft check-in' : 'Support note',
        glyph: TruLuraGlyph.moon,
        accentA: TruLuraTokens.auraCyan,
        accentB: TruLuraBrandColors.neonPurple,
        radius: 30,
        leftInset: 2,
        topLift: 6,
        bottomBreath: 10,
        seed: seed,
        emotionalWeight: 0.92,
        motionTempo: 0.48,
        floatRange: 0.5,
        compression: category.contains('vent') ? 1.34 : 1.10,
        gravity: gravity,
      );
    }
    if (post.contentType == TruPostContentType.creator ||
        post.isCreatorContent ||
        category.contains('creator') ||
        category.contains('luxe') ||
        type == 'image' ||
        type == 'video') {
      return FeedCardVisualSpec(
        label: category.contains('luxe')
            ? 'Luxe signal'
            : type == 'video'
                ? 'Creator drop'
                : 'Visual aura',
        glyph: type == 'video' ? TruLuraGlyph.video : TruLuraGlyph.image,
        accentA: category.contains('luxe')
            ? TruLuraBrandColors.glowGold
            : TruLuraTokens.auraPink,
        accentB: TruLuraTokens.auraCyan,
        radius: 30,
        leftInset: seed.isEven ? 0 : 3,
        topLift: 0,
        bottomBreath: 8,
        seed: seed,
        emotionalWeight: category.contains('luxe') ? 0.72 : 0.60,
        motionTempo: category.contains('luxe') ? 0.58 : 1.05,
        floatRange: category.contains('luxe') ? 0.6 : 1.3,
        compression: category.contains('luxe') ? 0.92 : 0.78,
        gravity: gravity,
      );
    }
    if (category.contains('quiz') ||
        category.contains('prompt') ||
        category.contains('compat')) {
      return FeedCardVisualSpec(
        label: 'Aura prompt',
        glyph: TruLuraGlyph.insights,
        accentA: TruLuraBrandColors.glowGold,
        accentB: p.glowB,
        radius: 26,
        leftInset: 4,
        topLift: 4,
        bottomBreath: 7,
        seed: seed,
        emotionalWeight: 0.70,
        motionTempo: 0.82,
        floatRange: 0.9,
        compression: 0.96,
        gravity: gravity,
      );
    }
    if (category.contains('community') || category.contains('discussion')) {
      return FeedCardVisualSpec(
        label: 'Conversation starter',
        glyph: TruLuraGlyph.groups,
        accentA: TruLuraTokens.auraCyan,
        accentB: p.glowA,
        radius: 27,
        leftInset: 0,
        topLift: 2,
        bottomBreath: 6,
        seed: seed,
        emotionalWeight: 0.52,
        motionTempo: 1.10,
        floatRange: 1.1,
        compression: 0.82,
        gravity: gravity,
      );
    }
    if (category.contains('repost') || category.contains('thread')) {
      return FeedCardVisualSpec(
        label: category.contains('thread') ? 'Threaded reply' : 'Repost aura',
        glyph: category.contains('thread')
            ? TruLuraGlyph.messages
            : TruLuraGlyph.share,
        accentA: TruLuraTokens.auraCyan,
        accentB: TruLuraTokens.auraViolet,
        radius: 26,
        leftInset: 5,
        topLift: 5,
        bottomBreath: 9,
        seed: seed,
        emotionalWeight: 0.76,
        motionTempo: 0.72,
        floatRange: 0.8,
        compression: 1.02,
        gravity: gravity,
      );
    }
    if (category.contains('music') || category.contains('audio')) {
      return FeedCardVisualSpec(
        label: category.contains('audio') ? 'Audio mood' : 'Music-linked',
        glyph: TruLuraGlyph.tv,
        accentA: TruLuraTokens.auraPink,
        accentB: TruLuraBrandColors.glowGold,
        radius: 30,
        leftInset: 1,
        topLift: 2,
        bottomBreath: 8,
        seed: seed,
        emotionalWeight: 0.64,
        motionTempo: 1.0,
        floatRange: 1.1,
        compression: 0.88,
        gravity: gravity,
      );
    }
    return FeedCardVisualSpec(
      label: mood.isEmpty ? 'Aura note' : 'Mood post',
      glyph: TruLuraGlyph.spark,
      accentA: p.glowA,
      accentB: p.glowB,
      radius: 28,
      leftInset: seed.isEven ? 0 : 2,
      topLift: seed % 3 == 0 ? 4 : 0,
      bottomBreath: 6,
      seed: seed,
      emotionalWeight: 0.58,
      motionTempo: 0.86,
      floatRange: 0.8,
      compression: 0.90,
      gravity: gravity,
    );
  }

  static double _gravityFor(Post post) {
    final text =
        '${post.category} ${post.moodTag ?? ''} ${post.content}'.toLowerCase();
    var gravity = post.emotionalIntensityScore.clamp(0, 100) / 100.0 * 0.72;
    if (text.contains('confess') ||
        text.contains('vulnerable') ||
        text.contains('healing') ||
        text.contains('milestone') ||
        text.contains('memory') ||
        text.contains('reconnect')) {
      gravity += 0.20;
    }
    if (post.isAnonymous || post.contentType == TruPostContentType.support) {
      gravity += 0.14;
    }
    return gravity.clamp(0.0, 1.0);
  }
}
