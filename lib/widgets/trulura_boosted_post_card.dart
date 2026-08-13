import 'package:flutter/material.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/widgets/feed_card.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class TruluraBoostedPostCard extends StatelessWidget {
  final Post post;
  final int initialGlowCount;
  final bool initiallyGlowed;
  final String why;

  const TruluraBoostedPostCard({super.key, required this.post, required this.initialGlowCount, required this.initiallyGlowed, required this.why});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Stack(
      children: [
        FeedCard(post: post, initialGlowCount: initialGlowCount, initiallyGlowed: initiallyGlowed, whyAmISeeingThis: why),
        Positioned(
          top: 12,
          right: 12,
          child: IgnorePointer(
            child: TruLuraGlassCard(
              radius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              depth: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TruLuraIcon(glyph: TruLuraGlyph.spark, size: 16, active: true),
                  const SizedBox(width: 6),
                  Text('Boosted', style: t.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
