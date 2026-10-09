import 'package:flutter/material.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';

enum _NotificationFilter {
  all('All'),
  glows('Glows'),
  sparks('Sparks'),
  replies('Replies'),
  follows('Follows'),
  safety('Safety'),
  events('Events');

  final String label;
  const _NotificationFilter(this.label);
}

enum _NotificationKind {
  glow,
  react,
  reply,
  follow,
  sync,
  quiz,
  community,
  event,
  safety;
}

class _NotificationDemo {
  final _NotificationKind kind;
  final String group;
  final String title;
  final String body;
  final String time;
  final bool priority;

  const _NotificationDemo({
    required this.kind,
    required this.group,
    required this.title,
    required this.body,
    required this.time,
    this.priority = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  // Populate only from authenticated account notifications once the service is wired.
  // Illustrative design activity must never appear as a user's real alerts.
  static const List<_NotificationDemo> _items = [];

  bool _matches(_NotificationDemo item) {
    return switch (_filter) {
      _NotificationFilter.all => true,
      _NotificationFilter.glows => item.kind == _NotificationKind.glow ||
          item.kind == _NotificationKind.react,
      _NotificationFilter.sparks => item.kind == _NotificationKind.sync,
      _NotificationFilter.replies => item.kind == _NotificationKind.reply,
      _NotificationFilter.follows => item.kind == _NotificationKind.follow,
      _NotificationFilter.safety => item.kind == _NotificationKind.safety,
      _NotificationFilter.events => item.kind == _NotificationKind.event ||
          item.kind == _NotificationKind.community,
    };
  }

  TruLuraGlyph _glyphFor(_NotificationKind kind) {
    return switch (kind) {
      _NotificationKind.glow => TruLuraGlyph.spark,
      _NotificationKind.react => TruLuraGlyph.heartOutline,
      _NotificationKind.reply => TruLuraGlyph.messages,
      _NotificationKind.follow => TruLuraGlyph.person,
      _NotificationKind.sync => TruLuraGlyph.sync,
      _NotificationKind.quiz => TruLuraGlyph.insights,
      _NotificationKind.community => TruLuraGlyph.groups,
      _NotificationKind.event => TruLuraGlyph.star,
      _NotificationKind.safety => TruLuraGlyph.shield,
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where(_matches).toList(growable: false);
    final groups = ['Priority', 'Today', 'Earlier']
        .map((group) => MapEntry(
              group,
              filtered
                  .where((item) => item.group == group)
                  .toList(growable: false),
            ))
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false);

    return TruluraContentLane(
      padding: EdgeInsets.zero,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(16, 10, 16, kTruluraBottomNavClearance),
        children: [
          Text(
            'Notifications',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(letterSpacing: -0.8, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Glows, replies, follows, Sync activity, community invites, and private alerts will collect here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            primary: false,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in _NotificationFilter.values) ...[
                  TruluraFeedChip(
                    label: filter.label,
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            TruStatePanel(
              glyph: TruLuraGlyph.info,
              title: 'Notifications are not connected yet',
              message: 'Live alerts are not available in this build yet.',
            )
          else ...[
            for (final group in groups) ...[
              _NotificationSection(
                title: group.key,
                children: [
                  for (final item in group.value)
                    _NotificationCard(
                      item: item,
                      glyph: _glyphFor(item.kind),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NotificationSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationDemo item;
  final TruLuraGlyph glyph;

  const _NotificationCard({
    required this.item,
    required this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TruLuraGlassCard(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        tint: item.priority
            ? TruLuraBrandColors.neonPurple.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: TruLuraSurfaces.hairline,
                ),
              ),
              child: TruLuraIcon(
                glyph: glyph,
                size: 20,
                active: true,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.58),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.72),
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
