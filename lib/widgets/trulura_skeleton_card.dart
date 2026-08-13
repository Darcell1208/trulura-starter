import 'package:flutter/material.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';

enum TruluraSkeletonVariant { feed, sync, explore, inbox, profile }

/// Spec component: TruluraSkeletonCard.
///
/// Uses the existing skeleton primitives (`TruSkeletonBox/Circle`) so loading
/// feels consistent.
class TruluraSkeletonCard extends StatelessWidget {
  final TruluraSkeletonVariant variant;

  const TruluraSkeletonCard({super.key, required this.variant});

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case TruluraSkeletonVariant.feed:
        return const _FeedSkeleton();
      case TruluraSkeletonVariant.sync:
        return const _SyncSkeleton();
      case TruluraSkeletonVariant.explore:
        return const _ExploreSkeleton();
      case TruluraSkeletonVariant.inbox:
        return const _InboxSkeleton();
      case TruluraSkeletonVariant.profile:
        return const _ProfileSkeleton();
    }
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [TruSkeletonCircle(size: 38), SizedBox(width: 10), Expanded(child: TruSkeletonBox(width: double.infinity, height: 14)), SizedBox(width: 80)]),
          SizedBox(height: 12),
          TruSkeletonBox(width: double.infinity, height: 16),
          SizedBox(height: 8),
          TruSkeletonBox(width: double.infinity, height: 16),
          SizedBox(height: 8),
          TruSkeletonBox(width: 220, height: 16),
          SizedBox(height: 14),
          Row(children: [TruSkeletonBox(height: 28, width: 86), SizedBox(width: 10), TruSkeletonBox(height: 28, width: 86), SizedBox(width: 10), TruSkeletonBox(height: 28, width: 86)]),
        ],
      ),
    );
  }
}

class _SyncSkeleton extends StatelessWidget {
  const _SyncSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [TruSkeletonCircle(size: 64), SizedBox(width: 12), Expanded(child: TruSkeletonBox(width: double.infinity, height: 18))]),
          SizedBox(height: 14),
          TruSkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: 8),
          TruSkeletonBox(width: 220, height: 14),
          SizedBox(height: 14),
          Row(children: [Expanded(child: TruSkeletonBox(width: double.infinity, height: 44)), SizedBox(width: 12), Expanded(child: TruSkeletonBox(width: double.infinity, height: 44))]),
        ],
      ),
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TruSkeletonBox(width: double.infinity, height: 170),
          SizedBox(height: 10),
          TruSkeletonBox(width: 160, height: 16),
          SizedBox(height: 8),
          TruSkeletonBox(width: 240, height: 14),
        ],
      ),
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          TruSkeletonCircle(size: 46),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TruSkeletonBox(height: 14, width: 160),
                SizedBox(height: 8),
                TruSkeletonBox(width: double.infinity, height: 14),
              ],
            ),
          ),
          SizedBox(width: 12),
          TruSkeletonBox(height: 12, width: 46),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [TruSkeletonCircle(size: 74), SizedBox(width: 14), Expanded(child: TruSkeletonBox(width: double.infinity, height: 18))]),
          SizedBox(height: 14),
          TruSkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: 8),
          TruSkeletonBox(width: double.infinity, height: 14),
        ],
      ),
    );
  }
}
