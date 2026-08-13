import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/core/navigation/tru_route_observer.dart';
import 'package:trulura/models/identity/identity_profile.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/identity_service.dart';
import 'package:trulura/services/identity_profile_service.dart';
import 'package:trulura/services/compatibility_service.dart';
import 'package:trulura/services/deep_quiz_archive_service.dart';
import 'package:trulura/models/profile/compatibility_report.dart';
import 'package:trulura/models/profile/quiz_result.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/services/quiz_engine.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/services/profile_completion_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_profile_hero_card.dart';
import 'package:trulura/widgets/trulura_profile_tab_bar.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/services/feed_demo_content_service.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  late final AnimationController _atmosphereController;
  final ScrollController _scrollController = ScrollController();
  User? _currentUser;
  bool _isLoading = true;
  bool _hasError = false;
  int _auraStrength = 71;
  List<Post> _myPosts = [];
  final IdentityService _identity = IdentityService();
  final IdentityProfileService _identityProfiles = IdentityProfileService();
  final CompatibilityService _compat = CompatibilityService();
  final DeepQuizArchiveService _deepArchive = DeepQuizArchiveService();
  final FeedDemoContentService _feedDemoContent =
      const FeedDemoContentService();
  final ProfileCompletionService _profileCompletion =
      const ProfileCompletionService();
  static const Map<String, int> _temporaryQuizFallback = <String, int>{
    'emotional': 70,
    'intellectual': 80,
    'lifestyle': 60,
  };

  TruIdentityProfile? _activeProfile;
  TruIdentityMode? _selectedIdentityMode;

  List<TruQuizResult> _quizResults = const <TruQuizResult>[];
  List<TruQuizResult> _deepQuizResults = const <TruQuizResult>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _atmosphereController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat();
    _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      truRouteObserver.unsubscribe(this);
      truRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    truRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    _atmosphereController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService().getCurrentUser();
      final activeProfile = user == null
          ? null
          : await _identityProfiles.getForMode(
              userId: user.id, mode: user.activeIdentityMode);
      final quiz = user == null
          ? const <TruQuizResult>[]
          : await _compat.getQuizResults(userId: user.id);
      final deepQuiz = user == null
          ? const <TruQuizResult>[]
          : await _deepArchive.getArchive(userId: user.id);
      final posts = await PostService().getAllPosts();
      final myPosts = user == null
          ? <Post>[]
          : posts
              .where((p) => p.userId == user.id && !(p.isAnonymous))
              .map((p) => p.copyWith(user: user))
              .toList();
      if (mounted) {
        context.read<AppState>().syncProfileState(
              vibe: (user?.vibeLabel ?? TruVibeLabel.oldSoul).label,
              anonymous: user?.anonymousOverlayEnabled ?? false,
            );
        await context.read<AppState>().hydrateQuizState(userId: user?.id);
      }
      setState(() {
        _currentUser = user;
        _activeProfile = activeProfile;
        _selectedIdentityMode = user?.activeIdentityMode;
        _auraStrength = _deriveAuraStrength(user);
        _myPosts = myPosts;
        _quizResults = quiz;
        _deepQuizResults = deepQuiz;
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      truLogStateError('Profile._loadUser', e);
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  bool get _isProfileIncomplete {
    return !_profileCompletion.summarize(_currentUser).hasMeaningfulProfile;
  }

  int _deriveAuraStrength(User? user) {
    // Keep the personal aura signal stable between visits.
    final seed = user?.id.hashCode ??
        user?.email.hashCode ??
        user?.username.hashCode ??
        71;
    final normalized = seed.abs() % 35; // 0..34
    return (65 + normalized).clamp(55, 99);
  }

  double _contentMaxWidth(double viewportWidth) {
    return truluraResponsiveContentMaxWidth(viewportWidth);
  }

  String _archetypeFor(String vibe, String identity) {
    final key = '$vibe $identity'.toLowerCase();
    if (key.contains('creator')) return 'Cinematic heart';
    if (key.contains('old') || key.contains('reflect')) return 'Deep signal';
    if (key.contains('spark') || key.contains('dating')) return 'Warm magnet';
    if (key.contains('calm') || key.contains('heal')) return 'Soft harbor';
    return 'Living aura';
  }

  String _rhythmFor(String socialStyle) {
    final key = socialStyle.toLowerCase();
    if (key.contains('slow') || key.contains('selective')) {
      return 'slow-bloom trust';
    }
    if (key.contains('social') || key.contains('group')) {
      return 'shared-space warmth';
    }
    if (key.contains('direct')) return 'clear signal exchange';
    return 'gentle curiosity';
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final contentMaxWidth = _contentMaxWidth(viewport.width);
    final tabViewportHeight = (viewport.height * 0.78).clamp(560.0, 860.0);
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    if (ui == TruUiState.loading) return const _ProfileSkeleton();

    if (ui == TruUiState.empty) {
      final returnTo = GoRouterState.of(context).uri.toString();
      final emptyNextStep = _profileCompletion.nextStepCopy(_currentUser);
      return TruStatePanel(
        glyph: TruLuraGlyph.person,
        title: 'Add your first profile layers',
        message: emptyNextStep,
        actions: [
          TruStateAction(
              label: 'Add bio',
              glyph: TruLuraGlyph.edit,
              onTap: () => context.push(Uri(
                  path: AppRoutes.onboardingProfileSetup,
                  queryParameters: {'returnTo': returnTo}).toString()),
              primary: true),
          TruStateAction(
              label: 'Add photos',
              glyph: TruLuraGlyph.image,
              onTap: () => context.push(Uri(
                  path: AppRoutes.onboardingProfileSetup,
                  queryParameters: {'returnTo': returnTo}).toString())),
          TruStateAction(
              label: 'Add vibes',
              glyph: TruLuraGlyph.spark,
              onTap: () => context.push(Uri(
                  path: AppRoutes.onboardingVibe,
                  queryParameters: {'returnTo': returnTo}).toString())),
        ],
      );
    }

    if (_isLoading) return const _ProfileSkeleton();

    if (_hasError) {
      return TruStatePanel(
        glyph: TruLuraGlyph.info,
        title: 'We couldn’t load your profile',
        message: 'Try again in a moment.',
        actions: [
          TruStateAction(
              label: 'Retry',
              glyph: TruLuraGlyph.spark,
              onTap: _loadUser,
              primary: true)
        ],
      );
    }

    final user = _currentUser;
    final profileSummary = _profileCompletion.summarize(user);
    final profileNextStep = _profileCompletion.nextStepCopy(user);
    final profileBreakdown = _profileCompletion.breakdownLabels(profileSummary);
    final identityMode = _selectedIdentityMode ??
        user?.activeIdentityMode ??
        TruIdentityMode.social;
    final appState = context.watch<AppState>();
    final presence = context.watch<AppProvider>().emotionalPresenceState;
    final anon = appState.isAnonymous;
    final vibe = TruVibeLabel.values.firstWhere(
      (candidate) => candidate.label == appState.selectedVibe,
      orElse: () => user?.vibeLabel ?? TruVibeLabel.oldSoul,
    );

    final layer = _activeProfile;
    final baseName = anon
        ? 'New member'
        : User.publicDisplayNameFrom(
            (layer?.displayName?.trim().isNotEmpty ?? false)
                ? layer!.displayName!.trim()
                : user?.name,
            email: user?.email,
            fallback: 'New member',
          );
    final baseHandle = anon
        ? null
        : User.publicUsernameFrom(
            (layer?.username?.trim().isNotEmpty ?? false)
                ? layer!.username!.trim()
                : user?.username,
            email: user?.email,
          );
    final baseBio = (layer?.bio?.trim().isNotEmpty ?? false)
        ? layer!.bio!.trim()
        : ((user?.bio?.trim().isNotEmpty ?? false)
            ? user!.bio!.trim()
            : '✨ Living my best life | Coffee addict ☕️');

    final name = baseName;
    final handle =
        anon ? '@masked' : (baseHandle == null ? null : '@$baseHandle');
    final bio = anon
        ? 'Anonymous layer is on. Your bio, details, and badges are masked.'
        : baseBio;

    return AnimatedBuilder(
      animation: _atmosphereController,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ProfileChamberPainter(
                    progress: _atmosphereController.value,
                    vibe: vibe.label,
                    identity: identityMode.label,
                    presenceLabel: presence.label,
                    presenceMotion: presence.motionScale,
                    presenceWarmth: presence.warmth,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                    16, 12, 16, kTruluraBottomNavClearance + 44),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      children: [
                        if (ui == TruUiState.action) ...[
                          const TruInlineBanner(
                              glyph: TruLuraGlyph.spark,
                              text:
                                  'Saved • Your profile energy just updated.'),
                          const SizedBox(height: 12),
                        ],
                        if (_isProfileIncomplete) ...[
                          TruInlineBanner(
                            glyph: TruLuraGlyph.info,
                            text:
                                '${profileSummary.statusLabel} • ${profileSummary.percent}% complete. $profileNextStep',
                            onTap: () => context.push(
                              Uri(
                                path: AppRoutes.onboardingProfileSetup,
                                queryParameters: {
                                  'returnTo':
                                      GoRouterState.of(context).uri.toString(),
                                },
                              ).toString(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profileBreakdown
                                  .map(
                                    (label) => TruLuraGlowPill(
                                      label: label,
                                      selected: label.contains('done'),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TruluraProfileHeroCard(
                          name: name,
                          handle: handle,
                          bio: bio,
                          avatarPath: (user?.profileImage ?? '').trim(),
                          auraStrength: _auraStrength,
                          onOpenSettings: () => TruNavigation.pushWithReturnTo(
                              context, AppRoutes.settings),
                        ),
                        const SizedBox(height: 10),
                        _ProfileIdentityStory(
                          archetype:
                              _archetypeFor(vibe.label, identityMode.label),
                          journeyMoments: _myPosts.length,
                          constellationSignals:
                              _quizResults.length + _deepQuizResults.length,
                          rhythm: _rhythmFor(
                            (user?.socialPreference ?? '').trim(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ProfileWeatherBand(
                          vibe: vibe.label,
                          identity: identityMode.label,
                          mood: (user?.moodTags.isNotEmpty ?? false)
                              ? user!.moodTags.first
                              : 'Reflective',
                          progress: _atmosphereController.value,
                        ),
                        const SizedBox(height: 10),
                        TruLuraGlassCard(
                          radius: 22,
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Identity layers',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              _ExperienceModesEntry(
                                  onTap: () =>
                                      context.push(AppRoutes.experienceModes)),
                              const SizedBox(height: 12),
                              _IdentityModeSwitcher(
                                selected: identityMode,
                                onSelected: (m) async {
                                  setState(() => _selectedIdentityMode = m);
                                  await _identity.setActiveMode(m);
                                  await _loadUser();
                                },
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 640;
                                  final vibePicker = _VibePicker(
                                    value: vibe,
                                    onChanged: (v) async {
                                      context.read<AppState>().setVibe(v.label);
                                      await _identity.setVibeLabel(v);
                                      await _loadUser();
                                    },
                                  );
                                  final anonToggle = _AnonToggle(
                                    enabled: anon,
                                    onChanged: (v) async {
                                      if (context
                                              .read<AppState>()
                                              .isAnonymous !=
                                          v) {
                                        context
                                            .read<AppState>()
                                            .toggleAnonymous();
                                      }
                                      await _identity.setAnonymousOverlay(v);
                                      await _loadUser();
                                    },
                                  );
                                  if (isCompact) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        vibePicker,
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: anonToggle,
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: vibePicker),
                                      const SizedBox(width: 12),
                                      anonToggle,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        TruluraProfileTabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Story'),
                            Tab(text: 'Journey'),
                            Tab(text: 'Moments'),
                            Tab(text: 'Resonance'),
                            Tab(text: 'Aura'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: tabViewportHeight,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAboutTab(),
                              _buildUnifiedFeedTab(),
                              _buildContentTab(),
                              _buildCompatibilityTab(),
                              _buildVibesTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutTab() {
    final u = _currentUser;
    final vibe = (u?.vibeLabel ?? TruVibeLabel.oldSoul).label;
    final identity = (u?.activeIdentityMode ?? TruIdentityMode.social).label;
    final primaryIntent =
        (u?.intents.isNotEmpty ?? false) ? u!.intents.first : 'open connection';
    final socialStyle = ((u?.socialPreference ?? '').trim().isNotEmpty)
        ? u!.socialPreference!.trim()
        : 'selective, warm, low-pressure';
    final moodSignature = (u?.moodTags.isNotEmpty ?? false)
        ? u!.moodTags.take(3).join(' / ')
        : 'reflective / tender / curious';
    final details = <Widget>[];
    details.add(_ProfileInfoRow(icon: TruLuraGlyph.spark, text: vibe));
    details.add(
      _ProfileInfoRow(
        icon: TruLuraGlyph.person,
        text: identity,
      ),
    );
    if (u?.intents.isNotEmpty ?? false) {
      details.add(
        _ProfileInfoRow(
          icon: TruLuraGlyph.heartOutline,
          text: u!.intents.join(' • '),
        ),
      );
    }
    if ((u?.socialPreference ?? '').trim().isNotEmpty) {
      details.add(
        _ProfileInfoRow(
          icon: TruLuraGlyph.groups,
          text: u!.socialPreference!.trim(),
        ),
      );
    }
    if ((u?.location ?? '').trim().isNotEmpty) {
      details.add(
        _ProfileInfoRow(
          icon: TruLuraGlyph.explore,
          text: u!.location!.trim(),
        ),
      );
    }
    if ((u?.pronouns ?? '').trim().isNotEmpty) {
      details.add(
        _ProfileInfoRow(
          icon: TruLuraGlyph.person,
          text: u!.pronouns!.trim(),
        ),
      );
    }

    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _EmotionalIdentityStatement(
          vibe: vibe,
          identity: identity,
          primaryIntent: primaryIntent,
          socialStyle: socialStyle,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final cards = [
              _EmotionalArchetypeCard(
                title: 'Aura archetype',
                value: _archetypeFor(vibe, identity),
                detail:
                    'Reads the room through feeling first, then lets trust form at a human pace.',
                accent: TruLuraTokens.auraPink,
              ),
              _EmotionalArchetypeCard(
                title: 'Connection rhythm',
                value: _rhythmFor(socialStyle),
                detail:
                    'Best with signals that feel honest, steady, and emotionally spacious.',
                accent: TruLuraTokens.auraCyan,
              ),
              _EmotionalArchetypeCard(
                title: 'Energy language',
                value: moodSignature,
                detail:
                    'The identity signals people can understand before the profile says a word.',
                accent: TruLuraBrandColors.glowGold,
              ),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    if (card != cards.last) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TruLuraGlassCard(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (int i = 0; i < details.length; i++) ...[
                details[i],
                if (i < details.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (u?.interests.isNotEmpty ?? false) ...[
          const SizedBox(height: 14),
          TruLuraGlassCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: u!.interests
                      .map(
                        (interest) => TruLuraGlowPill(
                          label: interest,
                          selected: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _EmotionalNeedsCard(
          needs: [
            'clear intent',
            'gentle consistency',
            'room to regulate',
            'playful emotional honesty',
          ],
          communicationStyle:
              'Warm signals land best when they feel specific, unforced, and paced with care.',
        ),
      ],
    );
  }

  Widget _buildUnifiedFeedTab() {
    final items = _feedDemoContent.profileItems(
      user: _currentUser,
      posts: _myPosts,
      quizResults: _quizResults,
    );
    return ListView.separated(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length + (_myPosts.isEmpty ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (_myPosts.isEmpty && i == 0) {
          return TruluraFeedEmptyState(
            icon: TruLuraGlyph.edit,
            title: 'You haven\'t posted yet',
            message:
                'Share your first vibe, styled text, image moment, or quiz insight when you are ready.',
            actions: [
              TruStateAction(
                label: 'Create post',
                glyph: TruLuraGlyph.edit,
                onTap: () => TruNavigation.pushWithReturnTo(
                  context,
                  AppRoutes.createPost,
                ),
                primary: true,
              ),
            ],
          );
        }
        final item = items[_myPosts.isEmpty ? i - 1 : i];
        return TruluraFeedItemRenderer(item: item);
      },
    );
  }

  // ignore: unused_element
  Widget _buildFeedTab() {
    if (_myPosts.isEmpty) {
      return TruStatePanel(
        glyph: TruLuraGlyph.edit,
        title: 'You haven’t posted yet',
        message:
            'Share your first vibe or a short visual post so your profile feels more alive.',
        actions: [
          TruStateAction(
              label: 'Create post',
              glyph: TruLuraGlyph.edit,
              onTap: () =>
                  TruNavigation.pushWithReturnTo(context, AppRoutes.createPost),
              primary: true)
        ],
      );
    }
    return ListView.separated(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _myPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = _myPosts[i];
        return TruLuraGlassCard(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.type.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              if (p.type == 'image' || p.type == 'video')
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.28),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    p.caption ?? p.content,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                )
              else if (p.content.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.backgroundColorHex != null
                        ? Color(
                            int.parse(
                              '0xFF${p.backgroundColorHex!.replaceFirst('#', '')}',
                            ),
                          ).withValues(alpha: 0.82)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    p.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          fontWeight: p.textStyle == 'editorial'
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                  ),
                ),
              if (p.moodTag != null) ...[
                const SizedBox(height: 10),
                Text(p.moodTag!,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentTab() {
    final u = _currentUser;
    final hasExpression = (u?.expressionPromptAnswer ?? '').trim().isNotEmpty ||
        (u?.expressionVibeTag ?? '').trim().isNotEmpty ||
        (u?.expressionShortPost ?? '').trim().isNotEmpty;
    if (hasExpression) {
      return ListView(
        primary: false,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          TruLuraGlassCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expression seed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved expression layers are already shaping how your profile reads before full posting history builds up.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                ),
                if ((u?.expressionPromptAnswer ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ProfileContentBlock(
                    title: 'Prompt answer',
                    body: u!.expressionPromptAnswer!.trim(),
                  ),
                ],
                if ((u?.expressionVibeTag ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ProfileContentBlock(
                    title: 'Expression vibe',
                    body: u!.expressionVibeTag!.trim(),
                  ),
                ],
                if ((u?.expressionShortPost ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ProfileContentBlock(
                    title: 'Short post',
                    body: u!.expressionShortPost!.trim(),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
    return TruStatePanel(
      glyph: TruLuraGlyph.tv,
      title: 'No content yet',
      message:
          'Video, image, and styled text posts will show up here as your profile starts to express itself.',
      actions: [
        TruStateAction(
            label: 'Go to Feed',
            glyph: TruLuraGlyph.inbox,
            onTap: () => _tabController.animateTo(1),
            primary: true)
      ],
    );
  }

  Widget _buildCompatibilityTab() {
    final u = _currentUser;
    final appState = context.watch<AppState>();
    if (u == null) {
      return TruStatePanel(
        glyph: TruLuraGlyph.insights,
        title: 'Compatibility is offline',
        message:
            'Sign in and complete onboarding to generate your compatibility layers.',
        actions: [
          TruStateAction(
              label: 'Finish profile',
              glyph: TruLuraGlyph.edit,
              onTap: () => context.push(Uri(
                      path: AppRoutes.onboardingProfileSetup,
                      queryParameters: {
                        'returnTo': GoRouterState.of(context).uri.toString()
                      }).toString()),
              primary: true)
        ],
      );
    }

    final hasRealQuizResults = appState.deeperQuizCompleted;
    final hasMicroQuizResults =
        appState.microQuizCompleted && !appState.deeperQuizCompleted;
    final hasBasicPersonalization = appState.basicPersonalizationCompleted;
    final hasPersonalizationQuiz = appState.hasPersonalizationQuiz;
    final interestCount = u.interests.length;
    final report = _buildCompatibilityReport(
      user: u,
      quizScores: hasPersonalizationQuiz
          ? appState.quizResults
          : _temporaryQuizFallback,
    );
    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!hasRealQuizResults)
          _ProfileGrowthPromptCard(
            hasMicroQuiz: hasMicroQuizResults,
            onTap: () => context.push(
              Uri(
                path: hasPersonalizationQuiz
                    ? AppRoutes.quiz
                    : AppRoutes.microQuiz,
                queryParameters: {
                  if (!hasPersonalizationQuiz)
                    'quiz': TruQuizEngine.friendshipEnergyMatchQuizId,
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            ),
          ),
        if (!hasRealQuizResults) const SizedBox(height: 12),
        if (hasRealQuizResults) ...[
          const TruInlineBanner(
            glyph: TruLuraGlyph.insights,
            text:
                'Compatibility is currently using your saved deeper-quiz traits to tune emotional, intellectual, and lifestyle fit.',
          ),
          const SizedBox(height: 12),
        ],
        if (!hasRealQuizResults) ...[
          TruInlineBanner(
            glyph: TruLuraGlyph.info,
            text: hasMicroQuizResults
                ? 'Quick tuning is active. Aura is already using your current social-style signals, and you can take a deeper quiz anytime for fuller compatibility layers.'
                : hasBasicPersonalization
                    ? (interestCount > 0
                        ? 'Basic personalization is complete. $interestCount interests are saved, and quick tuning is the next step before any deeper quiz.'
                        : 'Basic personalization is complete, and quick tuning is the next step before any deeper quiz.')
                    : 'No quiz or personalization results yet. Start quick tuning to improve what Aura shows you.',
            onTap: () => context.push(
              Uri(
                path: hasPersonalizationQuiz
                    ? AppRoutes.quiz
                    : AppRoutes.microQuiz,
                queryParameters: {
                  if (!hasPersonalizationQuiz)
                    'quiz': TruQuizEngine.friendshipEnergyMatchQuizId,
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ResonanceCompatibilityHeader(
          report: report,
          progress: _atmosphereController.value,
        ),
        const SizedBox(height: 12),
        _AttractionMapCard(
          map: report.attraction,
          progress: _atmosphereController.value,
        ),
        const SizedBox(height: 12),
        _CompatibilityInterpretationCard(
          report: report,
          progress: _atmosphereController.value,
        ),
        const SizedBox(height: 12),
        for (final d in report.dimensions) ...[
          _CompatDimensionCard(dimension: d),
          const SizedBox(height: 12),
        ],
        _QuizCard(
          results: _quizResults,
          deepResults: _deepQuizResults,
          hasBasicPersonalization: hasBasicPersonalization,
          hasMicroQuizCompletion: hasMicroQuizResults,
          hasDeeperQuizCompletion: hasRealQuizResults,
          interestCount: interestCount,
          actionLabel: hasRealQuizResults
              ? 'Retake deeper quiz'
              : hasPersonalizationQuiz
                  ? 'Take deeper quiz'
                  : 'Start quick tuning',
          onTakeQuiz: () async {
            await context.push(
              Uri(
                path: hasPersonalizationQuiz
                    ? AppRoutes.quiz
                    : AppRoutes.microQuiz,
                queryParameters: {
                  if (!hasPersonalizationQuiz)
                    'quiz': TruQuizEngine.friendshipEnergyMatchQuizId,
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            );
            if (!mounted) return;
            await _loadUser();
          },
          onTogglePublic: (id, value) async {
            final existing = _quizResults.firstWhere((e) => e.quizId == id);
            await _compat.upsertQuizResult(
              _compat.applyVisibilityChoice(
                existing,
                visibility: value
                    ? TruQuizVisibility.profileOptIn
                    : TruQuizVisibility.privateOnly,
              ),
            );
            await _loadUser();
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildVibesTab() {
    final u = _currentUser;
    final hasVibes = (u?.moodTags.isNotEmpty ?? false);
    if (!hasVibes) {
      return TruStatePanel(
        glyph: TruLuraGlyph.spark,
        title: 'No vibes set yet',
        message: 'Add a prompt or mood so your profile feels more like you.',
        actions: [
          TruStateAction(
              label: 'Pick moods',
              glyph: TruLuraGlyph.spark,
              onTap: () => context.push(Uri(
                      path: AppRoutes.onboardingVibe,
                      queryParameters: {
                        'returnTo': GoRouterState.of(context).uri.toString()
                      }).toString()),
              primary: true)
        ],
      );
    }

    final vibe = (u?.vibeLabel ?? TruVibeLabel.oldSoul).label;
    final moods = u!.moodTags;
    final comfortMode = moods.any((m) =>
            m.toLowerCase().contains('calm') ||
            m.toLowerCase().contains('heal'))
        ? 'restorative quiet'
        : moods.any((m) =>
                m.toLowerCase().contains('spark') ||
                m.toLowerCase().contains('flirt'))
            ? 'warm charge'
            : 'soft presence';
    final socialBattery = moods.length >= 4
        ? 'expressive but selective'
        : 'low-pressure and spacious';

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      children: [
        _VibeWeatherCard(
          vibe: vibe,
          weather: _weatherForVibes(moods, vibe),
          comfortMode: comfortMode,
          socialBattery: socialBattery,
        ),
        const SizedBox(height: 12),
        _VibeClusterField(
          moods: moods,
          accent: TruLuraTokens.auraViolet,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final cards = [
              _EmotionalArchetypeCard(
                title: 'Seasonal state',
                value: moods.length > 2 ? 'many-layered' : 'quiet bloom',
                detail:
                    'The profile is currently tuned toward signals that reveal themselves gradually.',
                accent: TruLuraTokens.auraCyan,
              ),
              _EmotionalArchetypeCard(
                title: 'Compatibility tendency',
                value: 'care before intensity',
                detail:
                    'Matching feels strongest when pacing, care, and curiosity overlap.',
                accent: TruLuraTokens.auraPink,
              ),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  cards.first,
                  const SizedBox(height: 10),
                  cards.last,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: cards.first),
                const SizedBox(width: 10),
                Expanded(child: cards.last),
              ],
            );
          },
        ),
      ],
    );
  }

  String _weatherForVibes(List<String> moods, String vibe) {
    final key = '${moods.join(' ')} $vibe'.toLowerCase();
    if (key.contains('calm') || key.contains('heal')) {
      return 'low moonlight, steady breath';
    }
    if (key.contains('spark') || key.contains('flirt')) {
      return 'warm static, bright edges';
    }
    if (key.contains('reflect') || key.contains('old soul')) {
      return 'deep quiet, slow shimmer';
    }
    return 'soft glow, open signal';
  }

  TruCompatibilityReport _buildCompatibilityReport({
    required User user,
    required Map<String, dynamic> quizScores,
  }) {
    final base = _compat.buildSelfReport(
      viewer: user,
      context: user.activeIdentityMode,
    );
    final emotional = _scoreFor(quizScores, 'emotional');
    final intellectual = _scoreFor(quizScores, 'intellectual');
    final lifestyle = _scoreFor(quizScores, 'lifestyle');
    final overall =
        ((emotional + intellectual + lifestyle) / 3).round().clamp(0, 100);

    return TruCompatibilityReport(
      viewerUserId: base.viewerUserId,
      context: base.context,
      overall: overall,
      attraction: TruAttractionMap(
        emotional: emotional,
        intellectual: intellectual,
        visual: base.attraction.visual,
        cultural: base.attraction.cultural,
        lifestyle: lifestyle,
      ),
      dimensions: <TruCompatibilityDimension>[
        TruCompatibilityDimension(
          key: 'emotional',
          title: 'Emotional Fit',
          score: emotional,
          insight: _compatibilityInsight(
            label: 'Emotional',
            score: emotional,
          ),
        ),
        TruCompatibilityDimension(
          key: 'intellectual',
          title: 'Intellectual Fit',
          score: intellectual,
          insight: _compatibilityInsight(
            label: 'Intellectual',
            score: intellectual,
          ),
        ),
        TruCompatibilityDimension(
          key: 'lifestyle',
          title: 'Lifestyle Flow',
          score: lifestyle,
          insight: _compatibilityInsight(
            label: 'Lifestyle',
            score: lifestyle,
          ),
        ),
      ],
      createdAt: base.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  int _scoreFor(Map<String, dynamic> scores, String key) {
    final value = scores[key];
    if (value is num) return value.round().clamp(0, 100);
    return _temporaryQuizFallback[key] ?? 50;
  }

  String _compatibilityInsight({
    required String label,
    required int score,
  }) {
    if (score >= 80) {
      return '$label alignment is coming through strongly in your current quiz signal.';
    }
    if (score >= 65) {
      return '$label alignment is present and should help Aura tune steadier recommendations.';
    }
    return '$label alignment is still early, so Aura should keep discovery broader for now.';
  }
}

class _ExperienceModesEntry extends StatelessWidget {
  final VoidCallback onTap;
  const _ExperienceModesEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Keep it clean: no splash.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: TruLuraTokens.ink.withValues(alpha: 0.24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            const TruLuraIcon(
                glyph: TruLuraGlyph.spark, size: 18, active: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Experience modes',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900, letterSpacing: -0.1)),
                  const SizedBox(height: 2),
                  Text(
                      'Switch contexts. Some layers like Creator and Luxe stay gated until requirements are met.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TruLuraTokens.textSecondary, height: 1.2)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const TruLuraIcon(glyph: TruLuraGlyph.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ProfileChamberPainter extends CustomPainter {
  final double progress;
  final String vibe;
  final String identity;
  final String presenceLabel;
  final double presenceMotion;
  final double presenceWarmth;

  const _ProfileChamberPainter({
    required this.progress,
    required this.vibe,
    required this.identity,
    required this.presenceLabel,
    required this.presenceMotion,
    required this.presenceWarmth,
  });

  Color get _accentA {
    final key = '$vibe $identity'.toLowerCase();
    if (key.contains('creator')) return TruLuraBrandColors.glowGold;
    if (key.contains('calm') || key.contains('heal')) {
      return TruLuraTokens.auraCyan;
    }
    if (key.contains('dating') || key.contains('spark')) {
      return TruLuraTokens.auraPink;
    }
    return TruLuraTokens.auraViolet;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final accentA = _accentA;
    final accentB = TruLuraTokens.auraCyan;
    final restorative = presenceLabel.contains('low') ||
        presenceLabel.contains('quiet') ||
        presenceLabel.contains('recharge') ||
        presenceLabel.contains('hidden') ||
        presenceLabel.contains('overwhelmed');
    final motion = presenceMotion.clamp(0.35, 1.15);
    final breath = 0.5 + math.sin(progress * math.pi * 2 * motion) * 0.5;

    final fog = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(-0.48 + breath * 0.16, -0.72),
        radius: 0.95 + breath * 0.16,
        colors: [
          accentA.withValues(alpha: restorative ? 0.095 : 0.16),
          accentB.withValues(alpha: restorative ? 0.035 : 0.055),
          Colors.transparent,
        ],
        stops: const [0, 0.42, 1],
      ).createShader(rect);
    canvas.drawRect(rect, fog);

    final lowerFog = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(0.62, 0.58 - breath * 0.12),
        radius: 1.10,
        colors: [
          Color.lerp(
            TruLuraTokens.auraCyan,
            TruLuraTokens.auraPink,
            presenceWarmth.clamp(0.0, 1.0),
          )!
              .withValues(alpha: restorative ? 0.050 : 0.090),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, lowerFog);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.plus
      ..color = accentA.withValues(alpha: 0.055 + breath * 0.030);
    final heroCenter = Offset(size.width * 0.50, size.height * 0.18);
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: heroCenter.translate(
            math.sin(progress * math.pi * 2 + i) * 6,
            i * 10.0,
          ),
          width: size.width * (0.56 + i * 0.14 + breath * 0.03),
          height: 110 + i * 42 + breath * 18,
        ),
        ringPaint,
      );
    }

    final particlePaint = Paint()..blendMode = BlendMode.plus;
    final particleCount = restorative
        ? 10
        : identity.toLowerCase().contains('creator')
            ? 26
            : 18;
    for (var i = 0; i < particleCount; i++) {
      final seed = i * 37.0;
      final x = (math.sin(seed + progress * 2.4 + i) * 0.5 + 0.5) * size.width;
      final y = ((i / 18) * size.height +
              progress * motion * (24 + (i % 4) * 8) +
              math.cos(seed) * 22) %
          size.height;
      particlePaint.color = (i.isEven ? accentA : accentB)
          .withValues(alpha: (restorative ? 0.020 : 0.035) + (i % 3) * 0.010);
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.55, particlePaint);
    }

    final tempColor = identity.toLowerCase().contains('dating')
        ? TruLuraTokens.auraPink
        : vibe.toLowerCase().contains('calm') ||
                vibe.toLowerCase().contains('heal')
            ? TruLuraTokens.auraCyan
            : accentA;
    final temperature = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin: Alignment(-1 + breath * 0.12, -0.1),
        end: Alignment(1, 0.9 - breath * 0.12),
        colors: [
          Colors.transparent,
          tempColor.withValues(alpha: restorative ? 0.020 : 0.035),
          Colors.white.withValues(alpha: 0.010),
          Colors.transparent,
        ],
        stops: const [0.0, 0.36, 0.52, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, temperature);

    final phrases = _floatingPhrases;
    for (var i = 0; i < phrases.length; i++) {
      final alpha = (restorative ? 0.035 : 0.050) +
          math.sin(progress * math.pi * 2 * motion + i) * 0.014;
      final painter = TextPainter(
        text: TextSpan(
          text: phrases[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: alpha.clamp(0.028, 0.07)),
            fontSize: 11 + (i % 2),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.46);
      final x = size.width * (i.isEven ? 0.08 : 0.58) +
          math.sin(progress * math.pi * 2 + i) * 10;
      final y = size.height * (0.24 + i * 0.17) - progress * (8 + i * 2) % 22;
      painter.paint(canvas, Offset(x, y));
    }
  }

  List<String> get _floatingPhrases {
    final key = '$vibe $identity'.toLowerCase();
    if (key.contains('dating') || key.contains('spark')) {
      return const ['warm pull', 'soft courage', 'signal open'];
    }
    if (key.contains('creator')) {
      return const ['creative field', 'bright archive', 'alive in color'];
    }
    if (key.contains('calm') || key.contains('heal')) {
      return const ['safe breath', 'steady light', 'held gently'];
    }
    if (key.contains('old') || key.contains('reflect')) {
      return const ['deep signal', 'quiet knowing', 'inner layer'];
    }
    return const ['living aura', 'open room', 'soft presence'];
  }

  @override
  bool shouldRepaint(covariant _ProfileChamberPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.vibe != vibe ||
        oldDelegate.identity != identity ||
        oldDelegate.presenceLabel != presenceLabel ||
        oldDelegate.presenceMotion != presenceMotion ||
        oldDelegate.presenceWarmth != presenceWarmth;
  }
}

class _EmotionalIdentityStatement extends StatelessWidget {
  final String vibe;
  final String identity;
  final String primaryIntent;
  final String socialStyle;

  const _EmotionalIdentityStatement({
    required this.vibe,
    required this.identity,
    required this.primaryIntent,
    required this.socialStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 28,
      depth: true,
      glow: TruLuraTokens.auraPink,
      tint: TruLuraTokens.auraPink.withValues(alpha: 0.035),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftConstellationPainter(
                  accentA: TruLuraTokens.auraPink,
                  accentB: TruLuraTokens.auraCyan,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signature field',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  )),
              const SizedBox(height: 8),
              Text(
                '$vibe energy in $identity mode, tuned for $primaryIntent with $socialStyle pacing.',
                style: t.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.80),
                  height: 1.42,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentityStory extends StatelessWidget {
  final String archetype;
  final int journeyMoments;
  final int constellationSignals;
  final String rhythm;

  const _ProfileIdentityStory({
    required this.archetype,
    required this.journeyMoments,
    required this.constellationSignals,
    required this.rhythm,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Emotional Archetype',
        archetype,
        TruLuraGlyph.spark,
        TruLuraBrandColors.glowGold
      ),
      (
        'Journey',
        '$journeyMoments ${journeyMoments == 1 ? 'moment' : 'moments'} shaping your story',
        TruLuraGlyph.pin,
        TruLuraTokens.auraViolet
      ),
      ('Connection Style', rhythm, TruLuraGlyph.sync, TruLuraTokens.auraCyan),
      (
        'Personal Constellation',
        '$constellationSignals living ${constellationSignals == 1 ? 'signal' : 'signals'}',
        TruLuraGlyph.star,
        TruLuraTokens.auraPink
      ),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        primary: false,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 220,
            child: Stack(
              children: [
                Positioned(
                  left: 14,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 1,
                    color: item.$4.withValues(alpha: 0.28),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TruLuraIcon(
                            glyph: item.$3,
                            size: 18,
                            color: item.$4,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: TruLuraTokens.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        item.$2,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TruLuraTokens.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileWeatherBand extends StatelessWidget {
  final String vibe;
  final String identity;
  final String mood;
  final double progress;

  const _ProfileWeatherBand({
    required this.vibe,
    required this.identity,
    required this.mood,
    required this.progress,
  });

  String get _state {
    final key = '$vibe $identity $mood'.toLowerCase();
    if (key.contains('calm') || key.contains('heal')) {
      return 'quiet identity layer';
    }
    if (key.contains('spark') || key.contains('dating')) {
      return 'warm signal bloom';
    }
    if (key.contains('creator')) return 'cinematic expression field';
    return 'reflective identity drift';
  }

  String get _soundHook {
    final key = '$vibe $mood'.toLowerCase();
    if (key.contains('calm') || key.contains('heal')) return 'soft chime bed';
    if (key.contains('spark') || key.contains('flirt')) return 'light pulse';
    return 'quiet shimmer';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Adaptive sound design hook: $_soundHook',
      child: TruLuraGlassCard(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
        tint: TruLuraTokens.auraCyan.withValues(alpha: 0.026),
        glow: TruLuraTokens.auraCyan,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WeatherBandPainter(progress: progress),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        TruLuraTokens.auraCyan.withValues(alpha: 0.46),
                        TruLuraTokens.auraViolet.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const TruLuraIcon(
                    glyph: TruLuraGlyph.moon,
                    size: 18,
                    active: true,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _state,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$mood signal in $identity identity',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: TruLuraTokens.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _CompatSignalPill(_soundHook),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherBandPainter extends CustomPainter {
  final double progress;

  const _WeatherBandPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          TruLuraTokens.auraCyan.withValues(alpha: 0.18),
          TruLuraTokens.auraPink.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(rect);
    final y = size.height * (0.56 + math.sin(progress * math.pi * 2) * 0.08);
    final path = Path()..moveTo(size.width * -0.04, y);
    path.cubicTo(size.width * 0.24, y - 9, size.width * 0.58, y + 11,
        size.width * 1.04, y - 4);
    canvas.drawPath(path, wave);
  }

  @override
  bool shouldRepaint(covariant _WeatherBandPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _EmotionalArchetypeCard extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final Color accent;

  const _EmotionalArchetypeCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(13),
      tint: accent.withValues(alpha: 0.035),
      glow: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: t.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 7),
          Text(value,
              style: t.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.05,
              )),
          const SizedBox(height: 7),
          Text(detail,
              style: t.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.70),
                height: 1.32,
              )),
        ],
      ),
    );
  }
}

class _EmotionalNeedsCard extends StatelessWidget {
  final List<String> needs;
  final String communicationStyle;

  const _EmotionalNeedsCard({
    required this.needs,
    required this.communicationStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      tint: TruLuraTokens.auraCyan.withValues(alpha: 0.030),
      glow: TruLuraTokens.auraCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emotional needs',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final need in needs)
                TruLuraGlowPill(
                  label: need,
                  selected: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            communicationStyle,
            style: t.bodySmall?.copyWith(
              color: TruLuraTokens.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VibeWeatherCard extends StatelessWidget {
  final String vibe;
  final String weather;
  final String comfortMode;
  final String socialBattery;

  const _VibeWeatherCard({
    required this.vibe,
    required this.weather,
    required this.comfortMode,
    required this.socialBattery,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 30,
      depth: true,
      glow: TruLuraTokens.auraViolet,
      tint: TruLuraTokens.auraViolet.withValues(alpha: 0.035),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftConstellationPainter(
                  accentA: TruLuraTokens.auraViolet,
                  accentB: TruLuraBrandColors.glowGold,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current identity state',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(vibe,
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  )),
              const SizedBox(height: 8),
              Text(weather,
                  style: t.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    height: 1.36,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CompatSignalPill(comfortMode),
                  _CompatSignalPill(socialBattery),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VibeClusterField extends StatelessWidget {
  final List<String> moods;
  final Color accent;

  const _VibeClusterField({
    required this.moods,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      tint: accent.withValues(alpha: 0.028),
      glow: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood clusters',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: moods
                .map((mood) => TruLuraGlowPill(
                      label: mood,
                      selected: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                    ))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SoftConstellationPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;

  const _SoftConstellationPainter({
    required this.accentA,
    required this.accentB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..blendMode = BlendMode.plus
      ..color = accentA.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.32)
      ..cubicTo(size.width * 0.32, size.height * 0.12, size.width * 0.58,
          size.height * 0.64, size.width * 0.92, size.height * 0.28);
    canvas.drawPath(path, paint);

    final dot = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.10 + i * 0.13);
      final y = size.height * (0.26 + math.sin(i * 1.7) * 0.18);
      dot.color = (i.isEven ? accentA : accentB).withValues(alpha: 0.16);
      canvas.drawCircle(Offset(x, y), 1.8 + (i % 2), dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftConstellationPainter oldDelegate) {
    return oldDelegate.accentA != accentA || oldDelegate.accentB != accentB;
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        children: [
          TruLuraGlassCard(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              children: const [
                Align(
                    alignment: Alignment.centerRight,
                    child: TruSkeletonBox(width: 38, height: 38, radius: 12)),
                SizedBox(height: 10),
                TruSkeletonCircle(size: 90),
                SizedBox(height: 16),
                TruSkeletonBox(width: 200, height: 18, radius: 10),
                SizedBox(height: 10),
                TruSkeletonBox(width: 140, height: 14, radius: 10),
                SizedBox(height: 14),
                TruSkeletonBox(width: 190, height: 40, radius: 999),
                SizedBox(height: 12),
                TruSkeletonBox(width: double.infinity, height: 14, radius: 10),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const TruSkeletonBox(width: double.infinity, height: 54, radius: 22),
          const SizedBox(height: 14),
          const TruSkeletonBox(width: double.infinity, height: 240, radius: 22),
        ],
      ),
    );
  }
}

class _AuraMatchPill extends StatefulWidget {
  final int percent;
  final VoidCallback onTap;

  const _AuraMatchPill({required this.percent, required this.onTap});

  @override
  State<_AuraMatchPill> createState() => _AuraMatchPillState();
}

class _AuraMatchPillState extends State<_AuraMatchPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.98 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TruLuraTokens.auraPink.withValues(alpha: 0.95),
                TruLuraTokens.auraViolet.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: TruLuraTokens.auraViolet.withValues(alpha: 0.22),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TruLuraIcon(
                  glyph: TruLuraGlyph.spark,
                  size: 18,
                  active: true,
                  color: Colors.white),
              const SizedBox(width: 10),
              Text('${widget.percent}% Aura Match',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final TruLuraGlyph icon;
  final String text;

  const _ProfileInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        TruLuraIcon(
            glyph: icon,
            size: 18,
            active: false,
            color: cs.onSurface.withValues(alpha: 0.62)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _ProfileContentBlock extends StatelessWidget {
  final String title;
  final String body;

  const _ProfileContentBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _IdentityModeSwitcher extends StatelessWidget {
  final TruIdentityMode selected;
  final ValueChanged<TruIdentityMode> onSelected;
  const _IdentityModeSwitcher(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = const [
      TruIdentityMode.social,
      TruIdentityMode.dating,
      TruIdentityMode.creator,
      TruIdentityMode.luxe,
      TruIdentityMode.friendship,
    ];
    final idx = options.indexOf(selected).clamp(0, options.length - 1);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: TruLuraSurfaces.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * idx,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: TruLuraTokens.auraGradient(opacity: 0.95),
                    boxShadow: TruLuraTokens.softGlow(TruLuraTokens.auraViolet)
                        .map((s) => s.copyWith(
                            blurRadius: s.blurRadius * 0.7,
                            color: s.color.withValues(alpha: 0.16)))
                        .toList(),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final m in options)
                    Expanded(
                      child: _IdentityModeItem(
                        label: m.label,
                        selected: m == selected,
                        onTap: () => onSelected(m),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityModeItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IdentityModeItem(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: selected
                      ? Colors.white
                      : cs.onSurface.withValues(alpha: 0.70),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: 0.2,
                ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}

class _VibePicker extends StatelessWidget {
  final TruVibeLabel value;
  final ValueChanged<TruVibeLabel> onChanged;
  const _VibePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: TruLuraSurfaces.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TruVibeLabel>(
          value: value,
          isExpanded: true,
          items: TruVibeLabel.values
              .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _AnonToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _AnonToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color:
            cs.surfaceContainerHighest.withValues(alpha: enabled ? 0.20 : 0.12),
        border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.10),
            width: TruLuraSurfaces.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Anonymous',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          TruToggle(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CompatibilityHeader extends StatelessWidget {
  final TruCompatibilityReport report;
  const _CompatibilityHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: TruLuraTokens.auraGradient(opacity: 0.95),
              boxShadow: TruLuraTokens.softGlow(TruLuraTokens.auraViolet)
                  .map(
                      (s) => s.copyWith(color: s.color.withValues(alpha: 0.18)))
                  .toList(),
            ),
            child: Center(
                child: Text('${report.overall}%',
                    style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compatibility Report',
                    style:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Mode-aware output: ${report.context.label}. Not a single score — layered dimensions + attraction mapping.',
                  style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResonanceCompatibilityHeader extends StatelessWidget {
  final TruCompatibilityReport report;
  final double progress;
  const _ResonanceCompatibilityHeader({
    required this.report,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 30,
      depth: true,
      glow: TruLuraTokens.auraPink,
      tint: TruLuraTokens.auraPink.withValues(alpha: 0.035),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -40,
            width: 180,
            height: 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    TruLuraTokens.auraPink.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CompatibilityFieldPainter(
                  progress: progress,
                  overall: report.overall,
                ),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: CustomPaint(
                  painter: _CompatibilityResonancePainter(
                    percent: report.overall,
                    accentA: TruLuraTokens.auraPink,
                    accentB: TruLuraTokens.auraCyan,
                    progress: progress,
                  ),
                  child: Center(
                    child: Text(
                      _resonanceLabel(report.overall),
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compatibility snapshot',
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${report.context.label} is reading as layered attraction, not a flat score.',
                      style: t.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        const _CompatSignalPill('emotional pull'),
                        const _CompatSignalPill('aura overlap'),
                        const _CompatSignalPill('pace match'),
                        _CompatSignalPill(_tensionLabel(report)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resonanceLabel(int score) {
    if (score >= 82) return 'deep';
    if (score >= 68) return 'warm';
    return 'open';
  }

  String _tensionLabel(TruCompatibilityReport report) {
    final scores = [
      report.attraction.emotional,
      report.attraction.intellectual,
      report.attraction.visual,
      report.attraction.cultural,
      report.attraction.lifestyle,
    ];
    final spread = scores.reduce(math.max) - scores.reduce(math.min);
    if (spread >= 32) return 'creative tension';
    if (report.overall >= 78) return 'low friction';
    return 'still forming';
  }
}

class _CompatibilityFieldPainter extends CustomPainter {
  final double progress;
  final int overall;

  const _CompatibilityFieldPainter({
    required this.progress,
    required this.overall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final normalized = (overall / 100).clamp(0.0, 1.0);
    final breath = 0.5 + math.sin(progress * math.pi * 2) * 0.5;
    final field = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(0.42 - breath * 0.18, 0.36),
        radius: 0.78,
        colors: [
          TruLuraTokens.auraCyan.withValues(alpha: 0.060 + normalized * 0.055),
          TruLuraTokens.auraPink.withValues(alpha: 0.040),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, field);

    final tension = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = TruLuraBrandColors.glowGold.withValues(alpha: 0.10);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.30 + i * 0.20 + breath * 0.03);
      final path = Path()
        ..moveTo(size.width * 0.18, y)
        ..cubicTo(size.width * 0.38, y - 10, size.width * 0.58, y + 12,
            size.width * 0.86, y - 4);
      canvas.drawPath(path, tension);
    }

    final gravity = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          TruLuraTokens.auraPink.withValues(alpha: 0.13 + normalized * 0.10),
          TruLuraTokens.auraCyan.withValues(alpha: 0.08 + normalized * 0.08),
          Colors.transparent,
        ],
      ).createShader(rect);
    final gravityCenter = Offset(size.width * (0.55 - breath * 0.08),
        size.height * (0.48 + math.cos(progress * math.pi * 2) * 0.03));
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: gravityCenter,
          width: size.width * (0.34 + i * 0.14 + normalized * 0.10),
          height: size.height * (0.28 + i * 0.10),
        ),
        gravity,
      );
    }

    final syncPaint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 5; i++) {
      final phase = progress * math.pi * 2 + i * 1.17;
      final x = size.width * (0.20 + i * 0.14 + math.sin(phase) * 0.018);
      final y = size.height * (0.32 + math.cos(phase * 0.8) * 0.14);
      syncPaint.shader = RadialGradient(
        colors: [
          (i.isEven ? TruLuraTokens.auraPink : TruLuraTokens.auraCyan)
              .withValues(alpha: 0.16 * normalized),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 18));
      canvas.drawCircle(Offset(x, y), 18, syncPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompatibilityFieldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.overall != overall;
  }
}

class _CompatibilityResonancePainter extends CustomPainter {
  final int percent;
  final Color accentA;
  final Color accentB;
  final double progress;

  const _CompatibilityResonancePainter({
    required this.percent,
    required this.accentA,
    required this.accentB,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final score = (percent / 100).clamp(0.0, 1.0);
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          accentA.withValues(alpha: 0.36),
          accentB.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.48));
    canvas.drawCircle(center, size.width * 0.48, glow);

    final ringRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.78,
      height: size.height * 0.78,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        colors: [
          accentA.withValues(alpha: 0.90),
          accentB.withValues(alpha: 0.68),
          Colors.white.withValues(alpha: 0.28),
          accentA.withValues(alpha: 0.90),
        ],
      ).createShader(ringRect);
    canvas.drawArc(ringRect, -math.pi / 2, math.pi * 2 * score, false, ring);

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = accentB.withValues(alpha: 0.30);
    canvas.drawArc(ringRect.inflate(8), 0.5, math.pi * 1.2, false, orbit);

    final tensionArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color =
          TruLuraBrandColors.glowGold.withValues(alpha: 0.12 + score * 0.10);
    canvas.drawArc(
      ringRect.inflate(16 + math.sin(progress * math.pi * 2) * 2),
      math.pi * 0.35 + progress * 0.25,
      math.pi * (0.32 + score * 0.38),
      false,
      tensionArc,
    );

    final dotPaint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 4; i++) {
      final angle =
          -math.pi / 2 + (math.pi * 2 * score) + i * 0.92 + progress * 6.28;
      final r = size.width * (0.34 + i * 0.025);
      dotPaint.color =
          (i.isEven ? accentA : accentB).withValues(alpha: 0.26 + score * 0.22);
      canvas.drawCircle(
        Offset(
            center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r),
        2.2,
        dotPaint,
      );
    }

    final overlapPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withValues(alpha: 0.060 + score * 0.050);
    canvas.drawCircle(
      center.translate(-size.width * 0.07, 0),
      size.width * (0.16 + score * 0.04),
      overlapPaint,
    );
    canvas.drawCircle(
      center.translate(size.width * 0.07, 0),
      size.width * (0.16 + score * 0.04),
      overlapPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompatibilityResonancePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.progress != progress;
  }
}

class _CompatSignalPill extends StatelessWidget {
  final String label;

  const _CompatSignalPill(this.label);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: TruLuraTokens.auraViolet.withValues(alpha: 0.10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: TruLuraTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _ProfileGrowthPromptCard extends StatelessWidget {
  final bool hasMicroQuiz;
  final VoidCallback onTap;

  const _ProfileGrowthPromptCard({
    required this.hasMicroQuiz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile growth',
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            hasMicroQuiz
                ? 'Friendship Energy Match is already saved. If you want a fuller read, the deeper compatibility quiz is the next layer.'
                : 'Take Friendship Energy Match for a lightweight read on the kinds of friends and prompts that fit your energy best.',
            style: t.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.74),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onTap,
            child: Text(
              hasMicroQuiz
                  ? 'Take deeper quiz'
                  : 'Start Friendship Energy Match',
            ),
          ),
        ],
      ),
    );
  }
}

class _AttractionMapCard extends StatelessWidget {
  final TruAttractionMap map;
  final double progress;
  const _AttractionMapCard({required this.map, required this.progress});

  Widget _bar(BuildContext context,
      {required String label, required int score}) {
    final t = Theme.of(context).textTheme;
    final accent = switch (label) {
      'Emotional' => TruLuraTokens.auraPink,
      'Intellectual' => TruLuraTokens.auraCyan,
      'Visual' => TruLuraTokens.auraViolet,
      'Cultural' => TruLuraBrandColors.glowGold,
      _ => TruLuraBrandColors.neonBlue,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 96,
              child: Text(label,
                  style: t.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: TruLuraTokens.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
            child: SizedBox(
              height: 32,
              child: CustomPaint(
                painter: _AuraFrequencyPainter(
                  score: score,
                  accent: accent,
                  progress: progress,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
              width: 62,
              child: Text(_signalLabel(score),
                  textAlign: TextAlign.right,
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  String _signalLabel(int score) {
    if (score >= 82) return 'deep';
    if (score >= 68) return 'warm';
    if (score >= 52) return 'soft';
    return 'early';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 28,
      depth: true,
      glow: TruLuraTokens.auraCyan,
      tint: TruLuraTokens.auraCyan.withValues(alpha: 0.028),
      padding: const EdgeInsets.all(15),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OverlapFieldPainter(map: map, progress: progress),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aura signature map',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  )),
              const SizedBox(height: 4),
              Text(
                'Compatibility expressed as emotional signal movement.',
                style: t.bodySmall?.copyWith(
                  color: TruLuraTokens.textSecondary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              _bar(context, label: 'Emotional', score: map.emotional),
              _bar(context, label: 'Intellectual', score: map.intellectual),
              _bar(context, label: 'Visual', score: map.visual),
              _bar(context, label: 'Cultural', score: map.cultural),
              _bar(context, label: 'Lifestyle', score: map.lifestyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlapFieldPainter extends CustomPainter {
  final TruAttractionMap map;
  final double progress;

  const _OverlapFieldPainter({
    required this.map,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scores = [
      map.emotional,
      map.intellectual,
      map.visual,
      map.cultural,
      map.lifestyle,
    ];
    final colors = [
      TruLuraTokens.auraPink,
      TruLuraTokens.auraCyan,
      TruLuraTokens.auraViolet,
      TruLuraBrandColors.glowGold,
      TruLuraBrandColors.neonBlue,
    ];
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < scores.length; i++) {
      final n = (scores[i] / 100).clamp(0.0, 1.0);
      final drift = math.sin(progress * math.pi * 2 + i) * 0.035;
      final center = Offset(
        size.width * (0.18 + i * 0.16 + drift),
        size.height * (0.68 - n * 0.18),
      );
      paint.shader = RadialGradient(
        colors: [
          colors[i].withValues(alpha: 0.055 + n * 0.045),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 42 + n * 24));
      canvas.drawCircle(center, 42 + n * 24, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlapFieldPainter oldDelegate) {
    return oldDelegate.map != map || oldDelegate.progress != progress;
  }
}

class _CompatibilityInterpretationCard extends StatelessWidget {
  final TruCompatibilityReport report;
  final double progress;

  const _CompatibilityInterpretationCard({
    required this.report,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final scores = [
      report.attraction.emotional,
      report.attraction.intellectual,
      report.attraction.visual,
      report.attraction.cultural,
      report.attraction.lifestyle,
    ];
    final spread = scores.reduce(math.max) - scores.reduce(math.min);
    final text = spread >= 32
        ? 'There is a live tension zone here: some layers pull close while others ask for pacing and translation.'
        : report.overall >= 78
            ? 'The field reads coherent: attraction, pacing, and emotional availability are moving in similar directions.'
            : 'The field is still opening. Keep discovery broad and let repeated signals teach the system.';
    return TruLuraGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      tint: TruLuraBrandColors.glowGold.withValues(alpha: 0.026),
      glow: TruLuraBrandColors.glowGold,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _InterpretationPulsePainter(progress: progress),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adaptive read',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(
                text,
                style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.74),
                  height: 1.38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterpretationPulsePainter extends CustomPainter {
  final double progress;

  const _InterpretationPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final breath = 0.5 + math.sin(progress * math.pi * 2) * 0.5;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(0.78 - breath * 0.18, -0.35 + breath * 0.22),
        radius: 0.86,
        colors: [
          TruLuraBrandColors.glowGold.withValues(alpha: 0.075),
          TruLuraTokens.auraPink.withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _InterpretationPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AuraFrequencyPainter extends CustomPainter {
  final int score;
  final Color accent;
  final double progress;

  const _AuraFrequencyPainter({
    required this.score,
    required this.accent,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final normalized = (score / 100).clamp(0.0, 1.0);
    final centerY = size.height / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), base);

    final wave = Path();
    for (var i = 0; i <= size.width; i++) {
      final x = i.toDouble();
      final phase = x / size.width * math.pi * (2.2 + normalized * 2.4) +
          progress * math.pi * 2;
      final amp = 4 + normalized * 8;
      final y = centerY + math.sin(phase) * amp;
      if (i == 0) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.82),
          Colors.white.withValues(alpha: 0.24),
        ],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);
    canvas.drawPath(wave, wavePaint);

    final node = Offset(size.width * normalized, centerY);
    final nodePaint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.70),
          accent.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: node, radius: 18));
    canvas.drawCircle(node, 18, nodePaint);
    canvas.drawCircle(node, 3.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _AuraFrequencyPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.accent != accent ||
        oldDelegate.progress != progress;
  }
}

class _CompatDimensionCard extends StatelessWidget {
  final TruCompatibilityDimension dimension;
  const _CompatDimensionCard({required this.dimension});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(dimension.title,
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: TruLuraSurfaces.hairline),
                ),
                child: Text('${dimension.score}%',
                    style:
                        t.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(dimension.insight,
              style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.74), height: 1.4)),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final List<TruQuizResult> results;
  final List<TruQuizResult> deepResults;
  final bool hasBasicPersonalization;
  final bool hasMicroQuizCompletion;
  final bool hasDeeperQuizCompletion;
  final int interestCount;
  final String actionLabel;
  final VoidCallback onTakeQuiz;
  final void Function(String quizId, bool isPublic) onTogglePublic;

  const _QuizCard({
    required this.results,
    required this.deepResults,
    required this.hasBasicPersonalization,
    required this.hasMicroQuizCompletion,
    required this.hasDeeperQuizCompletion,
    required this.interestCount,
    required this.actionLabel,
    required this.onTakeQuiz,
    required this.onTogglePublic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final archive = DeepQuizArchiveService();
    final compat = CompatibilityService();
    final r = results
        .where((e) => e.completionLevel == TruQuizCompletionLevel.deeper)
        .cast<TruQuizResult?>()
        .firstOrNull;
    final micro = results
        .where((e) => e.completionLevel == TruQuizCompletionLevel.micro)
        .cast<TruQuizResult?>()
        .firstOrNull;
    final activeResult = r ?? micro;
    final showingDeeper = r != null;
    final visibleDeepInsights = archive.visibleProfileInsights(deepResults);
    final visibleProfileCards = compat.selectedProfileCardResults(results);
    final savedVaultResults = compat.savedQuizVault(results);
    final matchingResults = compat.matchingVisibleResults(results);

    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Quizzes',
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
              TextButton(onPressed: onTakeQuiz, child: Text(actionLabel)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showingDeeper
                ? 'Deeper compatibility quizzes shape your profile behavior, discovery, and matchmaking signals. You control what is public.'
                : 'Micro quizzes add lightweight social-pattern signals you can keep private or show on profile.',
            style: t.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (activeResult == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: TruLuraSurfaces.hairline),
              ),
              child: Text(
                hasMicroQuizCompletion
                    ? 'Quick tuning is already shaping your feed and suggestions. Deeper compatibility traits have not been generated yet.'
                    : hasBasicPersonalization
                        ? (interestCount > 0
                            ? 'Basic personalization is complete and $interestCount interests are saved. Quick tuning is the next layer before a deeper quiz.'
                            : 'Basic personalization is complete. Quick tuning is the next layer before a deeper quiz.')
                        : 'No quiz or personalization results yet. Start quick tuning to begin shaping Aura.',
                style: t.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.76), height: 1.35),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: TruLuraSurfaces.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          showingDeeper
                              ? (hasDeeperQuizCompletion
                                  ? 'Deeper Compatibility Quiz'
                                  : 'Compatibility Quiz')
                              : (activeResult.primaryResult ??
                                  'Friendship Energy Match'),
                          style: t.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TruToggle(
                        value: activeResult.isPublic,
                        onChanged: (v) =>
                            onTogglePublic(activeResult.quizId, v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!showingDeeper &&
                      (activeResult.primaryResult?.trim().isNotEmpty ??
                          false)) ...[
                    Text(
                      activeResult.resultSummary ??
                          'Saved as a lightweight personalization signal.',
                      style: t.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.76),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: activeResult.traitScores.entries
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.22),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  width: TruLuraSurfaces.hairline),
                            ),
                            child: Text('${e.key}: ${e.value}',
                                style: t.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w900)),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeResult.isPublic
                        ? 'Visible on your profile and usable for personalization.'
                        : 'Private to you. Used by the system for personalization.',
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Selected profile cards',
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (visibleProfileCards.isEmpty)
            Text(
              'Only quiz results you explicitly save as profile-visible appear here.',
              style: t.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            )
          else
            for (final result in visibleProfileCards.take(3)) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.primaryResult ?? result.quizId,
                      style:
                          t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if ((result.resultSummary ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        result.resultSummary!,
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.76),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          const SizedBox(height: 4),
          Text(
            'Saved vault: ${savedVaultResults.length} • Matching-only: ${matchingResults.length}',
            style: t.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          if (visibleDeepInsights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Healing Archive highlights',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Only limited, opt-in insights appear here. Full reflections stay private by default.',
              style: t.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            for (final insight in visibleDeepInsights.take(2)) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style:
                          t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insight.primaryResult,
                      style:
                          t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (insight.supportingInsights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        insight.supportingInsights.join(' • '),
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.74),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
