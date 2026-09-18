import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trulura/widgets/feed_card_presentation.dart';
import 'package:trulura/widgets/trulura_safe_avatar.dart';

enum FeedMoodIndicator { ring, dot }

/// Three sections only: single-line identity, bounded preview, inline actions.
/// Sizes are caller-owned; content length never adds another row.
class CompactFeedCardPresentation extends FeedCardPresentation {
  final double avatarDiameter, ringWidth, nameSize, vibeSize, textSize;
  final int previewLines;
  final FeedMoodIndicator moodIndicator;
  const CompactFeedCardPresentation(
      {this.avatarDiameter = 40,
      this.ringWidth = 2,
      this.nameSize = 15,
      this.vibeSize = 11,
      this.textSize = 15,
      this.previewLines = 2,
      this.moodIndicator = FeedMoodIndicator.ring});

  @override
  bool get showPromotionBadge => false;

  @override
  Widget build(BuildContext context, FeedCardPresentationData data) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF0EFF8) : const Color(0xFF242033);
    final muted = dark ? const Color(0xFFB0ADC4) : const Color(0xFF625D73);
    final scale = MediaQuery.textScalerOf(context);
    // Null or blank means the post has no mood to show. The chip is omitted
    // entirely rather than rendered empty: a bare pill still reads as "there
    // is something here", which is the impression known issue 24 was about.
    final rawVibe = data.vibe?.trim();
    final moodLabel = (rawVibe == null || rawVibe.isEmpty) ? null : rawVibe;
    // Same rule for the name: no name, no text. Known issue 31.
    final rawName = data.name?.trim();
    final nameLabel = (rawName == null || rawName.isEmpty) ? null : rawName;
    final textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: textSize,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: ink);
    return Container(
        key: const ValueKey('compact-feed-card'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
            color: dark ? const Color(0xFF19172B) : const Color(0xFFF8F7FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    dark ? const Color(0xFF302B46) : const Color(0xFFE4DFED))),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: math.max(avatarDiameter, scale.scale(nameSize) * 1.3),
                  child: Row(children: [
                    Semantics(
                        label: 'View ${data.name} profile',
                        button: data.onProfile != null,
                        child: GestureDetector(
                            onTap: data.onProfile,
                            child: Container(
                                key: const ValueKey('compact-mood-ring'),
                                width: avatarDiameter,
                                height: avatarDiameter,
                                padding: EdgeInsets.all(ringWidth),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        moodIndicator == FeedMoodIndicator.ring
                                            ? data.auraColor
                                            : Colors.transparent),
                                child: TruLuraSafeAvatar(
                                    radius:
                                        (avatarDiameter - 2 * ringWidth) / 2,
                                    image: data.avatar,
                                    backgroundColor: dark
                                        ? const Color(0xFF353047)
                                        : const Color(0xFFE6E1EE),
                                    fallback: Icon(Icons.person_outline,
                                        size: 23, color: muted))))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Row(children: [
                      if (moodIndicator == FeedMoodIndicator.dot) ...[
                        Container(
                            key: const ValueKey('compact-mood-dot'),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: data.auraColor)),
                        const SizedBox(width: 5),
                      ],
                      if (nameLabel != null)
                        Flexible(
                            child: GestureDetector(
                                onTap: data.onProfile,
                                child: Text(nameLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                            fontSize: nameSize,
                                            fontWeight: FontWeight.w500,
                                            color: ink)))),
                      // Mood chip: neutral pill, coloured dot, mood name. The
                      // ring is brand glow; this is the only mood carrier, and
                      // the name means it still reads without colour. No mood,
                      // no chip -- and no spacer either, so the row closes up.
                      if (moodLabel != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                          child: Container(
                              key: const ValueKey('compact-mood-chip'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF262238)
                                      : const Color(0xFFEDE9F3),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (data.moodColor != null) ...[
                                      Container(
                                          key: const ValueKey(
                                              'compact-mood-chip-dot'),
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: data.moodColor)),
                                      const SizedBox(width: 5),
                                    ],
                                    Flexible(
                                        child: Text(moodLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall!
                                                .copyWith(
                                                    fontSize: vibeSize,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: muted))),
                                  ]))),
                      ],
                    ])),
                    SizedBox(
                        width: 32,
                        height: 40,
                        child: IconButton(
                            tooltip: 'More',
                            padding: EdgeInsets.zero,
                            onPressed: data.onMore,
                            icon: Icon(Icons.more_horiz,
                                size: 20, color: muted))),
                  ])),
              const SizedBox(height: 10),
              SizedBox(
                  height: scale.scale(textSize) * 1.4 * previewLines,
                  child: Text(data.text,
                      key: const ValueKey('compact-preview'),
                      maxLines: previewLines,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle)),
              const SizedBox(height: 6),
              LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                      width: math.min(272, constraints.maxWidth),
                      height: 44,
                      child: Row(
                          key: const ValueKey('compact-actions'),
                          children: [
                            for (final action in data.actions)
                              Expanded(
                                  child: Semantics(
                                      button: true,
                                      enabled: action.onTap != null,
                                      label: '${action.label}, ${action.count}',
                                      child: Tooltip(
                                          message: action.label,
                                          child: InkWell(
                                              onTap: action.onTap,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SizedBox(
                                                  height: 44,
                                                  child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8),
                                                          child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                        action
                                                                            .icon,
                                                                        size:
                                                                            18,
                                                                        color: action.onTap ==
                                                                                null
                                                                            ? muted.withValues(alpha: 0.35)
                                                                            : action.selected
                                                                                ? data.auraColor
                                                                                : muted),
                                                                    const SizedBox(
                                                                        width:
                                                                            5),
                                                                    Text(
                                                                        _count(action
                                                                            .count),
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .labelMedium!
                                                                            .copyWith(
                                                                                fontSize: 12,
                                                                                color: action.onTap == null ? muted.withValues(alpha: 0.35) : muted)),
                                                                  ]))))))))),
                          ]))),
            ]));
  }

  static String _count(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }
}
