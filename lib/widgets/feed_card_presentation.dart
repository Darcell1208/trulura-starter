import 'package:flutter/material.dart';

/// Caller-owned structure. Null on FeedCardVisualSpec retains the legacy tree.
abstract class FeedCardPresentation {
  const FeedCardPresentation();
  bool get showPromotionBadge => true;
  Widget build(BuildContext context, FeedCardPresentationData data);
}

class FeedCardAction {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback? onTap;
  const FeedCardAction(
      {required this.icon,
      required this.label,
      required this.count,
      this.selected = false,
      required this.onTap});
}

/// State and callbacks remain owned by FeedCard; presentations only render them.
///
/// [auraColor] is the avatar ring: brand glow, injected through the visual
/// spec. It does not carry mood. Mood is carried by the header chip, whose dot
/// is [moodColor] -- null when the post has no mood tag, in which case no dot
/// is drawn rather than a guessed colour.
class FeedCardPresentationData {
  final String name, vibe, text;
  final Color auraColor;
  final Color? moodColor;
  final ImageProvider<Object>? avatar;
  final VoidCallback? onProfile;
  final VoidCallback onMore;
  final List<FeedCardAction> actions;
  const FeedCardPresentationData(
      {required this.name,
      required this.vibe,
      required this.text,
      required this.auraColor,
      this.moodColor,
      required this.avatar,
      required this.onProfile,
      required this.onMore,
      required this.actions});
}
