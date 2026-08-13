import 'package:flutter/foundation.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';

enum TruFeedPostType {
  text,
  image,
  video,
  quote,
  recommendation,
  quiz,
  supportPrompt,
  communityDiscussion,
  compatibilitySuggestion,
  repost,
  unknown;

  static TruFeedPostType fromPost(Post post) {
    final type = post.type.trim().toLowerCase();
    final category = post.category.trim().toLowerCase();
    if (category.contains('quiz')) {
      return TruFeedPostType.quiz;
    }
    if (category.contains('recommend')) {
      return TruFeedPostType.recommendation;
    }
    if (category.contains('compat')) {
      return TruFeedPostType.compatibilitySuggestion;
    }
    if (category.contains('community')) {
      return TruFeedPostType.communityDiscussion;
    }
    if (category.contains('repost') || category.contains('share')) {
      return TruFeedPostType.repost;
    }
    if (type == 'image') {
      return TruFeedPostType.image;
    }
    if (type == 'video') {
      return TruFeedPostType.video;
    }
    if (type == 'quote' || post.textStyle == 'editorial') {
      return TruFeedPostType.quote;
    }
    if (type == 'text' || type == 'general') {
      return TruFeedPostType.text;
    }
    return TruFeedPostType.unknown;
  }
}

enum TruFeedVisibility {
  public,
  followers,
  private,
  anonymous,
  placeholder;

  static TruFeedVisibility fromPost(Post post) {
    if (post.isAnonymous) return TruFeedVisibility.anonymous;
    return switch (post.privacy.trim().toLowerCase()) {
      'private' => TruFeedVisibility.private,
      'followers' || 'friends' => TruFeedVisibility.followers,
      'public' => TruFeedVisibility.public,
      _ => TruFeedVisibility.public,
    };
  }
}

@immutable
class TruVibeTag {
  final String label;
  final bool primary;

  const TruVibeTag(this.label, {this.primary = false});
}

@immutable
class TruFeedInteractionCounts {
  final int glow;
  final int reactions;
  final int comments;
  final int shares;
  final bool glowedByViewer;

  const TruFeedInteractionCounts({
    this.glow = 0,
    this.reactions = 0,
    this.comments = 0,
    this.shares = 0,
    this.glowedByViewer = false,
  });

  factory TruFeedInteractionCounts.fromPost(
    Post post, {
    int? glowCount,
    bool glowedByViewer = false,
  }) {
    return TruFeedInteractionCounts(
      glow: glowCount ?? post.likeCount,
      reactions: post.likeCount,
      comments: post.commentCount,
      shares: post.shareCount,
      glowedByViewer: glowedByViewer,
    );
  }
}

sealed class TruFeedItem {
  final String id;

  const TruFeedItem({required this.id});
}

class TruPostFeedItem extends TruFeedItem {
  final Post post;
  final TruFeedPostType postType;
  final TruFeedVisibility visibility;
  final List<TruVibeTag> vibeTags;
  final TruFeedInteractionCounts counts;
  final String? why;
  final bool boosted;

  TruPostFeedItem({
    required this.post,
    this.why,
    this.boosted = false,
    TruFeedInteractionCounts? counts,
    List<TruVibeTag>? vibeTags,
  })  : postType = TruFeedPostType.fromPost(post),
        visibility = TruFeedVisibility.fromPost(post),
        counts = counts ?? TruFeedInteractionCounts.fromPost(post),
        vibeTags = vibeTags ??
            [
              if ((post.moodTag ?? '').trim().isNotEmpty)
                TruVibeTag(post.moodTag!.trim(), primary: true),
            ],
        super(id: post.id.isEmpty ? 'local-${post.hashCode}' : post.id);
}

class TruDemoFeedItem extends TruFeedItem {
  final TruluraFeedDemoCardKind kind;
  final String title;
  final String body;
  final List<TruVibeTag> vibeTags;
  final String? actionLabel;
  final bool emphasized;

  const TruDemoFeedItem({
    required super.id,
    required this.kind,
    required this.title,
    required this.body,
    this.vibeTags = const <TruVibeTag>[],
    this.actionLabel,
    this.emphasized = false,
  });

  List<String> get chipLabels => vibeTags.map((tag) => tag.label).toList();
}
