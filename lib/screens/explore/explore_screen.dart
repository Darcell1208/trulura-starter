import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/quiz_engine.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_cinematic_components.dart';
import 'package:trulura/widgets/trulura_explore_profile_card.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_orb_chip.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final UserService _userService = UserService();
  final TextEditingController _search = TextEditingController();
  final Set<String> _followed = <String>{};
  final Set<String> _connectSent = <String>{};

  List<User> _users = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _hasError = false;

  final List<String> _categories = const [
    'All',
    'Gaming/Anime',
    'Mommy Space',
    'Travel',
    'Events',
    'Nearby',
    'Verified',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      truLogStateError('Explore._loadUsers', e);
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<String> _visibleCategories(List<String> interests) => <String>[
        ..._categories,
        ...interests.where((e) => !_categories.contains(e)).take(4),
      ];

  List<User> get _filtered {
    final q = _search.text.trim().toLowerCase();
    Iterable<User> out = _users;
    if (_selectedCategory == 'Verified') {
      out = out.where((u) => (u.profileImage ?? '').trim().isNotEmpty);
    } else if (_selectedCategory == 'Nearby') {
      out = out.take(3);
    } else if (_selectedCategory != 'All') {
      final tag = _selectedCategory.toLowerCase();
      out = out.where((u) => (u.bio ?? '').toLowerCase().contains(tag));
    }
    if (q.isNotEmpty) {
      out = out.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          (u.bio ?? '').toLowerCase().contains(q));
    }
    return out.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final categories =
        _visibleCategories(app.currentUser?.interests ?? const <String>[]);
    final filtered = _filtered;
    final hasQuery = _search.text.trim().isNotEmpty;

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, kTruluraBottomNavClearance),
      children: [
        TruluraContentLane(
          maxWidth: kTruluraDesktopContentMaxWidth,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _ExploreDiscoveryMap(
            selectedCategory: _selectedCategory,
            onCategory: (category) => setState(() {
              _selectedCategory = category;
            }),
            onOpenVent: () => context.push(AppRoutes.vent),
            onTune: () => context.push(
              Uri(
                path: AppRoutes.microQuiz,
                queryParameters: {
                  'quiz': TruQuizEngine.friendshipEnergyMatchQuizId,
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            ),
          ),
        ),
        SizedBox(
          height: 74,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: kTruluraDesktopContentMaxWidth),
              child: ListView.separated(
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return TruLuraOrbChip(
                    label: category,
                    selected: _selectedCategory == category,
                    onTap: () => setState(() => _selectedCategory = category),
                    glyph: TruLuraGlyph.explore,
                    size: 44,
                    compact: true,
                    tone: TruLuraModeTone.explore,
                  );
                },
              ),
            ),
          ),
        ),
        TruluraContentLane(
          maxWidth: kTruluraDesktopContentMaxWidth,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CosmicGlassCard(
            radius: 26,
            accent: TruLuraTokens.auraCyan,
            padding: const EdgeInsets.all(16),
            child: _SearchField(
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        _buildResults(filtered, hasQuery),
        TruluraContentLane(
          maxWidth: kTruluraDesktopContentMaxWidth,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CosmicGlassCard(
            radius: 26,
            accent: TruLuraBrandColors.glowGold,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const GlowIconButton(
                  glyph: TruLuraGlyph.insights,
                  onTap: _noop,
                  accent: TruLuraBrandColors.glowGold,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discovery Tuning',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: TruLuraTokens.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A quick tuning ritual helps Explore rank worlds, communities, and people without turning it into Sync.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TruLuraTokens.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () => context.push(
                    Uri(
                      path: AppRoutes.microQuiz,
                      queryParameters: {
                        'quiz': TruQuizEngine.friendshipEnergyMatchQuizId,
                        'returnTo': GoRouterState.of(context).uri.toString(),
                      },
                    ).toString(),
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(List<User> filtered, bool hasQuery) {
    if (_isLoading) return const _ExploreSkeleton();
    if (_hasError) {
      return TruStatePanel(
        tone: TruLuraModeTone.explore,
        glyph: TruLuraGlyph.info,
        title: 'Explore could not load',
        message: 'We could not load Explore right now. Try again.',
        actions: [
          TruStateAction(
            label: 'Retry',
            glyph: TruLuraGlyph.spark,
            onTap: _loadUsers,
            primary: true,
          )
        ],
      );
    }
    if (filtered.isEmpty) {
      return TruStatePanel(
        tone: TruLuraModeTone.explore,
        glyph: TruLuraGlyph.search,
        title:
            hasQuery ? 'No matches for your search' : 'This world is quiet now',
        message: hasQuery
            ? 'Try a different name, handle, or vibe.'
            : 'Choose another world or refresh the constellation.',
        actions: [
          TruStateAction(
            label: hasQuery ? 'Clear search' : 'Featured',
            glyph: hasQuery ? TruLuraGlyph.close : TruLuraGlyph.star,
            onTap: () {
              if (hasQuery) _search.clear();
              setState(() => _selectedCategory = 'All');
            },
            primary: true,
          ),
          TruStateAction(
            label: 'Refresh',
            glyph: TruLuraGlyph.spark,
            onTap: _loadUsers,
          ),
        ],
      );
    }

    return TruluraContentLane(
      maxWidth: kTruluraDesktopContentMaxWidth,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1180
              ? 5
              : width >= 920
                  ? 4
                  : width >= 620
                      ? 3
                      : 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CinematicSectionHeader(
                title: _selectedCategory == 'All'
                    ? 'People Inside Open Worlds'
                    : 'People Inside $_selectedCategory',
                subtitle:
                    'Enter a destination first, then meet the people, spaces, and signals living inside it.',
              ),
              const SizedBox(height: 12),
              GridView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: width < 380 ? 0.65 : 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return TruluraExploreProfileCard(
                    user: user,
                    followed: _followed.contains(user.id),
                    connectSent: _connectSent.contains(user.id),
                    onTapCard: () => _openProfilePreview(user),
                    onFollow: () => _toggleFollow(user),
                    onConnect: _connectSent.contains(user.id)
                        ? null
                        : () => _sendConnect(user),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleFollow(User user) {
    setState(() {
      if (_followed.contains(user.id)) {
        _followed.remove(user.id);
      } else {
        _followed.add(user.id);
      }
    });
    final displayHandle = user.publicUsername ?? user.publicDisplayName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _followed.contains(user.id)
              ? 'Followed $displayHandle'
              : 'Unfollowed $displayHandle',
        ),
      ),
    );
  }

  void _sendConnect(User user) {
    setState(() => _connectSent.add(user.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection request sent')),
    );
  }

  Future<void> _openProfilePreview(User user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: CosmicGlassCard(
              radius: 28,
              accent: TruLuraTokens.auraCyan,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AuraRingAvatar(
                        imageUrl: user.profileImage,
                        size: 76,
                        accentA: TruLuraTokens.auraCyan,
                        accentB: TruLuraTokens.auraPink,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.publicDisplayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: TruLuraTokens.textPrimary,
                                    fontFamily: 'Georgia',
                                  ),
                            ),
                            if (user.publicUsername != null)
                              Text(
                                '@${user.publicUsername}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: TruLuraTokens.textSecondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      GlowIconButton(
                        glyph: TruLuraGlyph.close,
                        tooltip: 'Close',
                        onTap: () => context.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (user.bio ??
                            'Always up for an emotionally honest adventure.')
                        .trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TruLuraTokens.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: EmotionalChip(
                          label: _followed.contains(user.id)
                              ? 'Unfollow'
                              : 'Follow',
                          glyph: TruLuraGlyph.person,
                          selected: _followed.contains(user.id),
                          onTap: () => _toggleFollow(user),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EmotionalChip(
                          label: _connectSent.contains(user.id)
                              ? 'Request Sent'
                              : 'Connect',
                          glyph: TruLuraGlyph.sync,
                          accent: TruLuraTokens.auraPink,
                          selected: true,
                          onTap: _connectSent.contains(user.id)
                              ? null
                              : () {
                                  _sendConnect(user);
                                  context.pop();
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: TruLuraTokens.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search worlds, spaces, people...',
        hintStyle: TextStyle(
          color: TruLuraTokens.textMuted.withValues(alpha: 0.78),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: TruLuraIcon(glyph: TruLuraGlyph.search, size: 20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.075),
      ),
    );
  }
}

class _ExploreDiscoveryMap extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategory;
  final VoidCallback onOpenVent;
  final VoidCallback onTune;

  const _ExploreDiscoveryMap({
    required this.selectedCategory,
    required this.onCategory,
    required this.onOpenVent,
    required this.onTune,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 430),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -60,
            top: 40,
            width: 240,
            height: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    TruLuraTokens.auraCyan.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DiscoveryMapPainter(selected: selectedCategory),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 22, 8, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WORLDS BEYOND ME',
                            style: t.labelSmall?.copyWith(
                              color: TruLuraTokens.auraCyan,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Choose a realm before you meet the people inside it.',
                            style: t.displaySmall?.copyWith(
                              color: TruLuraTokens.textPrimary,
                              fontFamily: 'Georgia',
                              height: 1.03,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Explore is a discovery map for destinations, communities, events, creators, and topics beyond your own orbit.',
                            style: t.bodyLarge?.copyWith(
                              color: TruLuraTokens.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: onTune,
                      tooltip: 'Tune discovery',
                      icon: const TruLuraIcon(
                        glyph: TruLuraGlyph.insights,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final nodes = [
                      _MapNode(
                        title: 'Anime Realm',
                        subtitle: 'Stories and fandom paths',
                        glyph: TruLuraGlyph.star,
                        category: 'Gaming/Anime',
                        alignment: compact
                            ? Alignment.centerLeft
                            : const Alignment(-0.82, -0.04),
                      ),
                      _MapNode(
                        title: 'Gaming Realm',
                        subtitle: 'Co-op spaces and parties',
                        glyph: TruLuraGlyph.video,
                        category: 'Gaming/Anime',
                        alignment: compact
                            ? Alignment.centerRight
                            : const Alignment(0.16, -0.22),
                      ),
                      _MapNode(
                        title: 'Creator Worlds',
                        subtitle: 'Live rooms and art spaces',
                        glyph: TruLuraGlyph.spark,
                        category: 'Events',
                        alignment: compact
                            ? Alignment.centerLeft
                            : const Alignment(0.78, 0.04),
                      ),
                      _MapNode(
                        title: 'Travel Worlds',
                        subtitle: 'Places and rituals',
                        glyph: TruLuraGlyph.pin,
                        category: 'Travel',
                        alignment: compact
                            ? Alignment.centerRight
                            : const Alignment(-0.18, 0.48),
                      ),
                      _MapNode(
                        title: 'Support Spaces',
                        subtitle: 'Public support topics',
                        glyph: TruLuraGlyph.shield,
                        category: 'Vent',
                        alignment: compact
                            ? Alignment.centerLeft
                            : const Alignment(0.58, 0.66),
                      ),
                    ];

                    if (compact) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final node in nodes)
                            _DiscoveryMapNode(
                              node: node,
                              selected: selectedCategory == node.category,
                              onTap: node.category == 'Vent'
                                  ? onOpenVent
                                  : () => onCategory(node.category),
                            ),
                        ],
                      );
                    }

                    return SizedBox(
                      height: 190,
                      child: Stack(
                        children: [
                          for (final node in nodes)
                            Align(
                              alignment: node.alignment,
                              child: _DiscoveryMapNode(
                                node: node,
                                selected: selectedCategory == node.category,
                                onTap: node.category == 'Vent'
                                    ? onOpenVent
                                    : () => onCategory(node.category),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNode {
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final String category;
  final Alignment alignment;

  const _MapNode({
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.category,
    required this.alignment,
  });
}

class _DiscoveryMapNode extends StatelessWidget {
  final _MapNode node;
  final bool selected;
  final VoidCallback onTap;

  const _DiscoveryMapNode({
    required this.node,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        selected ? TruLuraBrandColors.glowGold : TruLuraTokens.auraCyan;
    return InkResponse(
      onTap: onTap,
      radius: 76,
      child: SizedBox(
        width: 164,
        height: 146,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 82 : 72,
              height: selected ? 82 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: selected ? 0.22 : 0.10),
                    accent.withValues(alpha: selected ? 0.34 : 0.18),
                    TruLuraTokens.ink.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.34, 0.68, 1.0],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: selected ? 0.58 : 0.24),
                  width: TruLuraSurfaces.hairline,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: selected ? 0.32 : 0.13),
                    blurRadius: selected ? 36 : 24,
                    spreadRadius: selected ? 1 : -4,
                  ),
                ],
              ),
              child: Center(
                child: TruLuraIcon(
                  glyph: node.glyph,
                  size: selected ? 27 : 23,
                  active: selected,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              node.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TruLuraTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              node.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TruLuraTokens.textSecondary,
                    height: 1.15,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryMapPainter extends CustomPainter {
  final String selected;

  const _DiscoveryMapPainter({required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final wash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.72, -0.56),
        radius: 1.15,
        colors: [
          TruLuraTokens.auraCyan.withValues(alpha: 0.20),
          TruLuraTokens.auraViolet.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, wash);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = TruLuraBrandColors.glowGold.withValues(alpha: 0.16);
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.68)
      ..cubicTo(size.width * 0.24, size.height * 0.44, size.width * 0.46,
          size.height * 0.58, size.width * 0.56, size.height * 0.42)
      ..cubicTo(size.width * 0.66, size.height * 0.24, size.width * 0.82,
          size.height * 0.46, size.width * 0.90, size.height * 0.32);
    canvas.drawPath(path, line);

    final dot = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 18; i++) {
      final x = size.width * (0.08 + ((i * 17) % 84) / 100);
      final y = size.height * (0.18 + ((i * 29) % 68) / 100);
      dot.color =
          (i.isEven ? TruLuraTokens.auraCyan : TruLuraBrandColors.glowGold)
              .withValues(alpha: selected == 'All' ? 0.11 : 0.16);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.55, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _DiscoveryMapPainter oldDelegate) {
    return oldDelegate.selected != selected;
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruluraContentLane(
      maxWidth: kTruluraDesktopContentMaxWidth,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.builder(
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.74,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) =>
            const TruSkeletonBox(width: double.infinity, height: 220),
      ),
    );
  }
}

void _noop() {}
