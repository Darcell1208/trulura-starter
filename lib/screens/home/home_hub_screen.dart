import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/screens/explore/explore_screen.dart';
import 'package:trulura/screens/home/home_feed_screen.dart';
import 'package:trulura/screens/sync/sync_screen.dart';
import 'package:trulura/services/app_settings_service.dart';
import 'package:trulura/services/profile_completion_service.dart';
import 'package:trulura/services/quiz_engine.dart';
import 'package:trulura/services/quiz_registry_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';

/// Home hub with top tab switching.
///
/// This matches the Trulura architecture where the *Home* area contains
/// intent-driven top tabs (Aura / Sync / Explore) while bottom nav stays
/// reserved for global surfaces.
class HomeHubScreen extends StatefulWidget {
  /// Supported: aura | sync | explore
  final String? initialTab;

  const HomeHubScreen({super.key, this.initialTab});

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AppSettingsService _settings = AppSettingsService();
  final ProfileCompletionService _profileCompletion =
      const ProfileCompletionService();
  Map<String, String> _dismissedPromptStatuses = const <String, String>{};
  Set<String> _sessionDismissedPromptIds = const <String>{};
  String? _promptStateUserId;
  String? _lastLoggedProfileSignature;
  bool _loadingPromptState = false;

  int _indexForInitialTab(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'sync':
        return 1;
      case 'explore':
        return 2;
      case 'aura':
      default:
        return 0;
    }
  }

  TruLuraMode _paletteForTopTab(int index) {
    switch (index) {
      case 1:
        return TruLuraMode.sync;
      case 2:
        return TruLuraMode.trending;
      default:
        return TruLuraMode.aura;
    }
  }

  String _tabForIndex(int index) {
    switch (index) {
      case 1:
        return 'sync';
      case 2:
        return 'explore';
      default:
        return 'aura';
    }
  }

  void _syncPalette(int index) {
    final mode = context.read<TruLuraModeController>();
    mode.setMode(_paletteForTopTab(index));
  }

  void _syncAppTabFromController() {
    context.read<AppState>().setTab(_tabForIndex(_tabController.index));
  }

  String _currentRouteTab() {
    return GoRouterState.of(context).uri.queryParameters['tab'] ?? 'aura';
  }

  void _syncRouteToTab(String tab) {
    if (_currentRouteTab() == tab) return;
    context.go(AppRoutes.homeTab(tab));
  }

  void _applyTabFromRoute(String? rawTab) {
    final index = _indexForInitialTab(rawTab);
    final nextTab = _tabForIndex(index);
    context.read<AppState>().setTab(nextTab);
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  List<Color> _gradientForMood(Mood mood) {
    switch (mood) {
      case Mood.reflective:
        return const [Color(0xFF553C9A), Color(0xFF3B82F6)];
      case Mood.flirty:
        return const [Color(0xFFFF5FA2), Color(0xFF8B5CF6)];
      case Mood.calm:
        return const [Color(0xFFB7D8FF), Color(0xFF6EA8FE)];
      case Mood.healing:
        return const [Color(0xFF2EC4B6), Color(0xFF7BC47F)];
      case Mood.social:
        return const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
    }
  }

  String _labelForMood(Mood mood) {
    switch (mood) {
      case Mood.reflective:
        return 'Reflective';
      case Mood.flirty:
        return 'Flirty';
      case Mood.calm:
        return 'Calm';
      case Mood.healing:
        return 'Healing';
      case Mood.social:
        return 'Social';
    }
  }

  double _sectionMaxWidth(double viewportWidth) {
    return truluraResponsiveContentMaxWidth(viewportWidth);
  }

  Widget _buildPromptCard({
    required BuildContext context,
    required ColorScheme cs,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: TruLuraSurfaces.hairline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDismiss,
                      splashRadius: 18,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    'Optional',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: TruLuraBrandColors.neonPurple.withValues(
                            alpha: 0.92,
                          ),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: onTap,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPromptState(String? userId, {bool force = false}) async {
    if (_loadingPromptState || (!force && _promptStateUserId == userId)) return;
    _loadingPromptState = true;
    final appState = context.read<AppState>();
    try {
      if (userId == null) {
        await appState.hydrateQuizState(userId: null);
        if (!mounted) return;
        setState(() {
          _promptStateUserId = null;
          _dismissedPromptStatuses = const <String, String>{};
          _sessionDismissedPromptIds = const <String>{};
        });
        return;
      }

      final dismissed = await _settings.getDismissedHomePromptStatuses(
        userId: userId,
      );
      final nextLoginExpired = dismissed.entries
          .where((entry) => entry.value == 'next_login')
          .map((entry) => entry.key)
          .toList(growable: false);
      if (nextLoginExpired.isNotEmpty) {
        final cleaned = Map<String, String>.from(dismissed)
          ..removeWhere((key, value) => value == 'next_login');
        await _settings.setDismissedHomePromptStatuses(cleaned, userId: userId);
      }
      await appState.hydrateQuizState(userId: userId);
      final preservedSessionDismissed = _promptStateUserId == userId
          ? _sessionDismissedPromptIds
          : const <String>{};
      if (!mounted) return;
      setState(() {
        _promptStateUserId = userId;
        _dismissedPromptStatuses = Map<String, String>.from(dismissed)
          ..removeWhere((key, value) => value == 'next_login');
        _sessionDismissedPromptIds = preservedSessionDismissed;
      });
    } finally {
      _loadingPromptState = false;
    }
  }

  Future<void> _dismissPrompt(String promptId, String title) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final sheetCs = sheetTheme.colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      sheetCs.surfaceContainerHighest.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hide this suggestion?',
                        style: sheetTheme.textTheme.titleMedium?.copyWith(
                          color: sheetCs.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$title will stay optional either way. You can always revisit it later.',
                        style: sheetTheme.textTheme.bodyMedium?.copyWith(
                          color: sheetCs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          'permanent',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Don’t show again'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          'next_login',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Remind me later'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (choice == null) return;
    if (!mounted) return;

    final userId = context.read<AppProvider>().currentUser?.id;
    final nextStatuses = Map<String, String>.from(_dismissedPromptStatuses)
      ..[promptId] = choice;
    final nextSessionDismissed = choice == 'next_login'
        ? {..._sessionDismissedPromptIds, promptId}
        : {..._sessionDismissedPromptIds, promptId};
    await _settings.setDismissedHomePromptStatuses(
      nextStatuses,
      userId: userId,
    );
    if (!mounted) return;
    setState(() {
      _promptStateUserId = userId;
      _dismissedPromptStatuses = nextStatuses;
      _sessionDismissedPromptIds = nextSessionDismissed;
    });
  }

  bool _shouldShowPrompt(String promptId, bool relevant) {
    final status = _dismissedPromptStatuses[promptId];
    return relevant &&
        status != 'permanent' &&
        status != 'next_login' &&
        !_sessionDismissedPromptIds.contains(promptId);
  }

  @override
  void initState() {
    super.initState();
    final initial = _indexForInitialTab(widget.initialTab);
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: initial);
    _tabController.addListener(() {
      if (mounted) setState(() {});
      if (!_tabController.indexIsChanging) {
        final tab = _tabForIndex(_tabController.index);
        _syncPalette(_tabController.index);
        _syncAppTabFromController();
        _syncRouteToTab(tab);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure palette is correct when landing via deep link.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPalette(_tabController.index);
      _applyTabFromRoute(widget.initialTab);
    });
  }

  @override
  void didUpdateWidget(covariant HomeHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyTabFromRoute(widget.initialTab);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sectionMaxWidth = _sectionMaxWidth(viewportWidth);
    final compactVertical = viewportWidth >= 700;
    final tabHeight = compactVertical ? 38.0 : 42.0;
    final app = context.watch<AppProvider>();
    final appState = context.watch<AppState>();
    final targetTabIndex = _indexForInitialTab(appState.currentTab);
    if (_tabController.index != targetTabIndex &&
        !_tabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _tabController.index == targetTabIndex) return;
        _tabController.animateTo(targetTabIndex);
      });
    }
    final aura = context.watch<AuraController>();
    final user = app.currentUser;
    final profileSummary = _profileCompletion.summarize(user);
    final profileNextStep = _profileCompletion.nextStepCopy(user);
    final userId = user?.id;
    final profileSignature =
        '${user?.id ?? ''}|${user?.username ?? ''}|${user?.bio ?? ''}';
    if (_lastLoggedProfileSignature != profileSignature) {
      _lastLoggedProfileSignature = profileSignature;
      debugPrint(
        'HomeHubScreen loaded profile: '
        'id=${user?.id}, username=${user?.username}, bio=${user?.bio}, '
        'needsOnboarding=${app.needsOnboarding}',
      );
    }
    if (_promptStateUserId != userId && !_loadingPromptState) {
      unawaited(_loadPromptState(userId));
    }
    final soft = app.softModeEnabled;
    final gradientColors = _gradientForMood(aura.mood);
    final tabPalette =
        kTruLuraPalettes[_paletteForTopTab(_tabController.index)]!;
    final environmentA =
        Color.lerp(gradientColors.first, tabPalette.glowA, 0.42) ??
            gradientColors.first;
    final environmentB =
        Color.lerp(gradientColors.last, tabPalette.glowB, 0.34) ??
            gradientColors.last;
    final hasIntent = user?.intents.isNotEmpty ?? false;
    final hasMood = user?.moodTags.isNotEmpty ?? false;
    final showProfilePrompt = _shouldShowPrompt(
      'profile',
      !profileSummary.hasMeaningfulProfile,
    );
    final showVibePrompt = _shouldShowPrompt(
      'vibe',
      !hasMood ||
          (app.askVibeAtStartup && (!app.rememberMoodIntent || !hasMood)),
    );
    final showIntentPrompt = _shouldShowPrompt(
      'intent',
      !hasIntent ||
          (app.askIntentAtStartup && (!app.rememberMoodIntent || !hasIntent)),
    );
    final showQuizPrompt = _shouldShowPrompt(
      'quiz',
      userId != null && !appState.hasPersonalizationQuiz,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradientColors.first.withValues(alpha: soft ? 0.055 : 0.095),
            environmentA.withValues(alpha: soft ? 0.050 : 0.085),
            environmentB.withValues(alpha: soft ? 0.030 : 0.060),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              compactVertical ? 3 : 6,
              16,
              compactVertical ? 2 : 4,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: sectionMaxWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: soft ? 8 : 12,
                      sigmaY: soft ? 8 : 12,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: soft ? 0.12 : 0.095,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: soft ? 0.08 : 0.07,
                          ),
                          width: TruLuraSurfaces.hairline,
                        ),
                        boxShadow: soft
                            ? const <BoxShadow>[]
                            : [
                                BoxShadow(
                                  color: gradientColors.first.withValues(
                                    alpha: 0.13 * app.glowScale,
                                  ),
                                  blurRadius: 24,
                                  spreadRadius: -8,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                      ),
                      child: SizedBox(
                        height: tabHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: TabBar(
                            controller: _tabController,
                            onTap: (index) {
                              final tab = _tabForIndex(index);
                              _syncPalette(index);
                              context.read<AppState>().setTab(tab);
                              _syncRouteToTab(tab);
                            },
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicatorPadding: const EdgeInsets.all(2),
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  gradientColors.first.withValues(alpha: 0.82),
                                  gradientColors.last.withValues(alpha: 0.68),
                                  Colors.white.withValues(alpha: 0.12),
                                ],
                                stops: const [0, 0.78, 1],
                              ),
                              boxShadow: soft
                                  ? const <BoxShadow>[]
                                  : [
                                      ...TruLuraEffects.multiAuraGlow(
                                        gradientColors.first,
                                        gradientColors.last,
                                        intensity: 0.42 * app.glowScale,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            labelColor: cs.onPrimary,
                            unselectedLabelColor:
                                cs.onSurfaceVariant.withValues(alpha: 0.88),
                            labelStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1.0,
                                ),
                            unselectedLabelStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                  height: 1.0,
                                ),
                            tabs: [
                              Tab(height: tabHeight - 6, text: 'Aura'),
                              Tab(height: tabHeight - 6, text: 'Sync'),
                              Tab(height: tabHeight - 6, text: 'Explore'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showProfilePrompt ||
              showVibePrompt ||
              showIntentPrompt ||
              showQuizPrompt)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                compactVertical ? 6 : 8,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: sectionMaxWidth),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: compactVertical ? 176 : 220,
                    ),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        children: [
                          if (showProfilePrompt)
                            _buildPromptCard(
                              context: context,
                              cs: cs,
                              title: 'Continue profile setup',
                              subtitle:
                                  '${profileSummary.statusLabel} • ${profileSummary.percent}% complete. $profileNextStep',
                              actionLabel: 'Complete profile',
                              onTap: () => context.push(
                                Uri(
                                  path: AppRoutes.onboardingProfileSetup,
                                  queryParameters: {
                                    'returnTo': GoRouterState.of(context)
                                        .uri
                                        .toString(),
                                  },
                                ).toString(),
                              ),
                              onDismiss: () => unawaited(
                                _dismissPrompt(
                                    'profile', 'Complete your profile'),
                              ),
                            ),
                          if (showProfilePrompt &&
                              (showVibePrompt ||
                                  showIntentPrompt ||
                                  showQuizPrompt))
                            const SizedBox(height: 12),
                          if (showVibePrompt)
                            _buildPromptCard(
                              context: context,
                              cs: cs,
                              title: hasMood
                                  ? 'Update your vibe'
                                  : 'Set your vibe',
                              subtitle:
                                  'Vibe is a session preference that shapes the tone of your feed and spaces.',
                              actionLabel: 'Choose vibe',
                              onTap: () => context.push(
                                Uri(
                                  path: AppRoutes.onboardingVibe,
                                  queryParameters: {
                                    'returnTo': GoRouterState.of(context)
                                        .uri
                                        .toString(),
                                  },
                                ).toString(),
                              ),
                              onDismiss: () => unawaited(
                                _dismissPrompt('vibe', 'Set your vibe'),
                              ),
                            ),
                          if (showVibePrompt &&
                              (showIntentPrompt || showQuizPrompt))
                            const SizedBox(height: 12),
                          if (showIntentPrompt)
                            _buildPromptCard(
                              context: context,
                              cs: cs,
                              title: hasIntent
                                  ? 'Update your intent'
                                  : 'Choose your intent',
                              subtitle:
                                  'Intent helps TruLura tune recommendations for people, communities, and compatible connections.',
                              actionLabel: 'Choose intent',
                              onTap: () => context.push(
                                Uri(
                                  path: AppRoutes.onboardingIntent,
                                  queryParameters: {
                                    'returnTo': GoRouterState.of(context)
                                        .uri
                                        .toString(),
                                  },
                                ).toString(),
                              ),
                              onDismiss: () => unawaited(
                                _dismissPrompt('intent', 'Choose your intent'),
                              ),
                            ),
                          if (showIntentPrompt && showQuizPrompt)
                            const SizedBox(height: 12),
                          if (showQuizPrompt)
                            Builder(
                              builder: (context) {
                                const registry = QuizRegistryService();
                                final featuredQuiz =
                                    registry.featuredReadyEntry(
                                  category: TruQuizCategory.social,
                                  surface: TruQuizLauncherSurface.homeAura,
                                );
                                final quizEntry = featuredQuiz ??
                                    registry.byId(
                                      TruQuizEngine.friendshipEnergyMatchQuizId,
                                    );
                                final launcher = quizEntry == null
                                    ? AppRoutes.microQuiz
                                    : (registry.launcherPathFor(quizEntry) ??
                                        AppRoutes.microQuiz);
                                return _buildPromptCard(
                                  context: context,
                                  cs: cs,
                                  title:
                                      'Try ${quizEntry?.title ?? 'Friendship Energy Match'}',
                                  subtitle: quizEntry?.subtitle ??
                                      'A few fast prompts can sharpen friend suggestions, feed ranking, and the kinds of interaction nudges Aura gives you.',
                                  actionLabel: 'Open quiz',
                                  onTap: () async {
                                    await context.push(
                                      Uri(
                                        path: launcher,
                                        queryParameters: {
                                          'quiz': quizEntry?.quizId ??
                                              TruQuizEngine
                                                  .friendshipEnergyMatchQuizId,
                                          'returnTo': GoRouterState.of(
                                            context,
                                          ).uri.toString(),
                                        },
                                      ).toString(),
                                    );
                                    if (!mounted) return;
                                    await _loadPromptState(userId, force: true);
                                  },
                                  onDismiss: () => unawaited(
                                    _dismissPrompt(
                                      'quiz',
                                      'Try ${quizEntry?.title ?? 'Friendship Energy Match'}',
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              compactVertical ? 4 : 6,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: sectionMaxWidth),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: Mood.values.map((mood) {
                        final selected = aura.mood == mood;
                        final moodTone = switch (mood) {
                          Mood.flirty => TruLuraModeTone.sync,
                          Mood.healing => TruLuraModeTone.profile,
                          Mood.social => TruLuraModeTone.explore,
                          _ => TruLuraModeTone.aura,
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TruLuraGlowPill(
                            label: _labelForMood(mood),
                            selected: selected,
                            tone: moodTone,
                            onTap: () {
                              debugPrint('Tapped mood: $mood');
                              context.read<AuraController>().updateMood(mood);
                            },
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: compactVertical ? 8 : 9,
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HomeFeedScreen(),
                SyncScreen(),
                ExploreScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
