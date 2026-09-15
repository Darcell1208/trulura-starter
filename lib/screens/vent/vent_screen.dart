import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/diagnostics/log_redaction.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/feed_item.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';

class VentScreen extends StatefulWidget {
  const VentScreen({super.key});

  @override
  State<VentScreen> createState() => _VentScreenState();
}

class _VentScreenState extends State<VentScreen> {
  final PostService _postService = PostService();
  List<Post> _ventPosts = [];
  bool _isLoading = true;
  bool _hasError = false;

  final List<String> _circles = const [
    'All',
    'Healing',
    'Parenting',
    'Work',
    'Relationships'
  ];
  String _circle = 'All';

  /// The mode that was active before the Sanctuary switched it, and the
  /// controller to hand it back to.
  ///
  /// Held rather than re-read in [dispose], because looking a provider up from
  /// the element tree while it is being torn down is not safe. Non-null means
  /// "this screen changed the mode and still owes a restore".
  ExperienceModeController? _modeController;
  TruExperienceMode? _modeBeforeVent;

  @override
  void initState() {
    super.initState();
    _loadVentPosts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterVentMode());
  }

  /// Hands the experience mode back on the way out.
  ///
  /// Vent mode is persisted through ExperienceModeService, so before this
  /// nothing ever set it back: entering the Sanctuary once left the composer
  /// defaulting to private and anonymous everywhere afterwards, and across
  /// app restarts. Restoring here rather than on every route change is what
  /// keeps the composer working -- CreatePostScreen is pushed *on top* of this
  /// screen, which does not dispose it, so opening the composer correctly
  /// keeps Vent mode while genuinely leaving the Sanctuary gives it up.
  ///
  /// KNOWN GAP: dispose does not run if the process is killed while the
  /// Sanctuary is open, so a hard kill still leaves Vent mode persisted. That
  /// is narrower than the bug it replaces but it is not nothing.
  ///
  /// Scheduled post-frame because setActiveMode notifies its listeners, and
  /// notifying during teardown rebuilds widgets mid-dispose.
  @override
  void dispose() {
    final controller = _modeController;
    final previous = _modeBeforeVent;
    _modeController = null;
    _modeBeforeVent = null;
    if (controller != null && previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await controller.setActiveMode(previous, confirmed: true);
        } catch (e) {
          debugPrint(
              'VentScreen: could not restore experience mode: ${safeError(e)}');
        }
      });
    }
    super.dispose();
  }

  /// Puts the app in Vent experience mode on entry.
  ///
  /// CreatePostScreen decides its privacy and anonymity defaults from
  /// ExperienceModeController.participationContext.activeMode, not from the
  /// route that opened it. Arriving in Vent from the drawer while in Social
  /// mode therefore produced a Public, attributed composer under copy that
  /// promises anonymity -- so entering the Sanctuary has to be what sets the
  /// mode, since arriving here IS the statement of intent.
  ///
  /// confirmed: true because opening this screen is an explicit, deliberate
  /// user action. setActiveMode can still refuse -- a locked or blocked
  /// transition -- so the result is logged rather than assumed; a refusal means
  /// the composer keeps whatever defaults the current mode gives it.
  /// The mode is recorded only once the switch has actually been accepted, so
  /// a refused transition leaves nothing to restore and [dispose] does not
  /// clobber a mode this screen never changed.
  Future<void> _enterVentMode() async {
    try {
      final controller = context.read<ExperienceModeController>();
      if (controller.activeMode == TruExperienceMode.vent) return;
      final previous = controller.activeMode;
      final ok = await controller.setActiveMode(TruExperienceMode.vent,
          confirmed: true);
      if (!ok) {
        debugPrint('VentScreen: could not switch to Vent experience mode');
        return;
      }
      _modeController = controller;
      _modeBeforeVent = previous;
    } catch (e) {
      debugPrint('VentScreen._enterVentMode failed: ${safeError(e)}');
    }
  }

  /// Opens the composer and refreshes when it closes.
  ///
  /// The composer pops with no callback and nothing re-runs the query on route
  /// resume, so without this a successful post left the Sanctuary showing its
  /// pre-post state -- the post was in vent_feed and never once displayed.
  Future<void> _openComposer() async {
    await TruNavigation.pushWithReturnTo(context, AppRoutes.createPost);
    if (!mounted) return;
    await _loadVentPosts();
  }

  Future<void> _loadVentPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _postService.getPostsByCategory('Vent');
      if (!mounted) return;
      setState(() {
        _ventPosts = posts;
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      truLogStateError('Vent._loadVentPosts', e);
      if (!mounted) return;
      setState(() {
        _ventPosts = [];
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<Post> get _filtered {
    if (_circle == 'All') return _ventPosts;
    final k = _circle.toLowerCase();
    return _ventPosts
        .where((p) => p.content.toLowerCase().contains(k))
        .toList();
  }

  /// The post list, sized to its content.
  ///
  /// shrinkWrap with NeverScrollableScrollPhysics because this now lives inside
  /// the page's CustomScrollView: one scrollable, one scroll position. Pull to
  /// refresh belongs to that outer view, which is why the RefreshIndicator
  /// moved out of here and up to the page body.
  Widget _buildVentFeedList(List<TruFeedItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppSpacing.paddingMd,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => TruluraFeedLane(
        child: TruluraFeedItemRenderer(item: items[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: kTruLuraPalettes[TruLuraMode.vent]!.bg0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => TruNavigation.goBackOrReturn(context),
        ),
        title: const Text('Vent Sanctuary'),
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.vent,
        // Header, filters and banner scroll WITH the feed rather than sitting
        // above it in a fixed Column.
        //
        // They used to be fixed children of a Column whose last child was
        // Expanded(feed). Their combined height -- a 92px spacer, a header with
        // a 390px min-height, a 54px filter strip and the banner -- exceeded
        // the viewport, so Expanded resolved to zero height and the feed had
        // nowhere to render. That is the 136px bottom overflow, and it is why
        // the query could succeed while nothing appeared: the posts were laid
        // out into a box with no room in it.
        //
        // The header block now scrolls out of the way instead of competing for
        // space, and the feed sits below it in the same scroll view.
        child: RefreshIndicator(
          onRefresh: _loadVentPosts,
          // One scroll view for the page, so one scroll position and one
          // refresh gesture. The feed list inside shrink-wraps.
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TruluraContentLane(
                      maxWidth: kTruluraDesktopContentMaxWidth,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _VentSanctuaryHeader(
                        onWrite: _openComposer,
                        onHealing: () => setState(() => _circle = 'Healing'),
                      ),
                    ),
                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _circles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final c = _circles[i];
                          final selected = c == _circle;
                          return GestureDetector(
                            onTap: () => setState(() => _circle = c),
                            child: TruLuraGlassCard(
                              radius: 999,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              fillAOverride: selected
                                  ? TruLuraBrandColors.neonBlue
                                      .withValues(alpha: 0.20)
                                  : null,
                              fillBOverride: selected
                                  ? TruLuraBrandColors.neonPurple
                                      .withValues(alpha: 0.12)
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TruLuraIcon(
                                      glyph: TruLuraGlyph.groups,
                                      size: 18,
                                      active: selected,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(
                                              alpha: selected ? 0.92 : 0.72)),
                                  const SizedBox(width: 8),
                                  Text(c,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(
                                                      alpha: selected
                                                          ? 0.92
                                                          : 0.72))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: soft
                                ? TruLuraSurfaces.glassBlurSoft
                                : TruLuraSurfaces.glassBlurStrong,
                            sigmaY: soft
                                ? TruLuraSurfaces.glassBlurSoft
                                : TruLuraSurfaces.glassBlurStrong,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.surface.withValues(
                                      alpha: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? TruLuraSurfaces.glassDarkA
                                          : TruLuraSurfaces.glassLightA),
                                  cs.surfaceContainerHighest.withValues(
                                      alpha: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? TruLuraSurfaces.glassDarkB
                                          : TruLuraSurfaces.glassLightB),
                                ],
                              ),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: soft ? 0.10 : 0.085),
                                  width: TruLuraSurfaces.hairline),
                            ),
                            child: Row(
                              children: [
                                TruLuraIcon(
                                    glyph: TruLuraGlyph.shield,
                                    size: 18,
                                    active: true,
                                    color: cs.onSurface),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Safety Active • This is a protected space',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            color: cs.onSurface,
                                            fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 96 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverToBoxAdapter(
                  child: ui == TruUiState.loading
                      ? const _VentSkeleton()
                      : ui == TruUiState.empty
                          ? TruStatePanel(
                              glyph: TruLuraGlyph.shield,
                              title: 'This is your protected space',
                              message:
                                  'Vent anonymously, join a support circle, or browse gentle topics. You’re safe here.',
                              actions: [
                                TruStateAction(
                                    label: 'Write a vent',
                                    glyph: TruLuraGlyph.edit,
                                    onTap: _openComposer,
                                    primary: true),
                                TruStateAction(
                                    label: 'Join support circle',
                                    glyph: TruLuraGlyph.groups,
                                    onTap: () =>
                                        setState(() => _circle = 'Healing')),
                              ],
                            )
                          : ui == TruUiState.action
                              ? TruStatePanel(
                                  glyph: TruLuraGlyph.shield,
                                  title: 'Your vent is under review',
                                  message:
                                      'To keep Vent Space emotionally safe, some posts are briefly held for moderation. You’ll see it here once approved.',
                                  actions: [
                                    TruStateAction(
                                        label: 'Browse circles',
                                        glyph: TruLuraGlyph.groups,
                                        onTap: () =>
                                            setState(() => _circle = 'All'),
                                        primary: true),
                                    TruStateAction(
                                        label: 'Write another vent',
                                        glyph: TruLuraGlyph.edit,
                                        onTap: _openComposer),
                                  ],
                                )
                              : _isLoading
                                  ? const _VentSkeleton()
                                  : _hasError
                                      ? TruStatePanel(
                                          glyph: TruLuraGlyph.info,
                                          title: 'Vent Space couldn’t load',
                                          message:
                                              'We couldn’t load this protected space right now. Try again.',
                                          actions: [
                                            TruStateAction(
                                                label: 'Retry',
                                                glyph: TruLuraGlyph.spark,
                                                onTap: _loadVentPosts,
                                                primary: true)
                                          ],
                                        )
                                      : _ventPosts.isEmpty
                                          ? TruStatePanel(
                                              glyph: TruLuraGlyph.shield,
                                              title: 'Vent Space is quiet',
                                              message:
                                                  'Start a protected reflection when you are ready.',
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      14, 14, 14, 14),
                                            )
                                          : _filtered.isEmpty
                                              ? TruStatePanel(
                                                  glyph: TruLuraGlyph.groups,
                                                  title:
                                                      'No posts in this support circle',
                                                  message:
                                                      'Try a different circle, or check back soon.',
                                                  actions: [
                                                    TruStateAction(
                                                        label: 'Show all',
                                                        glyph:
                                                            TruLuraGlyph.spark,
                                                        onTap: () => setState(
                                                            () => _circle =
                                                                'All'),
                                                        primary: true)
                                                  ],
                                                )
                                              : _buildVentFeedList(
                                                  _filtered
                                                      .map(
                                                        (post) =>
                                                            TruPostFeedItem(
                                                          post: post.copyWith(
                                                            isAnonymous: true,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(growable: false),
                                                ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        icon: const TruLuraIcon(
            glyph: TruLuraGlyph.edit,
            size: 20,
            active: true,
            color: Colors.white),
        label: const Text('Enter Reflection'),
      ),
    );
  }
}

class _VentSkeleton extends StatelessWidget {
  const _VentSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.paddingMd,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return TruLuraGlassCard(
            radius: AppRadius.card,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    TruSkeletonCircle(size: 40),
                    SizedBox(width: 12),
                    TruSkeletonBox(width: 120, height: 14, radius: 10),
                    Spacer(),
                    TruSkeletonBox(width: 26, height: 26, radius: 10),
                  ],
                ),
                SizedBox(height: 14),
                TruSkeletonBox(width: double.infinity, height: 14, radius: 10),
                SizedBox(height: 10),
                TruSkeletonBox(width: double.infinity, height: 14, radius: 10),
                SizedBox(height: 10),
                TruSkeletonBox(width: 240, height: 14, radius: 10),
                SizedBox(height: 14),
                TruSkeletonBox(width: double.infinity, height: 38, radius: 18),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VentSanctuaryHeader extends StatelessWidget {
  final VoidCallback onWrite;
  final VoidCallback onHealing;

  const _VentSanctuaryHeader({
    required this.onWrite,
    required this.onHealing,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 390),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -70,
            top: -30,
            width: 300,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    TruLuraTokens.auraCyan.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _SanctuaryShelterPainter()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TruLuraBrandColors.neonBlue.withValues(alpha: 0.08),
                    Colors.transparent,
                    TruLuraTokens.ink.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final text = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EMOTIONAL SANCTUARY',
                      style: t.labelSmall?.copyWith(
                        color: TruLuraTokens.auraCyan,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your emotional shelter.',
                      style: t.displaySmall?.copyWith(
                        color: TruLuraTokens.textPrimary,
                        fontFamily: 'Georgia',
                        height: 1.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vent is anonymous, moderated, low-pressure, and held for release without performance.',
                      style: t.bodyLarge?.copyWith(
                        color: TruLuraTokens.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _SanctuaryAction(
                          label: 'Write Privately',
                          glyph: TruLuraGlyph.edit,
                          primary: true,
                          onTap: onWrite,
                        ),
                        _SanctuaryAction(
                          label: 'Healing Circle',
                          glyph: TruLuraGlyph.groups,
                          onTap: onHealing,
                        ),
                      ],
                    ),
                  ],
                );
                final rooms = _SanctuaryRooms(onHealing: onHealing);
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text,
                      const SizedBox(height: 22),
                      rooms,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 6, child: text),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: rooms),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SanctuaryAction extends StatelessWidget {
  final String label;
  final TruLuraGlyph glyph;
  final bool primary;
  final VoidCallback onTap;

  const _SanctuaryAction({
    required this.label,
    required this.glyph,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        primary ? TruLuraTokens.auraCyan : TruLuraBrandColors.neonBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: accent.withValues(alpha: primary ? 0.22 : 0.11),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TruLuraIcon(glyph: glyph, size: 17, active: primary, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TruLuraTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SanctuaryRooms extends StatelessWidget {
  final VoidCallback onHealing;

  const _SanctuaryRooms({required this.onHealing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShelterRoom(
          label: 'Anonymous Path',
          body: 'Release without performance.',
          glyph: TruLuraGlyph.person,
        ),
        const SizedBox(height: 10),
        _ShelterRoom(
          label: 'Healing Circles',
          body: 'Small support rooms with softer pace.',
          glyph: TruLuraGlyph.shield,
          onTap: onHealing,
        ),
        const SizedBox(height: 10),
        _ShelterRoom(
          label: 'Reflection Space',
          body: 'Prompts for what hurts and what helps.',
          glyph: TruLuraGlyph.heartOutline,
        ),
      ],
    );
  }
}

class _ShelterRoom extends StatelessWidget {
  final String label;
  final String body;
  final TruLuraGlyph glyph;
  final VoidCallback? onTap;

  const _ShelterRoom({
    required this.label,
    required this.body,
    required this.glyph,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.055),
          border: Border.all(
            color: TruLuraTokens.auraCyan.withValues(alpha: 0.16),
            width: TruLuraSurfaces.hairline,
          ),
        ),
        child: Row(
          children: [
            TruLuraIcon(
              glyph: glyph,
              size: 20,
              color: TruLuraTokens.auraCyan,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TruLuraTokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TruLuraTokens.textSecondary,
                          height: 1.25,
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

class _SanctuaryShelterPainter extends CustomPainter {
  const _SanctuaryShelterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = TruLuraTokens.auraCyan.withValues(alpha: 0.13);
    for (var i = 0; i < 4; i++) {
      final inset = 24.0 + i * 22;
      final rect = Rect.fromLTWH(
        inset,
        36 + i * 12,
        size.width - inset * 2,
        size.height - 76 - i * 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(34 + i * 8)),
        wall,
      );
    }

    final roof = Path()
      ..moveTo(size.width * 0.14, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.12,
          size.width * 0.86, size.height * 0.38);
    canvas.drawPath(roof,
        wall..color = TruLuraBrandColors.neonBlue.withValues(alpha: 0.18));

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.15),
        radius: 0.76,
        colors: [
          TruLuraTokens.auraCyan.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _SanctuaryShelterPainter oldDelegate) => false;
}

class VentCard extends StatelessWidget {
  final Post post;

  const VentCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cs = Theme.of(context).colorScheme;
    final p = kTruLuraPalettes[TruLuraMode.vent]!;

    // Vent should feel emotionally distinct: safe-space blue, subtle vignette,
    // and a calm neon presence.
    return TruLuraGlassCard(
      paletteMode: TruLuraMode.vent,
      radius: AppRadius.card,
      padding: EdgeInsets.zero,
      fillAOverride: TruLuraBrandColors.neonBlue
          .withValues(alpha: brightness == Brightness.dark ? 0.10 : 0.08),
      fillBOverride: TruLuraBrandColors.cosmicDeep
          .withValues(alpha: brightness == Brightness.dark ? 0.34 : 0.22),
      borderColorOverride: p.border.withValues(alpha: 0.55),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TruLuraBrandColors.neonBlue.withValues(alpha: 0.06),
                      TruLuraBrandColors.neonPurple.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.9),
                    radius: 1.25,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.34),
                    ],
                    stops: const [0.0, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TruLuraHaloAvatar(
                      radius: 20,
                      image: null,
                      // “Safety Active” ring feel.
                      tone: TruLuraModeTone.explore,
                      fallback: const TruLuraIcon(
                          glyph: TruLuraGlyph.person, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Anonymous',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: TruLuraIcon(
                          glyph: TruLuraGlyph.more,
                          size: 20,
                          active: false,
                          color: cs.onSurface.withValues(alpha: 0.88)),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: cs.onSurface.withValues(alpha: 0.92))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionButton(
                        context, TruLuraGlyph.heartOutline, post.likeCount),
                    const SizedBox(width: 20),
                    _buildActionButton(
                        context, TruLuraGlyph.messages, post.commentCount),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                            colors: [TruLuraBrandColors.neonBlue, p.glowB]),
                        boxShadow: [
                          BoxShadow(
                            color: TruLuraBrandColors.neonBlue
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const TruLuraIcon(
                              glyph: TruLuraGlyph.heart,
                              size: 16,
                              active: true,
                              color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Support',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, TruLuraGlyph icon, int count) {
    return Row(
      children: [
        TruLuraIcon(
            glyph: icon,
            size: 20,
            active: false,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
