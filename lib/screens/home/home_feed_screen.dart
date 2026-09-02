import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/feed_item.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/visibility_service.dart';
import 'package:trulura/services/feed_behavior_service.dart';
import 'package:trulura/services/feed_distribution_engine.dart';
import 'package:trulura/services/aura_shield_service.dart';
import 'package:trulura/services/safety_center_service.dart';
import 'package:trulura/services/compatibility_service.dart';
import 'package:trulura/services/profile_completion_service.dart';
import 'package:trulura/services/quiz_engine.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/theme/mood_colors.dart';
import 'package:trulura/widgets/trulura_event_carousel_row.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_world_layers.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulse;
  final PostService _postService = PostService();
  final FeedDistributionEngine _engine = const FeedDistributionEngine();
  final AuraShieldService _auraShield = AuraShieldService();
  final SafetyCenterService _safetyCenter = SafetyCenterService();
  final CompatibilityService _compat = CompatibilityService();
  final ProfileCompletionService _profileCompletion =
      const ProfileCompletionService();

  bool _didSyncTabToMode = false;

  _AuraFeedKind? _lastSuggested;
  DateTime? _lastSuggestionAt;

  RealtimeChannel? _postsChannel;
  RealtimeChannel? _reactionsChannel;
  List<Post> _posts = const <Post>[];
  Map<String, int> _glowCounts = const <String, int>{};
  Set<String> _glowedPostIds = const <String>{};
  bool _isLoadingPosts = true;
  Object? _postsError;

  TruFeedBehaviorProfile _behavior = const TruFeedBehaviorProfile();
  bool _behaviorLoading = true;
  TruQuizPersonalization _quizPersonalization =
      const TruQuizPersonalization.empty();
  String? _personalizationUserId;

  late final Map<_AuraFeedKind, ScrollController> _scrollControllers = {
    for (final k in _AuraFeedKind.values) k: ScrollController(),
  };

  /// The current user-selected feed tab order. Stored in [AppProvider] + persisted
  /// by [AppSettingsService].
  ///
  /// Important: we treat this as a view-order only. All policy filtering is still
  /// computed from [TruParticipationContext] + [VisibilityService].
  List<_AuraFeedKind> _tabOrder = _AuraFeedKind.values;

  String _personalizedHeadingSubtitle(TruParticipationContext participation) {
    final base = participation.activePermissions.feedKind.label;
    if (!_quizPersonalization.hasResults) return base;

    final themes = _quizPersonalization.contentThemes.take(2).join(' + ');
    final emphasis = _quizPersonalization.discoveryEmphasis.firstOrNull;
    if (themes.isEmpty && emphasis == null) {
      return '$base tuned for ${_quizPersonalization.emotionalTone} energy.';
    }
    if (themes.isEmpty) {
      return '$base with extra focus on $emphasis.';
    }
    if (emphasis == null) {
      return '$base tuned around $themes.';
    }
    return '$base tuned around $themes with extra focus on $emphasis.';
  }

  @override
  void initState() {
    super.initState();
    // Mode-shaped feed tabs.
    _tabController = TabController(length: 5, vsync: this);
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100));
    _pulse.repeat(reverse: true);
    _tabController.addListener(_onFeedTabChanged);
    _loadInitialPosts();
    _loadBehavior();
    _loadQuizPersonalization();
    FeedBehaviorService.instance.revision.addListener(_onBehaviorChanged);
    _initRealtimeFeed();
  }

  _AuraFeedKind _activeKind() =>
      _tabOrder.elementAt(_tabController.index.clamp(0, _tabOrder.length - 1));

  Color _moodAccentFor(BuildContext context, _AuraFeedKind kind) {
    final app = context.read<AppProvider>();
    final soft = app.softModeEnabled;
    if (!app.moodAdaptiveUiEnabled || soft) {
      return Theme.of(context).colorScheme.primary;
    }

    final u = app.currentUser;
    final mood = (u?.moodTags.isNotEmpty ?? false) ? (u!.moodTags.first) : '';
    // A subtle baseline per feed environment, then mood tint nudges it.
    final base = switch (kind) {
      _AuraFeedKind.forYou => TruLuraBrandColors.neonPurple,
      _AuraFeedKind.aura => TruLuraBrandColors.nebulaIndigo,
      _AuraFeedKind.spark => TruLuraBrandColors.nebulaMagenta,
      _AuraFeedKind.vent => TruLuraBrandColors.nebulaIndigo,
      _AuraFeedKind.trending => TruLuraBrandColors.neonPurple,
    };
    final tint = MoodColors.glow(mood);
    return Color.lerp(base, tint, 0.45) ?? base;
  }

  _AuraFeedKind? _suggestedKind(
      BuildContext context, TruParticipationContext participation) {
    final app = context.read<AppProvider>();
    if (!app.smartFeedSwitchingEnabled) return null;
    if (_behaviorLoading) return null;

    // Never suggest switching out of protected environments the user intentionally entered.
    if (participation.activeMode == TruExperienceMode.vent) {
      return _AuraFeedKind.vent;
    }
    if (participation.isProtectedEmotionalSpace) return _AuraFeedKind.vent;

    // Simple local-first heuristic:
    // - If romantic visibility is high + user mood affinity contains romantic-ish tags -> suggest Spark.
    // - If user is leaning toward heavy moods and sensitivity is high -> suggest Vent.
    // - If user is in creator mode or creator weight high -> suggest Aura (creator) or Trending.
    final topMood = _behavior.moodAffinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final moodKey = topMood.isNotEmpty ? topMood.first.key : '';

    final romanticish = moodKey.contains('rom') ||
        moodKey.contains('crush') ||
        moodKey.contains('love') ||
        moodKey.contains('spicy');
    final heavyish = moodKey.contains('sad') ||
        moodKey.contains('anx') ||
        moodKey.contains('grief') ||
        moodKey.contains('anger');

    if (romanticish &&
        app.feedRomanticVisibility > 0.35 &&
        participation.activeMode.isAdultIntent) {
      return _AuraFeedKind.spark;
    }
    if (romanticish && app.feedRomanticVisibility > 0.60) {
      return _AuraFeedKind.spark;
    }
    if (heavyish && app.feedEmotionalSensitivity > 0.55) {
      return _AuraFeedKind.vent;
    }

    if (app.feedCreatorWeight > 0.60 &&
        participation.activeMode != TruExperienceMode.vent) {
      return _AuraFeedKind.aura;
    }
    if (app.feedContentIntensity > 0.75 &&
        !participation.effectivePermissions.suppressVirality) {
      return _AuraFeedKind.trending;
    }

    return null;
  }

  void _onBehaviorChanged() {
    // Reload the profile so ranking reflects hides/mutes + interaction signals.
    _loadBehavior();
  }

  void _onFeedTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AppProvider>().currentUser?.id;
    if (_personalizationUserId != currentUserId) {
      unawaited(_loadQuizPersonalization());
    }

    // Keep the TabBar order synced with personalization settings.
    final desiredOrder =
        _kindsFromOrder(context.watch<AppProvider>().feedTabOrder);
    if (!_sameOrder(_tabOrder, desiredOrder)) {
      final oldKind = _tabOrder
          .elementAt(_tabController.index.clamp(0, _tabOrder.length - 1));
      _tabOrder = desiredOrder;
      final nextIndex = _tabOrder.indexOf(oldKind);
      if (nextIndex != -1 && nextIndex != _tabController.index) {
        _tabController.index = nextIndex;
      }
    }

    if (_didSyncTabToMode) return;
    final participation =
        context.read<ExperienceModeController>().participationContext;

    final preferred = switch (participation.activeMode) {
      TruExperienceMode.vent => _AuraFeedKind.vent,
      TruExperienceMode.dating ||
      TruExperienceMode.luxe ||
      TruExperienceMode.altIntimate =>
        _AuraFeedKind.spark,
      _ => _AuraFeedKind.aura,
    };
    final desiredIndex = _tabOrder.indexOf(preferred);
    if (desiredIndex != -1) {
      _tabController.index = desiredIndex.clamp(0, _tabController.length - 1);
    }
    _didSyncTabToMode = true;
  }

  bool _sameOrder(List<_AuraFeedKind> a, List<_AuraFeedKind> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<_AuraFeedKind> _kindsFromOrder(List<String> order) {
    final map = {
      'for_you': _AuraFeedKind.forYou,
      'aura': _AuraFeedKind.aura,
      'spark': _AuraFeedKind.spark,
      'vent': _AuraFeedKind.vent,
      'trending': _AuraFeedKind.trending,
    };
    final resolved = <_AuraFeedKind>[];
    for (final key in order) {
      final k = map[key];
      if (k != null && !resolved.contains(k)) resolved.add(k);
    }
    for (final k in _AuraFeedKind.values) {
      if (!resolved.contains(k)) resolved.add(k);
    }
    return resolved;
  }

  @override
  void dispose() {
    try {
      _postsChannel?.unsubscribe();
      _reactionsChannel?.unsubscribe();
    } catch (_) {}

    FeedBehaviorService.instance.revision.removeListener(_onBehaviorChanged);
    _tabController.removeListener(_onFeedTabChanged);
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    _tabController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadBehavior() async {
    try {
      final userId = context.read<AppProvider>().currentUser?.id;
      final profile =
          await FeedBehaviorService.instance.getProfile(userId: userId);
      if (!mounted) return;
      setState(() {
        _behavior = profile;
        _behaviorLoading = false;
      });
    } catch (e) {
      debugPrint('HomeFeedScreen: load behavior failed: $e');
      if (!mounted) return;
      setState(() => _behaviorLoading = false);
    }
  }

  Future<void> _loadQuizPersonalization() async {
    try {
      final userId = context.read<AppProvider>().currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _personalizationUserId = null;
          _quizPersonalization = const TruQuizPersonalization.empty();
        });
        return;
      }
      final personalization = await _compat.getQuizPersonalization(
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _personalizationUserId = userId;
        _quizPersonalization = personalization;
      });
    } catch (e) {
      debugPrint('HomeFeedScreen: load quiz personalization failed: $e');
    }
  }

  Future<void> _loadInitialPosts() async {
    try {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
      final posts = await _postService.getAllPosts();
      debugPrint('HomeFeedScreen._loadInitialPosts posts=${posts.length}');
      if (posts.isNotEmpty) {
        debugPrint(
            'HomeFeedScreen._loadInitialPosts firstPostId=${posts.first.id}');
      }
      final filtered = await _applySafetyDiscoveryFiltering(posts);
      await _loadReactionsForPosts(filtered);
      if (!mounted) return;
      setState(() {
        _posts = filtered;
      });
    } catch (e) {
      truLogStateError('AuraFeed._loadInitialPosts', e);
      if (!mounted) return;
      setState(() {
        _postsError = e;
        _posts = const <Post>[];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _loadReactionsForPosts(List<Post> posts) async {
    try {
      if (!DatabaseService.instance.isInitialized) {
        _glowCounts = const <String, int>{};
        _glowedPostIds = const <String>{};
        return;
      }

      final postIds = posts
          .map((p) => p.id)
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      if (postIds.isEmpty) {
        _glowCounts = const <String, int>{};
        _glowedPostIds = const <String>{};
        return;
      }

      final counts = await _postService.getReactionCounts(postIds: postIds);
      final myIds = await _postService.getMyReactedPostIds(postIds: postIds);
      if (!mounted) return;
      setState(() {
        _glowCounts = counts;
        _glowedPostIds = myIds;
      });
    } catch (e) {
      truLogStateError('AuraFeed._loadReactionsForPosts', e);
    }
  }

  Future<List<Post>> _applySafetyDiscoveryFiltering(List<Post> posts) async {
    try {
      final prefs = await _safetyCenter.getPrefs();
      if (!prefs.auraShieldEnabled) return posts;

      // Local-first approximation of 9.26: if AuraShield has accumulated enough
      // concerning signals about an author (from this device’s experience),
      // suppress them from discovery.
      final uniqueAuthors = posts
          .map((p) => p.userId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (uniqueAuthors.isEmpty) return posts;

      final suppressed = <String>{};
      await Future.wait(uniqueAuthors.map((id) async {
        if (await _auraShield.shouldSuppressUser(id)) suppressed.add(id);
      }));
      if (suppressed.isEmpty) return posts;
      return posts
          .where((p) => !suppressed.contains(p.userId))
          .toList(growable: false);
    } catch (e) {
      debugPrint('HomeFeedScreen: safety filtering failed: $e');
      return posts;
    }
  }

  void _initRealtimeFeed() {
    try {
      if (!DatabaseService.instance.isInitialized) {
        setState(() {
          _postsChannel = null;
          _reactionsChannel = null;
          _postsError = Exception('Database not initialized');
        });
        return;
      }

      final client = DatabaseService.instance.client;
      _postsChannel?.unsubscribe();
      _postsChannel = client
          .channel('public:posts')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'posts',
            callback: (payload) async {
              try {
                final posts = await _postService.getAllPosts();
                debugPrint(
                    'HomeFeedScreen.realtimeRefetch posts=${posts.length}');
                if (posts.isNotEmpty) {
                  debugPrint(
                      'HomeFeedScreen.realtimeRefetch firstPostId=${posts.first.id}');
                }
                final filtered = await _applySafetyDiscoveryFiltering(posts);
                await _loadReactionsForPosts(filtered);
                if (!mounted) return;
                setState(() {
                  _posts = filtered;
                  _postsError = null;
                });
              } catch (e) {
                truLogStateError('AuraFeed.realtimeRefetch', e);
                if (!mounted) return;
                setState(() => _postsError = e);
              }
            },
          )
          .subscribe();

      _reactionsChannel?.unsubscribe();
      _reactionsChannel = client
          .channel('public:post_reactions')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'post_reactions',
            callback: (payload) async {
              // Only refresh reaction meta; no need to refetch posts.
              await _loadReactionsForPosts(_posts);
            },
          )
          .subscribe();
    } catch (e) {
      truLogStateError('AuraFeed._initRealtimeFeed', e);
      setState(() => _postsError = e);
    }
  }

  Future<void> _refreshFeed() async {
    await _loadInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    final participation =
        context.watch<ExperienceModeController>().participationContext;
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    final profileSummary = _profileCompletion.summarize(user);

    final activeKind = _activeKind();
    final accent = _moodAccentFor(context, activeKind);
    final suggested = _suggestedKind(context, participation);
    final cooldownActive = _lastSuggested == suggested &&
        _lastSuggestionAt != null &&
        DateTime.now().difference(_lastSuggestionAt!).inMinutes < 12;
    final shouldSuggest = suggested != null &&
        suggested != activeKind &&
        !app.isLowEnergyContext &&
        !cooldownActive;

    if (!DatabaseService.instance.isInitialized) {
      return TruStatePanel(
        glyph: TruLuraGlyph.info,
        title: 'Supabase isn\'t configured',
        message:
            'This build is missing SUPABASE_URL and SUPABASE_ANON_KEY, so the realtime feed and reactions can\'t load. Open the Supabase panel in Dreamflow and complete Project Setup for this app.',
        actions: [
          TruStateAction(
              label: 'Retry',
              glyph: TruLuraGlyph.spark,
              onTap: () {
                _loadInitialPosts();
                _initRealtimeFeed();
              },
              primary: true),
        ],
      );
    }

    Widget body;
    if (ui == TruUiState.loading) {
      body = _AuraFeedSkeleton(
        header: _AuraScrollHeader(
          participation: participation,
          personalizedSubtitle: _personalizedHeadingSubtitle(participation),
          tabController: _tabController,
          pulse: _pulse,
          tabOrder: _tabOrder,
        ),
      );
    } else if (ui == TruUiState.empty && _posts.isEmpty) {
      final vibe =
          (user?.moodTags.isNotEmpty ?? false) ? user!.moodTags.first : null;
      final intent =
          (user?.intents.isNotEmpty ?? false) ? user!.intents.first : null;
      final title = _quizPersonalization.hasResults
          ? 'Your Aura is ready for curated discovery'
          : vibe != null
              ? 'Your $vibe Aura is waiting for its first signal'
              : 'Your emotional universe is waiting for your energy';
      final message = _quizPersonalization.hasResults
          ? 'We are shaping this space around ${_quizPersonalization.contentThemes.join(', ')} with extra emphasis on ${_quizPersonalization.discoveryEmphasis.join(', ')}.'
          : intent != null && vibe != null
              ? 'You are showing up with a $vibe vibe and $intent intent. Start with communities, people, and prompts that match that energy.'
              : intent != null
                  ? 'Your $intent intent is set. Add a vibe or explore aligned communities to give Aura something to build on.'
                  : vibe != null
                      ? 'Your current vibe is $vibe. Explore communities or take the personalization quiz to help Aura tune discovery.'
                      : 'Start by choosing a vibe, shaping your intent, or exploring communities that feel like you.';
      final actions = <TruStateAction>[
        if (!profileSummary.hasMeaningfulProfile)
          TruStateAction(
            label: 'Complete profile',
            glyph: TruLuraGlyph.person,
            onTap: () => context.push(
              Uri(
                path: AppRoutes.onboardingProfileSetup,
                queryParameters: {
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            ),
            primary: true,
          )
        else if (vibe == null)
          TruStateAction(
            label: 'Set your vibe',
            glyph: TruLuraGlyph.spark,
            onTap: () => context.push(
              Uri(
                path: AppRoutes.onboardingVibe,
                queryParameters: {
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            ),
            primary: true,
          )
        else
          TruStateAction(
            label: 'Explore communities',
            glyph: TruLuraGlyph.explore,
            onTap: () => context.go(AppRoutes.homeTab('explore')),
            primary: true,
          ),
        if (!_quizPersonalization.hasResults)
          TruStateAction(
            label: 'Try Friendship Energy Match',
            glyph: TruLuraGlyph.insights,
            onTap: () => context.push(
              Uri(
                path: AppRoutes.microQuiz,
                queryParameters: {
                  'quiz': TruQuizEngine.friendshipEnergyMatchQuizId,
                  'returnTo': GoRouterState.of(context).uri.toString(),
                },
              ).toString(),
            ),
          )
        else
          TruStateAction(
            label: 'Explore communities',
            glyph: TruLuraGlyph.explore,
            onTap: () => context.go(AppRoutes.homeTab('explore')),
          ),
        TruStateAction(
          label: intent == null ? 'Choose your intent' : 'Create first post',
          glyph: intent == null ? TruLuraGlyph.spark : TruLuraGlyph.edit,
          onTap: () => intent == null
              ? context.push(
                  Uri(
                    path: AppRoutes.onboardingIntent,
                    queryParameters: {
                      'returnTo': GoRouterState.of(context).uri.toString(),
                    },
                  ).toString(),
                )
              : TruNavigation.pushWithReturnTo(
                  context,
                  AppRoutes.createPost,
                ),
        ),
      ];
      body = ListView(
        padding: EdgeInsets.only(bottom: _auraFeedBottomPadding(context)),
        children: [
          _AuraScrollHeader(
            participation: participation,
            personalizedSubtitle: _personalizedHeadingSubtitle(participation),
            tabController: _tabController,
            pulse: _pulse,
            tabOrder: _tabOrder,
          ),
          TruluraFeedLane(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: _FeedFoundationPreview(
              onCreateFirstPost: () => TruNavigation.pushWithReturnTo(
                context,
                AppRoutes.createPost,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TruluraFeedLane(
            child: TruStatePanel(
              glyph: TruLuraGlyph.spark,
              title: title,
              message: message,
              actions: actions,
            ),
          ),
        ],
      );
    } else if (_isLoadingPosts) {
      body = _AuraFeedSkeleton(
        header: _AuraScrollHeader(
          participation: participation,
          personalizedSubtitle: _personalizedHeadingSubtitle(participation),
          tabController: _tabController,
          pulse: _pulse,
          tabOrder: _tabOrder,
        ),
      );
    } else if (_postsError != null) {
      body = TruStatePanel(
        glyph: TruLuraGlyph.info,
        title: 'Couldn’t open your Aura',
        message: 'We couldn’t open your emotional universe right now.',
        actions: [
          TruStateAction(
              label: 'Retry',
              glyph: TruLuraGlyph.spark,
              onTap: _loadInitialPosts,
              primary: true)
        ],
      );
    } else {
      final headerChildren = <Widget>[
        TruluraFeedLane(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _AmbientIntelligenceStrip(
            kind: activeKind,
            lowEnergy: app.isLowEnergyContext,
            personalization: _quizPersonalization,
          ),
        ),
        const SizedBox(height: 6),
        TruluraFeedLane(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: _SocialEcosystemStrip(
            kind: activeKind,
            postCount: _posts.length,
            lowEnergy: app.isLowEnergyContext,
          ),
        ),
        const SizedBox(height: 8),
        TruluraFeedLane(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          maxWidth: kTruluraFeedMaxWidth + 44,
          child: _WorldspaceCurrentCard(
            kind: activeKind,
            lowEnergy: app.isLowEnergyContext,
          ),
        ),
        const SizedBox(height: 6),
        if (_quizPersonalization.hasResults)
          TruluraFeedLane(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _AuraSignalStrip(
              personalization: _quizPersonalization,
              onPrimaryTap: () => context.go(AppRoutes.homeTab('explore')),
            ),
          ),
        if (_quizPersonalization.hasResults) const SizedBox(height: 6),
        if (shouldSuggest)
          TruluraFeedLane(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _SmartSwitchBanner(
              accent: accent,
              from: activeKind,
              to: suggested,
              onTap: () {
                final idx = _tabOrder.indexOf(suggested);
                if (idx != -1) _tabController.animateTo(idx);
                setState(() {
                  _lastSuggested = suggested;
                  _lastSuggestionAt = DateTime.now();
                });
              },
              onDismiss: () => setState(() {
                _lastSuggested = suggested;
                _lastSuggestionAt = DateTime.now();
              }),
            ),
          ),
        if (shouldSuggest) const SizedBox(height: 6),
        if (ui == TruUiState.action) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TruInlineBanner(
              glyph: TruLuraGlyph.spark,
              text: 'Vibe updated • Your Aura feed is reacting to your energy.',
            ),
          ),
          const SizedBox(height: 6),
        ],
      ];

      final resolvedFeedTabs = <Widget>[
        for (final kind in _tabOrder)
          _FeedTabView(
            kind: kind,
            ctx: participation,
            personalization: _quizPersonalization,
            ranked: _rankedForKind(kind, participation),
            controller: _scrollControllers[kind]!,
            onRefresh: _refreshFeed,
            glowCounts: _glowCounts,
            glowedPostIds: _glowedPostIds,
            header: _AuraScrollHeader(
              participation: participation,
              personalizedSubtitle: _personalizedHeadingSubtitle(
                participation,
              ),
              tabController: _tabController,
              pulse: _pulse,
              tabOrder: _tabOrder,
              children: headerChildren,
            ),
          ),
      ];

      if (resolvedFeedTabs.isEmpty) {
        body = const TruStatePanel(
          glyph: TruLuraGlyph.info,
          title: 'Feed unavailable',
          message: 'Aura could not open this community layer right now.',
        );
      } else {
        body = TabBarView(
          controller: _tabController,
          children: resolvedFeedTabs,
        );
      }
    }

    final aura = context.watch<AuraStateController>();
    final auraAccent =
        Color.lerp(accent, aura.auraColor, 0.58) ?? aura.auraColor;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final adaptiveEnabled =
            context.watch<AppProvider>().moodAdaptiveUiEnabled;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                auraAccent.withValues(
                  alpha: adaptiveEnabled ? (0.08 + 0.05 * t) : 0.0,
                ),
                aura.auraColor.withValues(
                  alpha: adaptiveEnabled ? (0.03 + 0.03 * (1 - t)) : 0.0,
                ),
                TruLuraTokens.nebula.withValues(alpha: 0.0),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: body,
        );
      },
    );
  }

  List<Post> _filtered(
      {required List<Post> posts, required TruParticipationContext ctx}) {
    final viewer = context.read<AppProvider>().currentUser;
    return const VisibilityService()
        .filterPosts(posts: posts, ctx: ctx, viewer: viewer);
  }

  List<Post> _postsForKind(_AuraFeedKind kind) {
    return switch (kind) {
      _AuraFeedKind.forYou => _posts,
      _AuraFeedKind.aura => _posts.where((p) {
          final m = p.inferredExperienceMode();
          return m == TruExperienceMode.social ||
              m == TruExperienceMode.friendship ||
              m == TruExperienceMode.creator;
        }).toList(growable: false),
      _AuraFeedKind.spark => _posts.where((p) {
          final m = p.inferredExperienceMode();
          return m == TruExperienceMode.dating ||
              m == TruExperienceMode.luxe ||
              m == TruExperienceMode.altIntimate;
        }).toList(growable: false),
      _AuraFeedKind.vent => _posts
          .where((p) =>
              p.inferredExperienceMode() == TruExperienceMode.vent ||
              p.isAnonymous)
          .toList(growable: false),
      _AuraFeedKind.trending => _posts,
    };
  }

  List<TruRankedPost> _rankedForKind(
      _AuraFeedKind kind, TruParticipationContext ctx) {
    if (_behaviorLoading) return const <TruRankedPost>[];

    final app = context.read<AppProvider>();
    final viewer = app.currentUser;
    final candidates = _postsForKind(kind);
    final visible = _filtered(posts: candidates, ctx: ctx);

    final feedKind = switch (kind) {
      _AuraFeedKind.forYou => TruDiscoveryFeedKind.forYou,
      _AuraFeedKind.aura => TruDiscoveryFeedKind.aura,
      _AuraFeedKind.spark => TruDiscoveryFeedKind.spark,
      _AuraFeedKind.vent => TruDiscoveryFeedKind.vent,
      _AuraFeedKind.trending => TruDiscoveryFeedKind.trending,
    };

    return _engine.rank(
        candidates: visible,
        kind: feedKind,
        ctx: ctx,
        viewer: viewer,
        settings: app,
        behavior: _behavior);
  }

  // NOTE: feed rendering moved into _FeedTabView for keep-alive + per-tab scroll.
}

enum _AuraFeedKind { forYou, aura, spark, vent, trending }

class _AuraScrollHeader extends StatelessWidget {
  final TruParticipationContext participation;
  final String? personalizedSubtitle;
  final TabController tabController;
  final Animation<double> pulse;
  final List<_AuraFeedKind> tabOrder;
  final List<Widget> children;

  const _AuraScrollHeader({
    required this.participation,
    required this.personalizedSubtitle,
    required this.tabController,
    required this.pulse,
    required this.tabOrder,
    this.children = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final activeKind =
        tabOrder.elementAt(tabController.index.clamp(0, tabOrder.length - 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TruluraFeedLane(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          maxWidth: kTruluraFeedMaxWidth + 84,
          child: _AuraWorldHero(kind: activeKind),
        ),
        ...children,
        TruluraFeedLane(
          padding: EdgeInsets.zero,
          child: _AuraPageHeading(
            participation: participation,
            personalizedSubtitle: personalizedSubtitle,
          ),
        ),
        TruluraFeedLane(
          padding: EdgeInsets.zero,
          child: _SecondaryFeedTabsBar(
            controller: tabController,
            pulse: pulse,
            tabOrder: tabOrder,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AuraWorldHero extends StatelessWidget {
  final _AuraFeedKind kind;

  const _AuraWorldHero({required this.kind});

  @override
  Widget build(BuildContext context) {
    final data = (
      overline: 'My emotional universe',
      title: 'Map your emotional universe.',
      subtitle:
          'Aura is where emotional weather, aura pulse, emotional orbit, mood evolution, and reflection journey become one personal world.',
      glyph: TruLuraGlyph.aura,
      primary: TruLuraBrandColors.nebulaIndigo,
      secondary: TruLuraTokens.auraPink,
      focal: 'Aura pulse',
      value: 'Radiant',
    );
    return TruWorldStage(
      overline: data.overline,
      title: data.title,
      subtitle: data.subtitle,
      glyph: data.glyph,
      primary: data.primary,
      secondary: data.secondary,
      focalLabel: data.focal,
      focalValue: data.value,
      atmosphereLabel: 'Aura = emotional universe',
      heroLabel: 'Emotional universe',
      identityLabel: 'Identity',
      identityValue: 'Self-expression orbit',
      interactionLabel: 'Reflect, tune, check in',
      contentLabel: 'Community enters after reflection',
      guidance: [
        TruWorldAction(
          label: 'Begin Reflection',
          glyph: TruLuraGlyph.edit,
          primary: true,
          accent: data.primary,
          onTap: () => TruNavigation.pushWithReturnTo(
            context,
            AppRoutes.createPost,
          ),
        ),
        TruWorldAction(
          label: 'Tune Aura',
          glyph: TruLuraGlyph.filter,
          accent: data.secondary,
          onTap: () => context.push(AppRoutes.feedPersonalization),
        ),
        TruWorldAction(
          label: 'Track Mood',
          glyph: TruLuraGlyph.insights,
          accent: TruLuraTokens.auraCyan,
          onTap: () => context.push(AppRoutes.onboardingVibe),
        ),
      ],
      portals: [
        TruRealmPortal(
          title: 'Emotional Weather',
          subtitle: 'Notice what is rising, softening, or asking for care.',
          glyph: TruLuraGlyph.aura,
          accent: data.primary,
        ),
        TruRealmPortal(
          title: 'Aura Pulse',
          subtitle: 'The living signal of your current emotional world.',
          glyph: TruLuraGlyph.groups,
          accent: data.secondary,
          onTap: () => context.go(AppRoutes.homeTab('explore')),
        ),
        TruRealmPortal(
          title: 'Reflection Journey',
          subtitle: 'Follow how your mood evolves across posts and check-ins.',
          glyph: TruLuraGlyph.star,
          accent: TruLuraBrandColors.glowGold,
        ),
      ],
    );
  }
}

double _auraFeedBottomPadding(BuildContext context) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  return kTruluraBottomNavClearance + bottomInset;
}

sealed class _FeedItem {
  const _FeedItem();
}

class _FeedPostItem extends _FeedItem {
  final Post post;
  final bool boostedSlot;
  final String why;

  const _FeedPostItem(
      {required this.post, required this.boostedSlot, required this.why});
}

class _FeedEventRowItem extends _FeedItem {
  const _FeedEventRowItem();
}

class _FeedLiveRowItem extends _FeedItem {
  const _FeedLiveRowItem();
}

class _FeedAiAwarenessItem extends _FeedItem {
  const _FeedAiAwarenessItem();
}

class _FeedCreatorWaveItem extends _FeedItem {
  final int index;

  const _FeedCreatorWaveItem({required this.index});
}

class _FeedQuietZoneItem extends _FeedItem {
  final _AuraFeedKind kind;

  const _FeedQuietZoneItem({required this.kind});
}

class _FeedOrbitPulseItem extends _FeedItem {
  final int index;
  final String label;

  const _FeedOrbitPulseItem({required this.index, required this.label});
}

class _FeedRecommendationSectionItem extends _FeedItem {
  final _AuraRecommendationSection section;
  final bool emphasized;

  const _FeedRecommendationSectionItem({
    required this.section,
    required this.emphasized,
  });
}

enum _AuraRecommendationSection { communities, people, sparks }

class _FeedDemoCardItem extends _FeedItem {
  final TruluraFeedDemoCardKind kind;
  final String title;
  final String body;
  final List<String> chips;
  final String? actionLabel;
  final bool emphasized;

  const _FeedDemoCardItem({
    required this.kind,
    required this.title,
    required this.body,
    this.chips = const <String>[],
    this.actionLabel,
    this.emphasized = false,
  });
}

class _FeedTabView extends StatefulWidget {
  final _AuraFeedKind kind;
  final TruParticipationContext ctx;
  final TruQuizPersonalization personalization;
  final List<TruRankedPost> ranked;
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final Map<String, int> glowCounts;
  final Set<String> glowedPostIds;
  final Widget header;

  const _FeedTabView({
    required this.kind,
    required this.ctx,
    required this.personalization,
    required this.ranked,
    required this.controller,
    required this.onRefresh,
    required this.glowCounts,
    required this.glowedPostIds,
    required this.header,
  });

  @override
  State<_FeedTabView> createState() => _FeedTabViewState();
}

class _AuraSignalStrip extends StatelessWidget {
  final TruQuizPersonalization personalization;
  final VoidCallback onPrimaryTap;

  const _AuraSignalStrip({
    required this.personalization,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final chips = [
      personalization.emotionalTone,
      personalization.connectionStyle,
      ...personalization.discoveryEmphasis.take(2),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);

    return TruLuraGlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Live tuning',
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                for (final chip in chips.take(4))
                  TruLuraGlowPill(
                    label: chip,
                    selected: chip == personalization.emotionalTone,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onPrimaryTap,
            child: const Text('Discover'),
          ),
        ],
      ),
    );
  }
}

class _AmbientIntelligenceStrip extends StatelessWidget {
  final _AuraFeedKind kind;
  final bool lowEnergy;
  final TruQuizPersonalization personalization;

  const _AmbientIntelligenceStrip({
    required this.kind,
    required this.lowEnergy,
    required this.personalization,
  });

  String get _message {
    if (lowEnergy) return 'Low-pressure conversations are breathing softer.';
    if (personalization.hasResults) {
      final tone = personalization.emotionalTone.trim();
      if (tone.isNotEmpty) return 'Your orbit is leaning $tone right now.';
    }
    return switch (kind) {
      _AuraFeedKind.vent => 'This space feels calmer tonight.',
      _AuraFeedKind.spark => 'Sync is pacing for intentional first moves.',
      _AuraFeedKind.trending => 'Energy is rising around active threads.',
      _AuraFeedKind.aura => 'Reflective replies are clustering nearby.',
      _AuraFeedKind.forYou => 'Your orbit is tuning toward softer signals.',
    };
  }

  List<String> get _signals => switch (kind) {
        _AuraFeedKind.vent => const ['quiet space', 'low-pressure', 'held'],
        _AuraFeedKind.spark => const ['currently vibing', 'pacing', 'aligned'],
        _AuraFeedKind.trending => const [
            'energy rising',
            'active thread',
            'waves'
          ],
        _AuraFeedKind.aura => const [
            'people responding',
            'vibe chain',
            'orbit'
          ],
        _AuraFeedKind.forYou => const [
            'socially alive',
            'fresh replies',
            'soft cue'
          ],
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final accent = switch (kind) {
      _AuraFeedKind.vent => TruLuraTokens.auraCyan,
      _AuraFeedKind.spark => TruLuraTokens.auraPink,
      _AuraFeedKind.trending => TruLuraBrandColors.glowGold,
      _ => TruLuraTokens.auraViolet,
    };

    return TruLuraGlassCard(
      radius: 22,
      depth: true,
      glow: accent,
      tint: accent.withValues(alpha: 0.045),
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
      child: Row(
        children: [
          _BreathingDot(color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    for (final signal in _signals)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: TruLuraSurfaces.hairline,
                          ),
                        ),
                        child: Text(
                          signal,
                          style: t.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TruLuraIcon(
            glyph: TruLuraGlyph.insights,
            size: 19,
            active: true,
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _SocialEcosystemStrip extends StatelessWidget {
  final _AuraFeedKind kind;
  final int postCount;
  final bool lowEnergy;

  const _SocialEcosystemStrip({
    required this.kind,
    required this.postCount,
    required this.lowEnergy,
  });

  List<String> get _signals {
    if (lowEnergy) {
      return const [
        'quiet space tonight',
        'people are reflecting here',
        'soft replies only'
      ];
    }
    return switch (kind) {
      _AuraFeedKind.vent => const [
          'quiet space tonight',
          '4 people reflecting',
          'low-pressure support'
        ],
      _AuraFeedKind.spark => const [
          '3 people tuning in',
          'warm first moves',
          'intimate pacing'
        ],
      _AuraFeedKind.trending => const [
          'orbit energy rising',
          'active discussions',
          'creator drops moving'
        ],
      _AuraFeedKind.aura => const [
          'people responding',
          'vibe chains active',
          'creator rooms open'
        ],
      _AuraFeedKind.forYou => const [
          'fresh replies nearby',
          'orbit activity moving',
          'reflective energy rising'
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final accent = switch (kind) {
      _AuraFeedKind.vent => TruLuraTokens.auraCyan,
      _AuraFeedKind.spark => TruLuraTokens.auraPink,
      _AuraFeedKind.trending => TruLuraBrandColors.glowGold,
      _ => TruLuraTokens.auraViolet,
    };
    final activeCount = (postCount +
            switch (kind) {
              _AuraFeedKind.vent => 2,
              _AuraFeedKind.spark => 3,
              _AuraFeedKind.trending => 7,
              _AuraFeedKind.aura => 5,
              _AuraFeedKind.forYou => 4,
            })
        .clamp(3, 18);

    return TruLuraGlassCard(
      radius: 20,
      tint: accent.withValues(alpha: 0.035),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BreathingDot(color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '$activeCount people tuning into this vibe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                lowEnergy ? 'soft mode' : 'currently active',
                style: t.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              for (final signal in _signals)
                _PresenceMiniPill(label: signal, accent: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceMiniPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _PresenceMiniPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.075),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.075),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _WorldspaceCurrentCard extends StatelessWidget {
  final _AuraFeedKind kind;
  final bool lowEnergy;

  const _WorldspaceCurrentCard({
    required this.kind,
    required this.lowEnergy,
  });

  String get _title {
    if (lowEnergy) return 'Quiet orbit active';
    return switch (kind) {
      _AuraFeedKind.vent => 'Vent-filtered posts',
      _AuraFeedKind.spark => 'Sync-filtered signals',
      _AuraFeedKind.trending => 'Public posts rising',
      _AuraFeedKind.aura => 'Reflective posts active',
      _AuraFeedKind.forYou => 'Your social atmosphere is forming',
    };
  }

  List<String> get _nodes {
    if (lowEnergy) {
      return const ['soft replies', 'low pressure', 'gentle pacing'];
    }
    return switch (kind) {
      _AuraFeedKind.vent => const [
          '2 quiet rooms',
          'support nearby',
          'slow replies'
        ],
      _AuraFeedKind.spark => const [
          '3 tuning in',
          'warm signals',
          'soft intros'
        ],
      _AuraFeedKind.trending => const [
          'creator wave',
          'active threads',
          'rising energy'
        ],
      _AuraFeedKind.aura => const [
          'orbit replies',
          'creator rooms',
          'vibe chain'
        ],
      _AuraFeedKind.forYou => const [
          'people reflecting',
          'fresh signals',
          'quiet spaces'
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = switch (kind) {
      _AuraFeedKind.vent => TruLuraTokens.auraCyan,
      _AuraFeedKind.spark => TruLuraTokens.auraPink,
      _AuraFeedKind.trending => TruLuraBrandColors.glowGold,
      _ => TruLuraTokens.auraViolet,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.050),
              accent.withValues(alpha: lowEnergy ? 0.040 : 0.080),
              Colors.black.withValues(alpha: 0.18),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: lowEnergy ? 0.14 : 0.24),
            width: TruLuraSurfaces.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: lowEnergy ? 0.12 : 0.22),
              blurRadius: 58,
              spreadRadius: -30,
              offset: const Offset(0, 26),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -34,
              width: 170,
              height: 170,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: lowEnergy ? 0.12 : 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    height: 74,
                    child: CustomPaint(
                      painter: _WorldspaceOrbitPainter(
                        accent: accent,
                        quiet: lowEnergy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final node in _nodes)
                              _PresenceMiniPill(label: node, accent: accent),
                          ],
                        ),
                      ],
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

class _WorldspaceOrbitPainter extends CustomPainter {
  final Color accent;
  final bool quiet;

  const _WorldspaceOrbitPainter({
    required this.accent,
    required this.quiet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width * 0.52, size.height * 0.52);
    final halo = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: quiet ? 0.18 : 0.32),
          accent.withValues(alpha: quiet ? 0.04 : 0.08),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.46));
    canvas.drawCircle(center, size.width * 0.46, halo);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        colors: [
          accent.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: quiet ? 0.16 : 0.32),
          accent.withValues(alpha: quiet ? 0.28 : 0.54),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.78,
        height: size.height * 0.62,
      ),
      -1.3,
      4.25,
      false,
      ring,
    );

    final dot = Paint()..color = accent.withValues(alpha: quiet ? 0.48 : 0.82);
    for (final p in const [
      Offset(0.22, 0.35),
      Offset(0.63, 0.18),
      Offset(0.76, 0.68),
    ]) {
      canvas.drawCircle(Offset(size.width * p.dx, size.height * p.dy), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldspaceOrbitPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.quiet != quiet;
  }
}

class _BreathingDot extends StatefulWidget {
  final Color color;

  const _BreathingDot({required this.color});

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.42 + 0.25 * t),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.20 + 0.18 * t),
                blurRadius: 18 + 10 * t,
                spreadRadius: -4,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuizDiscoveryFocusCard extends StatelessWidget {
  final TruQuizPersonalization personalization;
  final VoidCallback onPrimaryTap;

  const _QuizDiscoveryFocusCard({
    required this.personalization,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final primaryFocus = personalization.discoveryEmphasis.firstOrNull;
    final content = personalization.contentThemes.take(2).join(' and ');
    final emphasis = personalization.discoveryEmphasis.take(2).join(' and ');

    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active discovery',
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            content.isEmpty
                ? 'Your saved tuning is now shaping who and what Aura foregrounds.'
                : 'Aura is leaning into $content and giving extra room to $emphasis based on your saved tuning signals.',
            style: t.bodySmall?.copyWith(
              color: TruLuraTokens.textSecondary,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final focus in personalization.discoveryEmphasis)
                TruLuraGlowPill(
                  label: focus,
                  selected: focus == primaryFocus,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: onPrimaryTap,
              child: Text(
                primaryFocus != null && primaryFocus.contains('friend')
                    ? 'Find aligned people'
                    : 'Explore matching spaces',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTabViewState extends State<_FeedTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_AuraRecommendationSection> _recommendationSections() {
    final ordered = <_AuraRecommendationSection>[
      _AuraRecommendationSection.communities,
      _AuraRecommendationSection.people,
      _AuraRecommendationSection.sparks,
    ];
    if (!widget.personalization.hasResults) return ordered;

    final primary = widget.personalization.discoveryEmphasis.firstOrNull ?? '';
    _AuraRecommendationSection lead;
    if (primary.contains('friend')) {
      lead = _AuraRecommendationSection.people;
    } else if (primary.contains('spark')) {
      lead = _AuraRecommendationSection.sparks;
    } else {
      lead = _AuraRecommendationSection.communities;
    }

    ordered.remove(lead);
    return [lead, ...ordered];
  }

  List<_FeedDemoCardItem> _demoCards() {
    final theme = widget.personalization.contentThemes.firstOrNull ??
        (widget.kind == _AuraFeedKind.vent ? 'gentle support' : 'vibe updates');
    final focus = widget.personalization.discoveryEmphasis.firstOrNull ??
        'low-pressure discovery';

    return switch (widget.kind) {
      _AuraFeedKind.vent => <_FeedDemoCardItem>[
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.supportPrompt,
            title: 'Protected check-in',
            body:
                'A softer check-in is open for people who want support without turning the moment into a performance.',
            chips: const ['private', 'low energy', 'support'],
            actionLabel: 'Open Vent Space',
            emphasized: true,
          ),
        ],
      _AuraFeedKind.spark => <_FeedDemoCardItem>[
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.recommendation,
            title: 'Compatible people',
            body:
                'Sync is surfacing people with aligned intent, trust signals, and room for a calm first move.',
            chips: ['aligned intent', focus, 'spark-safe'],
            actionLabel: 'Open Sync',
            emphasized: true,
          ),
        ],
      _AuraFeedKind.trending => <_FeedDemoCardItem>[
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.conversation,
            title: 'Trending conversations',
            body:
                'Public conversations with fresh replies and rising energy collect here without crowding your Aura.',
            chips: const ['now rising', 'public', 'conversation'],
            actionLabel: 'Explore',
            emphasized: true,
          ),
        ],
      _AuraFeedKind.aura => <_FeedDemoCardItem>[
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.conversation,
            title: 'Aura reflection thread',
            body:
                'Emotional posts, creator reflections, and soft replies gather here as a social-first Aura stream.',
            chips: [theme, 'aura replies', 'social'],
            emphasized: true,
          ),
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.community,
            title: 'Aura circles',
            body:
                'Join reflective rooms, aesthetic drops, and creator-led conversations without Spark or Vent intent.',
            chips: ['creator rooms', focus, 'emotion-safe'],
            actionLabel: 'Browse communities',
          ),
        ],
      _AuraFeedKind.forYou => <_FeedDemoCardItem>[
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.recommendation,
            title: 'Personalized mix',
            body:
                'A blended home stream with friend signals, creator posts, gentle support prompts, and low-pressure discovery.',
            chips: [theme, 'mixed feed', 'personalized'],
            emphasized: true,
          ),
          _FeedDemoCardItem(
            kind: TruluraFeedDemoCardKind.conversation,
            title: 'Your orbit pulse',
            body:
                'Fresh replies, saved interests, and compatibility nudges appear together before you choose a deeper lane.',
            chips: ['fresh signals', focus, 'for you'],
            actionLabel: 'Explore',
          ),
        ],
    };
  }

  List<_FeedItem> _composeItems(BuildContext context) {
    final app = context.read<AppProvider>();
    final ranked = widget.ranked;
    if (ranked.isEmpty) return const <_FeedItem>[];
    final posts = ranked.map((e) => e.post).toList(growable: false);
    final whyById = <String, String>{for (final r in ranked) r.post.id: r.why};

    final showLives = app.showLivesInFeed &&
        !widget.ctx.effectivePermissions.suppressVirality;
    final frequency = app.livesInFeedFrequency;
    final liveInterval = switch (frequency) {
      'Rare' => 10,
      'Often' => 4,
      _ => 7,
    };

    final showEvents = (widget.kind == _AuraFeedKind.forYou ||
            widget.kind == _AuraFeedKind.trending) &&
        !app.isLowEnergyContext;
    final eventRow =
        showEvents ? const [_FeedEventRowItem()] : const <_FeedItem>[];
    final showRecommendationSections = widget.personalization.hasResults &&
        (widget.kind == _AuraFeedKind.forYou ||
            widget.kind == _AuraFeedKind.aura);
    final recommendationItems = showRecommendationSections
        ? _recommendationSections()
            .asMap()
            .entries
            .map(
              (entry) => _FeedRecommendationSectionItem(
                section: entry.value,
                emphasized: entry.key == 0,
              ),
            )
            .toList(growable: false)
        : const <_FeedItem>[];

    // Boost economy: keep it controlled.
    // - never in Vent
    // - never bypass safety/mode boundaries (we only boost inside filteredPosts)
    final allowBoost = widget.kind != _AuraFeedKind.vent &&
        !widget.ctx.effectivePermissions.suppressVirality &&
        !app.isLowEnergyContext;
    final boostedCandidates = allowBoost
        ? posts.where((p) => p.isBoosted).toList(growable: false)
        : const <Post>[];
    final boostedSet = boostedCandidates.map((e) => e.id).toSet();

    final items = <_FeedItem>[];
    for (int i = 0; i < posts.length; i++) {
      final post = posts[i];
      final isBoostedSlot =
          boostedSet.contains(post.id) || (allowBoost && i != 0 && i % 9 == 0);
      if (i == 0) {
        items.add(const _FeedAiAwarenessItem());
      }
      if (showLives && i != 0 && i % liveInterval == 0) {
        items.add(const _FeedLiveRowItem());
      }

      final baseWhy = whyById[post.id] ?? '';
      final why = _whyAmISeeingThis(
          context: context,
          kind: widget.kind,
          ctx: widget.ctx,
          post: post,
          boosted: isBoostedSlot,
          baseWhy: baseWhy);
      items
          .add(_FeedPostItem(post: post, boostedSlot: isBoostedSlot, why: why));
      if (i == 1 && eventRow.isNotEmpty) {
        items.addAll(eventRow);
      }
      if (i == 2 && recommendationItems.isNotEmpty) {
        items.addAll(recommendationItems.take(2));
      }
      if (i == 2 &&
          widget.kind != _AuraFeedKind.vent &&
          !app.isLowEnergyContext) {
        items.add(_FeedCreatorWaveItem(index: i));
      }
      if (i == 4 || (i == 1 && widget.kind == _AuraFeedKind.vent)) {
        items.add(_FeedQuietZoneItem(kind: widget.kind));
      }
      if (i != 0 && i % 3 == 0) {
        items.add(_FeedOrbitPulseItem(
          index: i,
          label: switch (widget.kind) {
            _AuraFeedKind.vent => 'quiet support thread',
            _AuraFeedKind.spark => 'low-pressure spark chain',
            _AuraFeedKind.trending => 'conversation wave rising',
            _AuraFeedKind.aura => 'orbit replies moving',
            _AuraFeedKind.forYou => 'vibe cluster forming',
          },
        ));
      }
    }
    if (items.length < 4) {
      items.addAll(recommendationItems.take(1));
    }
    return items;
  }

  String _whyAmISeeingThis(
      {required BuildContext context,
      required _AuraFeedKind kind,
      required TruParticipationContext ctx,
      required Post post,
      required bool boosted,
      required String baseWhy}) {
    final app = context.read<AppProvider>();
    final inferred = post.inferredExperienceMode();
    final intensity = post.emotionalIntensityScore;
    final reasons = <String>[];

    if (baseWhy.trim().isNotEmpty) {
      reasons.add(baseWhy);
    }
    reasons.add('Mode match: ${ctx.activeMode.name} → ${inferred.name}');
    if (post.isAnonymous || inferred == TruExperienceMode.vent) {
      reasons.add('Protected emotional content');
    }
    if (post.isCreatorContent || inferred == TruExperienceMode.creator) {
      reasons
          .add('Creator weighting: ${(app.feedCreatorWeight * 100).round()}%');
    }
    if (kind == _AuraFeedKind.spark) {
      reasons.add('Spark tab surfaces romantic discovery');
    }
    if (kind == _AuraFeedKind.aura) {
      reasons.add('Aura tab is social-first');
    }
    if (boosted) {
      reasons.add('Boosted slot (still safety-checked)');
    }
    reasons.add('Intensity score: $intensity/100');
    reasons.add(
        'Emotional sensitivity: ${(app.feedEmotionalSensitivity * 100).round()}%');
    reasons.add(
        'Romantic visibility: ${(app.feedRomanticVisibility * 100).round()}%');
    reasons
        .add('Discovery balance: ${(app.feedDiscoveryBalance * 100).round()}%');

    return reasons.join('\n');
  }

  Widget _emptyState(BuildContext context) {
    switch (widget.kind) {
      case _AuraFeedKind.aura:
        return TruStatePanel(
          glyph: TruLuraGlyph.aura,
          title: 'Aura is quiet right now',
          message:
              'Social vibes appear here — never mixed with Spark or Vent intent.',
          actions: [
            TruStateAction(
                label: 'Explore',
                glyph: TruLuraGlyph.explore,
                onTap: () => context.go(AppRoutes.homeTab('explore')),
                primary: true),
            TruStateAction(
                label: 'Create vibe',
                glyph: TruLuraGlyph.edit,
                onTap: () => TruNavigation.pushWithReturnTo(
                    context, AppRoutes.createPost)),
          ],
        );
      case _AuraFeedKind.spark:
        return TruStatePanel(
          glyph: TruLuraGlyph.heartOutline,
          title: 'Sync-filtered posts are quiet',
          message:
              'Romantic connection belongs in Sync. This tab only previews eligible posts without becoming a second Sync.',
          actions: [
            TruStateAction(
                label: 'Open Sync',
                glyph: TruLuraGlyph.sync,
                onTap: () => context.go(AppRoutes.homeTab('sync')),
                primary: true),
            TruStateAction(
                label: 'Create post',
                glyph: TruLuraGlyph.edit,
                onTap: () => TruNavigation.pushWithReturnTo(
                    context, AppRoutes.createPost)),
          ],
        );
      case _AuraFeedKind.vent:
        return TruStatePanel(
          glyph: TruLuraGlyph.shield,
          title: 'Vent-filtered posts are quiet',
          message:
              'This is a protected space. No virality, no monetization, no cross-mode discovery.',
          actions: [
            TruStateAction(
                label: 'Open Vent Space',
                glyph: TruLuraGlyph.shield,
                onTap: () => context.push(AppRoutes.vent),
                primary: true),
            TruStateAction(
                label: 'Create anonymous post',
                glyph: TruLuraGlyph.edit,
                onTap: () => TruNavigation.pushWithReturnTo(
                    context, AppRoutes.createPost)),
          ],
        );
      case _AuraFeedKind.trending:
        return TruStatePanel(
          glyph: TruLuraGlyph.insights,
          title: 'Trending is quiet right now',
          message:
              'No trending posts yet — we’ll show the newest public vibes as a fallback soon.',
          actions: [
            TruStateAction(
                label: 'Refresh',
                glyph: TruLuraGlyph.spark,
                onTap: widget.onRefresh,
                primary: true)
          ],
        );
      case _AuraFeedKind.forYou:
        return TruStatePanel(
          glyph: TruLuraGlyph.spark,
          title: switch (widget.ctx.activeMode) {
            TruExperienceMode.vent => 'This space is quiet right now',
            TruExperienceMode.youth => 'Youth feed is calming right now',
            TruExperienceMode.dating => 'Your Dating space is waiting',
            TruExperienceMode.friendship => 'Friendship space is waiting',
            TruExperienceMode.creator => 'Creator space is warming up',
            TruExperienceMode.luxe => 'Luxe is quiet right now',
            TruExperienceMode.altIntimate => 'Alternative space is quiet',
            TruExperienceMode.social =>
              'Your Aura feed is waiting for your energy',
          },
          message: switch (widget.ctx.activeMode) {
            TruExperienceMode.vent =>
              'Protected support has no virality. Share if you need to let it out.',
            TruExperienceMode.youth =>
              'Safe, age-appropriate posts. Use Explore for outward discovery.',
            TruExperienceMode.dating =>
              'Intentional romance — start with a signal or a vibe.',
            TruExperienceMode.friendship =>
              'Platonic discovery. No pressure — just alignment.',
            TruExperienceMode.creator =>
              'Publish something luminous — your audience will find you.',
            TruExperienceMode.luxe =>
              'Curated visibility. Post softly, be seen selectively.',
            TruExperienceMode.altIntimate =>
              'Consent-first, gated space. Keep it intentional.',
            TruExperienceMode.social =>
              'Start by exploring people or sharing your first post.',
          },
          actions: [
            TruStateAction(
                label: 'Explore',
                glyph: TruLuraGlyph.explore,
                onTap: () => context.go(AppRoutes.homeTab('explore')),
                primary: true),
            TruStateAction(
                label: 'Create post',
                glyph: TruLuraGlyph.edit,
                onTap: () => TruNavigation.pushWithReturnTo(
                    context, AppRoutes.createPost)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _composeItems(context);
    if (widget.ranked.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          key: PageStorageKey<String>('feed_${widget.kind.name}'),
          controller: widget.controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: _auraFeedBottomPadding(context)),
          children: [
            widget.header,
            const SizedBox(height: 8),
            TruluraFeedLane(
              child: Column(
                children: [
                  _AmbientIntelligenceStrip(
                    kind: widget.kind,
                    lowEnergy: context.read<AppProvider>().isLowEnergyContext,
                    personalization: widget.personalization,
                  ),
                  const SizedBox(height: 10),
                  if (widget.personalization.hasResults &&
                      (widget.kind == _AuraFeedKind.forYou ||
                          widget.kind == _AuraFeedKind.aura)) ...[
                    _QuizDiscoveryFocusCard(
                      personalization: widget.personalization,
                      onPrimaryTap: () =>
                          context.go(AppRoutes.homeTab('explore')),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final demo in _demoCards().take(2)) ...[
                    TruluraFeedDemoCard(
                      kind: demo.kind,
                      title: demo.title,
                      body: demo.body,
                      chips: demo.chips,
                      actionLabel: demo.actionLabel,
                      emphasized: demo.emphasized,
                      onTap: demo.actionLabel == null
                          ? null
                          : () {
                              if (demo.actionLabel!.contains('Sync')) {
                                context.go(AppRoutes.homeTab('sync'));
                              } else if (demo.actionLabel!.contains('Vent')) {
                                context.push(AppRoutes.vent);
                              } else {
                                context.go(AppRoutes.homeTab('explore'));
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                  ],
                  Align(
                      alignment: Alignment.topCenter,
                      child: _emptyState(context)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        key: PageStorageKey<String>('feed_${widget.kind.name}'),
        controller: widget.controller,
        padding: EdgeInsets.only(bottom: _auraFeedBottomPadding(context)),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) =>
            SizedBox(height: index % 4 == 0 ? 18 : 13),
        itemBuilder: (context, index) {
          if (index == 0) return widget.header;
          final item = items[index - 1];
          final child = switch (item) {
            _FeedAiAwarenessItem() => _AiEmotionalAwarenessCard(
                kind: widget.kind,
                personalization: widget.personalization,
              ),
            _FeedCreatorWaveItem(:final index) => _CreatorEcosystemCard(
                index: index,
                kind: widget.kind,
              ),
            _FeedQuietZoneItem(:final kind) => _QuietZoneCard(kind: kind),
            _FeedOrbitPulseItem(:final index, :final label) =>
              _OrbitPulseDivider(
                label: label,
                index: index,
                kind: widget.kind,
              ),
            _FeedRecommendationSectionItem(
              :final section,
              :final emphasized,
            ) =>
              _RecommendationSectionCard(
                section: section,
                personalization: widget.personalization,
                emphasized: emphasized,
              ),
            _FeedDemoCardItem(
              :final kind,
              :final title,
              :final body,
              :final chips,
              :final actionLabel,
              :final emphasized,
            ) =>
              TruluraFeedItemRenderer(
                item: TruDemoFeedItem(
                  id: 'aura-demo-$title',
                  kind: kind,
                  title: title,
                  body: body,
                  vibeTags: [
                    for (final chip in chips) TruVibeTag(chip),
                  ],
                  actionLabel: actionLabel,
                  emphasized: emphasized,
                ),
              ),
            _FeedEventRowItem() => const TruluraEventCarouselRow(),
            _FeedLiveRowItem() => const _LiveInFeedCard(),
            _FeedPostItem(:final post, :final boostedSlot, :final why) =>
              TruluraFeedItemRenderer(
                item: TruPostFeedItem(
                  post: post,
                  boosted: boostedSlot,
                  why: why,
                  counts: TruFeedInteractionCounts.fromPost(
                    post,
                    glowCount: widget.glowCounts[post.id] ?? post.likeCount,
                    glowedByViewer: widget.glowedPostIds.contains(post.id),
                  ),
                ),
              ),
          };
          return _FeedRhythmLane(
            index: index,
            kind: widget.kind,
            child: child,
          );
        },
      ),
    );
  }
}

class _FeedRhythmLane extends StatelessWidget {
  final int index;
  final _AuraFeedKind kind;
  final Widget child;

  const _FeedRhythmLane({
    required this.index,
    required this.kind,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final rhythm = index % 5;
    final left = !wide
        ? 16.0
        : switch (rhythm) {
            1 => 18.0,
            2 => 46.0,
            3 => 88.0,
            4 => 34.0,
            _ => 64.0,
          };
    final right = !wide
        ? 16.0
        : switch (rhythm) {
            1 => 78.0,
            2 => 24.0,
            3 => 48.0,
            4 => 98.0,
            _ => 34.0,
          };
    final maxWidth = switch (kind) {
      _AuraFeedKind.trending => kTruluraFeedMaxWidth + 64,
      _AuraFeedKind.vent => kTruluraFeedMaxWidth - 28,
      _ => kTruluraFeedMaxWidth +
          (rhythm == 3
              ? 52
              : rhythm == 1
                  ? -18
                  : 0),
    };
    final yDrift = switch (rhythm) {
      1 => 0.0,
      2 => 4.0,
      3 => -2.0,
      4 => 7.0,
      _ => 2.0,
    };
    final atmosphericInset = switch (rhythm) {
      1 => Alignment.centerLeft,
      2 => Alignment.centerRight,
      3 => Alignment.center,
      4 => Alignment.centerLeft,
      _ => Alignment.centerRight,
    };
    return TruluraFeedLane(
      padding: EdgeInsets.fromLTRB(left, 0, right, 0),
      maxWidth: maxWidth,
      child: Transform.translate(
        offset: Offset(0, yDrift),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: atmosphericInset,
                  child: FractionallySizedBox(
                    widthFactor: wide ? 0.78 : 0.92,
                    heightFactor: 0.72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _feedRhythmGlow(kind).withValues(alpha: 0.055),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Color _feedRhythmGlow(_AuraFeedKind kind) {
    return switch (kind) {
      _AuraFeedKind.vent => TruLuraTokens.auraCyan,
      _AuraFeedKind.spark => TruLuraTokens.auraPink,
      _AuraFeedKind.trending => TruLuraBrandColors.glowGold,
      _ => TruLuraTokens.auraViolet,
    };
  }
}

class _OrbitPulseDivider extends StatelessWidget {
  final String label;
  final int index;
  final _AuraFeedKind kind;

  const _OrbitPulseDivider({
    required this.label,
    required this.index,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final accent = switch (kind) {
      _AuraFeedKind.vent => TruLuraTokens.auraCyan,
      _AuraFeedKind.spark => TruLuraTokens.auraPink,
      _AuraFeedKind.trending => TruLuraBrandColors.glowGold,
      _ => TruLuraTokens.auraViolet,
    };
    return Align(
      alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: MediaQuery.sizeOf(context).width >= 760 ? 0.74 : 1.0,
        child: TruLuraGlassCard(
          radius: 999,
          tint: accent.withValues(alpha: 0.035),
          glow: accent,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            children: [
              _BreathingDot(color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'live orbit',
                style: t.labelSmall?.copyWith(
                  color: accent.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiEmotionalAwarenessCard extends StatelessWidget {
  final _AuraFeedKind kind;
  final TruQuizPersonalization personalization;

  const _AiEmotionalAwarenessCard({
    required this.kind,
    required this.personalization,
  });

  String get _message {
    if (personalization.hasResults &&
        personalization.emotionalTone.trim().isNotEmpty) {
      return 'Your current atmosphere leans ${personalization.emotionalTone}.';
    }
    return switch (kind) {
      _AuraFeedKind.vent => 'Your orbit feels calmer tonight.',
      _AuraFeedKind.spark => 'People nearby are sharing softly tonight.',
      _AuraFeedKind.trending => 'Reflective energy is rising.',
      _AuraFeedKind.aura => 'Your orbit is gathering around gentler replies.',
      _AuraFeedKind.forYou => 'Your current atmosphere leans grounded.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final accent = switch (kind) {
      _AuraFeedKind.vent => TruLuraTokens.auraCyan,
      _AuraFeedKind.spark => TruLuraTokens.auraPink,
      _AuraFeedKind.trending => TruLuraBrandColors.glowGold,
      _ => TruLuraTokens.auraViolet,
    };

    return TruLuraGlassCard(
      radius: 22,
      tint: accent.withValues(alpha: 0.040),
      glow: accent,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: TruLuraSurfaces.hairline,
              ),
            ),
            child: TruLuraIcon(
              glyph: TruLuraGlyph.insights,
              size: 17,
              active: true,
              color: accent,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ambient AI is sensing the room tone and keeping the pace soft.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.62),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorEcosystemCard extends StatelessWidget {
  final int index;
  final _AuraFeedKind kind;

  const _CreatorEcosystemCard({
    required this.index,
    required this.kind,
  });

  List<String> get _items => switch (kind) {
        _AuraFeedKind.spark => const [
            'live session',
            'music thread',
            'warm room'
          ],
        _AuraFeedKind.trending => const [
            'creator broadcast',
            'vibe event',
            'active room'
          ],
        _ => const [
            'creator room open',
            'orbit community',
            'emotional broadcast'
          ],
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final accent = kind == _AuraFeedKind.trending
        ? TruLuraBrandColors.glowGold
        : TruLuraTokens.auraPink;

    return Align(
      alignment: index.isEven ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: MediaQuery.sizeOf(context).width >= 760 ? 0.86 : 1.0,
        child: TruLuraGlassCard(
          radius: 24,
          depth: true,
          glow: accent,
          tint: accent.withValues(alpha: 0.045),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TruLuraIcon(
                    glyph: TruLuraGlyph.video,
                    size: 18,
                    active: true,
                    color: accent,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Creator movement',
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    'active',
                    style: t.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'A few creator spaces are carrying the room without pushing the pace.',
                style: t.bodySmall?.copyWith(
                  color: TruLuraTokens.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 7,
                children: [
                  for (final item in _items)
                    _PresenceMiniPill(label: item, accent: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietZoneCard extends StatelessWidget {
  final _AuraFeedKind kind;

  const _QuietZoneCard({required this.kind});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = kind == _AuraFeedKind.spark
        ? TruLuraTokens.auraPink
        : TruLuraTokens.auraCyan;
    final title = switch (kind) {
      _AuraFeedKind.vent => 'Quiet support space',
      _AuraFeedKind.spark => 'Soft first-move room',
      _ => 'Low-pressure quiet zone',
    };
    final body = switch (kind) {
      _AuraFeedKind.vent =>
        'People are reflecting here without performance pressure.',
      _AuraFeedKind.spark =>
        'Intentional signals are moving slowly and warmly.',
      _ => 'The feed is making room for slower replies and softer context.',
    };

    return TruLuraGlassCard(
      radius: 22,
      tint: accent.withValues(alpha: 0.035),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      child: Row(
        children: [
          _BreathingDot(color: accent),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: TruLuraTokens.textSecondary,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraFeedSkeleton extends StatelessWidget {
  final Widget? header;

  const _AuraFeedSkeleton({this.header});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(bottom: _auraFeedBottomPadding(context)),
      itemCount: 5 + (header == null ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (header != null && i == 0) return header!;
        return const TruluraFeedLane(
          child: _AuraFeedSkeletonCard(),
        );
      },
    );
  }
}

class _RecommendationSectionCard extends StatelessWidget {
  final _AuraRecommendationSection section;
  final TruQuizPersonalization personalization;
  final bool emphasized;

  const _RecommendationSectionCard({
    required this.section,
    required this.personalization,
    required this.emphasized,
  });

  String get _title => switch (section) {
        _AuraRecommendationSection.communities => 'Communities for you',
        _AuraRecommendationSection.people => 'Compatible people',
        _AuraRecommendationSection.sparks => 'Social sparks',
      };

  String _description() {
    final theme =
        personalization.contentThemes.firstOrNull ?? 'your current energy';
    final focus = personalization.discoveryEmphasis.firstOrNull ?? 'discovery';
    return switch (section) {
      _AuraRecommendationSection.communities =>
        'Community rooms are tuned around $theme and weighted toward $focus so discovery feels social, not random.',
      _AuraRecommendationSection.people =>
        'Aligned people and friend signals are tuned around $theme with extra weight on $focus.',
      _AuraRecommendationSection.sparks =>
        'Light social sparks and first-message prompts are tuned around $theme and $focus.',
    };
  }

  List<String> _chips() {
    final base = switch (section) {
      _AuraRecommendationSection.communities => <String>[
          'thoughtful groups',
          'interest circles',
          'low-pressure spaces',
        ],
      _AuraRecommendationSection.people => <String>[
          'trusted friends',
          'aligned people',
          'steady connections',
        ],
      _AuraRecommendationSection.sparks => <String>[
          'social sparks',
          'conversation starters',
          'light discovery',
        ],
    };
    final dynamicChips = [
      ...personalization.discoveryEmphasis.take(1),
      ...personalization.contentThemes.take(1),
    ];
    return [...dynamicChips, ...base].take(3).toList(growable: false);
  }

  VoidCallback _onTap(BuildContext context) {
    return switch (section) {
      _AuraRecommendationSection.communities => () =>
          context.go(AppRoutes.homeTab('explore')),
      _AuraRecommendationSection.people => () =>
          context.go(AppRoutes.homeTab('explore')),
      _AuraRecommendationSection.sparks => () =>
          context.go(AppRoutes.homeTab('sync')),
    };
  }

  String _ctaLabel() {
    return switch (section) {
      _AuraRecommendationSection.communities => 'Browse communities',
      _AuraRecommendationSection.people => 'Browse people',
      _AuraRecommendationSection.sparks => 'Open Spark',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = emphasized
        ? TruLuraTokens.auraViolet.withValues(alpha: 0.10)
        : Colors.transparent;

    return TruLuraGlassCard(
      radius: 22,
      tint: accent,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
      onTap: _onTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (emphasized)
                Text(
                  'Prioritized',
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _description(),
            style: t.bodySmall?.copyWith(
              color: TruLuraTokens.textSecondary,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _chips()
                .map(
                  (chip) => TruLuraGlowPill(
                    label: chip,
                    selected: emphasized,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: _onTap(context),
              child: Text(_ctaLabel()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedFoundationPreview extends StatelessWidget {
  final VoidCallback onCreateFirstPost;

  const _FeedFoundationPreview({
    required this.onCreateFirstPost,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expression studio',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Aura begins with a single honest signal. Choose the shape of your first moment and let the emotional world gather around it.',
          style: t.bodyMedium?.copyWith(
            color: TruLuraTokens.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        _FeedTypePreviewCard(
          title: 'Video post',
          subtitle: 'A cinematic aura drop with voice, motion, and feeling',
          accent: Color(0xFF7C4DFF),
          overlayCaption: 'Your feeling becomes the scene',
        ),
        const SizedBox(height: 9),
        _FeedTypePreviewCard(
          title: 'Image post',
          subtitle: 'A still emotional memory with a soft caption',
          accent: Color(0xFFFF4FD8),
        ),
        const SizedBox(height: 9),
        _FeedTypePreviewCard(
          title: 'Styled text post',
          subtitle: 'A written truth with atmosphere and rhythm',
          accent: Color(0xFF37D5FF),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: onCreateFirstPost,
            child: const Text('Create first post'),
          ),
        ),
      ],
    );
  }
}

class _FeedTypePreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String? overlayCaption;

  const _FeedTypePreviewCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.overlayCaption,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TruLuraGlassCard(
      radius: 22,
      tint: accent.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 136,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.45),
                  accent.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: overlayCaption == null
                ? Center(
                    child: Text(
                      title,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          overlayCaption!,
                          style: t.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtitle,
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

class _AuraFeedSkeletonCard extends StatelessWidget {
  const _AuraFeedSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: TruLuraGlassCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(14),
        depth: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const TruSkeletonCircle(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      TruSkeletonBox(width: 160, height: 14, radius: 10),
                      SizedBox(height: 10),
                      TruSkeletonBox(width: 110, height: 12, radius: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const TruSkeletonBox(width: 26, height: 26, radius: 10),
              ],
            ),
            const SizedBox(height: 14),
            const TruSkeletonBox(
                width: double.infinity, height: 14, radius: 10),
            const SizedBox(height: 10),
            const TruSkeletonBox(
                width: double.infinity, height: 14, radius: 10),
            const SizedBox(height: 10),
            const TruSkeletonBox(width: 240, height: 14, radius: 10),
            const SizedBox(height: 14),
            const TruSkeletonBox(
                width: double.infinity, height: 150, radius: 16),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                    child: TruSkeletonBox(
                        width: double.infinity, height: 38, radius: 999)),
                SizedBox(width: 10),
                Expanded(
                    child: TruSkeletonBox(
                        width: double.infinity, height: 38, radius: 999)),
                SizedBox(width: 10),
                Expanded(
                    child: TruSkeletonBox(
                        width: double.infinity, height: 38, radius: 999)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuraPageHeading extends StatelessWidget {
  final TruParticipationContext participation;
  final String? personalizedSubtitle;

  const _AuraPageHeading({
    required this.participation,
    this.personalizedSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // Home → Aura is always the parent surface; the subtitle reflects the current
    // participation policy lens.
    final subtitle =
        personalizedSubtitle ?? participation.activePermissions.feedKind.label;
    final protected = participation.effectivePermissions.suppressVirality;

    final compactVertical = MediaQuery.sizeOf(context).width >= 700;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, compactVertical ? 6 : 8, 16, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aura',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                            height: 1.25),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (protected)
            Container(
              margin: const EdgeInsets.only(left: 12, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: cs.primary.withValues(alpha: 0.10)),
              child: Text('Protected',
                  style: t.labelSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      height: 1.0)),
            ),
        ],
      ),
    );
  }
}

class _SecondaryFeedTabsBar extends StatelessWidget {
  final TabController controller;
  final Animation<double> pulse;
  final List<_AuraFeedKind> tabOrder;

  const _SecondaryFeedTabsBar(
      {required this.controller, required this.pulse, required this.tabOrder});

  String _labelFor(_AuraFeedKind k) {
    switch (k) {
      case _AuraFeedKind.forYou:
        return 'For You';
      case _AuraFeedKind.aura:
        return 'Aura';
      case _AuraFeedKind.spark:
        return 'Spark';
      case _AuraFeedKind.vent:
        return 'Vent';
      case _AuraFeedKind.trending:
        return 'Trending';
    }
  }

  TruLuraGlyph _glyphFor(_AuraFeedKind k) {
    return switch (k) {
      _AuraFeedKind.forYou => TruLuraGlyph.spark,
      _AuraFeedKind.aura => TruLuraGlyph.aura,
      _AuraFeedKind.spark => TruLuraGlyph.heartOutline,
      _AuraFeedKind.vent => TruLuraGlyph.shield,
      _AuraFeedKind.trending => TruLuraGlyph.star,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = soft ? 0.0 : pulse.value;
          final glow = soft
              ? const <BoxShadow>[]
              : TruLuraEffects.softGlow(cs.primary,
                  intensity: (0.24 + 0.14 * t) * app.glowScale);

          return Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: cs.surfaceContainerHighest
                  .withValues(alpha: soft ? 0.08 : 0.055),
              border: Border.all(
                  color: Colors.white.withValues(alpha: soft ? 0.055 : 0.045),
                  width: TruLuraSurfaces.hairline),
            ),
            child: TabBar(
              controller: controller,
              isScrollable: true,
              dividerHeight: 0,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
                  const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              indicator: BoxDecoration(
                gradient: TruLuraGradients.pillSelected(brightness),
                borderRadius: BorderRadius.circular(999),
                boxShadow: glow,
              ),
              labelColor: cs.onPrimary,
              unselectedLabelColor: cs.onSurfaceVariant.withValues(alpha: 0.88),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                  height: 1.0),
              unselectedLabelStyle: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                      height: 1.0),
              tabs: [
                for (final k in tabOrder)
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TruLuraIcon(
                          glyph: _glyphFor(k),
                          size: 15,
                          active: true,
                        ),
                        const SizedBox(width: 7),
                        Text(_labelFor(k)),
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

class _LiveInFeedCard extends StatelessWidget {
  const _LiveInFeedCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final mode = context.watch<TruLuraModeController>().mode;

    return TruLuraGlassCard(
      paletteMode: mode,
      radius: AppRadius.card,
      padding: const EdgeInsets.all(14),
      onTap: () => TruNavigation.pushWithReturnTo(context, AppRoutes.live),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.56),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: TruLuraSurfaces.hairline),
              boxShadow: soft
                  ? []
                  : TruLuraEffects.softGlow(TruLuraBrandColors.nebulaMagenta,
                      intensity: 0.55 * app.glowScale),
            ),
            child: TruLuraIcon(
                glyph: TruLuraGlyph.video,
                size: 22,
                active: true,
                color: cs.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live now',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Jump into Live Hub — featured rooms + basic Lives.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.35),
                ),
              ],
            ),
          ),
          TruLuraIcon(
              glyph: TruLuraGlyph.chevronRight,
              size: 18,
              active: false,
              color: cs.onSurface.withValues(alpha: 0.72)),
        ],
      ),
    );
  }
}

class _SmartSwitchBanner extends StatelessWidget {
  final Color accent;
  final _AuraFeedKind from;
  final _AuraFeedKind to;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _SmartSwitchBanner(
      {required this.accent,
      required this.from,
      required this.to,
      required this.onTap,
      required this.onDismiss});

  String _label(_AuraFeedKind k) => switch (k) {
        _AuraFeedKind.forYou => 'For You',
        _AuraFeedKind.aura => 'Aura',
        _AuraFeedKind.spark => 'Spark',
        _AuraFeedKind.vent => 'Vent',
        _AuraFeedKind.trending => 'Trending',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;

    return TruLuraGlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      tint: accent.withValues(alpha: 0.06),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: TruLuraSurfaces.hairline),
              boxShadow: soft
                  ? const <BoxShadow>[]
                  : TruLuraEffects.softGlow(accent,
                      intensity: 0.35 * app.glowScale),
            ),
            child: TruLuraIcon(
                glyph: TruLuraGlyph.spark,
                size: 18,
                active: true,
                color: cs.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Switch context?',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'You’re leaning ${_label(to)} right now. Tap to move from ${_label(from)} → ${_label(to)}.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.25),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TruLuraIcon(
                  glyph: TruLuraGlyph.close,
                  size: 16,
                  active: false,
                  color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
