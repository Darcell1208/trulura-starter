import 'package:trulura/models/feed_item.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/profile/quiz_result.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';

class FeedDemoContentService {
  const FeedDemoContentService();

  List<TruFeedItem> profileItems({
    required User? user,
    required List<Post> posts,
    required List<TruQuizResult> quizResults,
  }) {
    final items = <TruFeedItem>[
      ...posts.map((post) => TruPostFeedItem(post: post)),
    ];

    final vibe = (user?.vibeLabel.label ?? '').trim();
    final expression = (user?.expressionShortPost ?? '').trim();
    if (expression.isNotEmpty) {
      items.add(
        TruPostFeedItem(
          post: Post(
            id: 'profile-expression-${user?.id ?? 'local'}',
            userId: user?.id ?? 'local',
            user: user,
            content: expression,
            type: 'quote',
            textStyle: 'editorial',
            backgroundColorHex: '#1A1B3F',
            moodTag: vibe.isEmpty ? null : vibe,
            privacy: 'public',
            category: 'Vibe',
            likeCount: 7,
            commentCount: 2,
            shareCount: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          why:
              'Profile expression rendered as part of the living identity feed.',
        ),
      );
    } else if (vibe.isNotEmpty) {
      items.add(
        TruDemoFeedItem(
          id: 'profile-vibe-update',
          kind: TruluraFeedDemoCardKind.conversation,
          title: 'Vibe update',
          body:
              '$vibe energy is shaping this profile. The next reflections will gather here as the story deepens.',
          vibeTags: [
            TruVibeTag(vibe, primary: true),
            const TruVibeTag('status'),
            const TruVibeTag('profile'),
          ],
          emphasized: posts.isEmpty,
        ),
      );
    }

    final visibleQuiz = quizResults
        .where((result) => result.isPublic)
        .cast<TruQuizResult?>()
        .firstOrNull;
    if (visibleQuiz != null) {
      items.add(
        TruDemoFeedItem(
          id: 'profile-quiz-${visibleQuiz.quizId}',
          kind: TruluraFeedDemoCardKind.quiz,
          title: 'Shared quiz result',
          body: visibleQuiz.resultSummary ??
              'A saved quiz result can be shared as a profile feed card while the detailed answers stay private.',
          vibeTags: [
            TruVibeTag(visibleQuiz.primaryResult ?? 'quiz result',
                primary: true),
            const TruVibeTag('shareable'),
          ],
          actionLabel: 'View quizzes',
          emphasized: true,
        ),
      );
    } else {
      items.add(
        const TruDemoFeedItem(
          id: 'profile-quiz-placeholder',
          kind: TruluraFeedDemoCardKind.quiz,
          title: 'Private quiz chamber',
          body:
              'Quiz insights stay private until the profile owner chooses to turn one into a public aura card.',
          vibeTags: [
            TruVibeTag('private by default'),
            TruVibeTag('quiz'),
          ],
        ),
      );
    }

    items.addAll(const [
      TruDemoFeedItem(
        id: 'profile-repost-placeholder',
        kind: TruluraFeedDemoCardKind.conversation,
        title: 'Community echo',
        body:
            'Shared moments from circles, conversations, and saved sparks can gather here as part of the profile story.',
        vibeTags: [
          TruVibeTag('repost'),
          TruVibeTag('community'),
        ],
      ),
      TruDemoFeedItem(
        id: 'profile-soft-prompt',
        kind: TruluraFeedDemoCardKind.supportPrompt,
        title: 'Soft engagement prompt',
        body:
            'Gentle profile prompts make the space feel social without forcing likes, streaks, or monetized engagement.',
        vibeTags: [
          TruVibeTag('low pressure'),
          TruVibeTag('prompt'),
        ],
      ),
      TruDemoFeedItem(
        id: 'profile-ai-nudge',
        kind: TruluraFeedDemoCardKind.recommendation,
        title: 'Soft AI nudge',
        body:
            'AI suggestions appear as quiet social prompts, never automated posting or noisy growth pressure.',
        vibeTags: [
          TruVibeTag('suggested'),
          TruVibeTag('social rhythm'),
        ],
      ),
    ]);

    return items;
  }

  List<TruFeedItem> ventItems(List<Post> posts) {
    if (posts.isEmpty) {
      return const [
        TruDemoFeedItem(
          id: 'vent-emotional-prompt',
          kind: TruluraFeedDemoCardKind.supportPrompt,
          title: 'Emotional prompt',
          body:
              'A protected support prompt holds space when the sanctuary is quiet.',
          vibeTags: [
            TruVibeTag('anonymous'),
            TruVibeTag('support'),
            TruVibeTag('protected'),
          ],
          actionLabel: 'Write a vent',
          emphasized: true,
        ),
      ];
    }
    return [
      const TruDemoFeedItem(
        id: 'vent-support-primer',
        kind: TruluraFeedDemoCardKind.supportPrompt,
        title: 'Support cue',
        body:
            'Reply softly, reflect first, and keep Vent separated from virality.',
        vibeTags: [
          TruVibeTag('support'),
          TruVibeTag('low energy'),
        ],
        emphasized: true,
      ),
      ...posts.map(
        (post) => TruPostFeedItem(
          post: post.copyWith(isAnonymous: true),
          why:
              'Vent Space keeps identity private and suppresses viral framing.',
        ),
      ),
    ];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
