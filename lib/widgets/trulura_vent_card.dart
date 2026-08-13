import 'package:flutter/material.dart';
import 'package:trulura/models/feed_item.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';

/// Back-compat wrapper. Vent now renders through the shared feed/post system.
class TruluraVentCard extends StatelessWidget {
  final Post post;
  final bool anonymous;

  const TruluraVentCard({
    super.key,
    required this.post,
    this.anonymous = true,
  });

  @override
  Widget build(BuildContext context) {
    return TruluraFeedItemRenderer(
      item: TruPostFeedItem(
        post: post.copyWith(isAnonymous: anonymous || post.isAnonymous),
        why: 'Vent Space keeps identity private and suppresses viral framing.',
      ),
    );
  }
}
