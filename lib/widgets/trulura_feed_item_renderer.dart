import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/feed_item.dart';
import 'package:trulura/widgets/feed_card.dart';
import 'package:trulura/widgets/trulura_boosted_post_card.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';

class TruluraFeedItemRenderer extends StatelessWidget {
  final TruFeedItem item;
  final EdgeInsetsGeometry padding;
  final bool constrainWidth;

  const TruluraFeedItemRenderer({
    super.key,
    required this.item,
    this.padding = EdgeInsets.zero,
    this.constrainWidth = false,
  });

  void _handleDemoTap(BuildContext context, TruDemoFeedItem item) {
    final label = item.actionLabel ?? '';
    if (label.contains('Sync')) {
      context.go(AppRoutes.homeTab('sync'));
    } else if (label.contains('Vent') || label.contains('vent')) {
      context.push(AppRoutes.vent);
    } else if (label.contains('quiz') || label.contains('quizzes')) {
      context.push(AppRoutes.quizLibrary);
    } else if (label.contains('post') || label.contains('Write')) {
      TruNavigation.pushWithReturnTo(context, AppRoutes.createPost);
    } else {
      context.go(AppRoutes.homeTab('explore'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (item) {
      TruPostFeedItem(:final post, :final counts, :final boosted, :final why) =>
        boosted
            ? TruluraBoostedPostCard(
                post: post,
                initialGlowCount: counts.glow,
                initiallyGlowed: counts.glowedByViewer,
                why: why ?? '',
              )
            : FeedCard(
                post: post,
                initialGlowCount: counts.glow,
                initiallyGlowed: counts.glowedByViewer,
                whyAmISeeingThis: why,
              ),
      TruDemoFeedItem(
        :final kind,
        :final title,
        :final body,
        :final chipLabels,
        :final actionLabel,
        :final emphasized,
      ) =>
        TruluraFeedDemoCard(
          kind: kind,
          title: title,
          body: body,
          chips: chipLabels,
          actionLabel: actionLabel,
          emphasized: emphasized,
          onTap: actionLabel == null
              ? null
              : () => _handleDemoTap(context, item as TruDemoFeedItem),
        ),
    };

    final wrapped = Padding(padding: padding, child: child);
    return constrainWidth ? TruluraFeedLane(child: wrapped) : wrapped;
  }
}
