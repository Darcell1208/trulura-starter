import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/sync_candidate/sync_candidate.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/chat_service.dart';
import 'package:trulura/services/sync_service/sync_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/sync_preview_panel.dart';
import 'package:trulura/widgets/sync_hero_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/tru_toggle.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final SyncService _syncService = SyncService();
  final ChatService _chatService = ChatService();
  final TextEditingController _search = TextEditingController();
  List<User> _users = [];
  bool _isLoading = true;
  bool _hasError = false;
  User? _currentUser;

  TruSyncState? _syncState;
  List<TruSyncSuggestion> _daily = const <TruSyncSuggestion>[];
  List<TruActiveMatch> _activeMatches = const <TruActiveMatch>[];

  final Set<String> _sparkSent = <String>{};
  final Set<String> _glowSent = <String>{};
  final Set<String> _savedForLater = <String>{};

  late final AnimationController _glow;

  TruMatchPurpose _purpose = TruMatchPurpose.dating;
  bool _verifiedOnly = false;
  RangeValues _age = const RangeValues(21, 34);
  double _distance = 15;
  bool _lowEnergy = false;
  bool _paused = false;
  int _activeLimit = 3;
  bool _backgroundVisibility = false;

  static const List<String> _previewFilters = [
    'Mood',
    'Lifestyle',
    'Verified',
    'Nearby'
  ];
  String _selectedPreviewFilter = _previewFilters.first;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final me = await _userService.getCurrentUser();
      final users = await _userService.getAllUsers();
      final syncState =
          me == null ? null : await _syncService.getState(userId: me.id);
      final daily = (me != null)
          ? await _syncService.getDailySuggestions(userId: me.id)
          : const <TruSyncSuggestion>[];
      final active = (me != null)
          ? await _syncService.getActiveMatches(userId: me.id)
          : const <TruActiveMatch>[];

      setState(() {
        _currentUser = me;
        _users = users;
        _syncState = syncState;
        _daily = daily;
        _activeMatches = active;
        if (syncState != null) {
          _purpose = syncState.preferences.purpose;
          _verifiedOnly = syncState.preferences.verifiedOnly;
          _age = RangeValues(syncState.preferences.minAge.toDouble(),
              syncState.preferences.maxAge.toDouble());
          _distance = syncState.preferences.maxDistanceMiles;
          _lowEnergy = syncState.preferences.lowEnergyMode;
          _paused = syncState.preferences.paused;
          _activeLimit = syncState.preferences.activeMatchLimit;
          _backgroundVisibility =
              syncState.preferences.backgroundVisibilityEnabled;
        }
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      truLogStateError('Sync._load', e);
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<_SyncCardData> get _cards {
    final query = _search.text.trim().toLowerCase();
    final byId = {for (final u in _users) u.id: u};
    final me = _currentUser;
    if (me == null) return const <_SyncCardData>[];

    final suggestions = _daily.where((s) {
      final u = byId[s.targetUserId];
      if (u == null) return false;
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query) ||
          (u.bio ?? '').toLowerCase().contains(query);
    }).toList(growable: false);

    return suggestions
        .map((s) {
          final u = byId[s.targetUserId];
          if (u == null) return null;
          return _SyncCardData(
              user: u,
              compatibility: s.report.overall,
              reasons: s.reasons,
              suggestion: s);
        })
        .whereType<_SyncCardData>()
        .toList(growable: false);
  }

  bool get _isProfileIncompleteForSync {
    final u = _currentUser;
    if (u == null) return true;
    final hasBio = (u.bio ?? '').trim().isNotEmpty;
    final hasIntent = u.intents.isNotEmpty;
    final hasMood = u.moodTags.isNotEmpty;
    return !(hasBio && hasIntent && hasMood);
  }

  bool get _filtersAreStrict {
    final isDefaultAge = _age.start.round() == 21 && _age.end.round() == 34;
    final isDefaultDistance = _distance.round() == 15;
    final isDefaultPurpose = _purpose == TruMatchPurpose.dating;
    return _verifiedOnly ||
        !isDefaultAge ||
        !isDefaultDistance ||
        !isDefaultPurpose ||
        _search.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final fullSyncMode = app.fullSyncModeEnabled;

    final cards = _cards;
    final enabled = _syncState?.enabled ?? false;
    final activeMatches = _activeMatches
        .where((m) => m.status != TruActiveMatchStatus.closed)
        .length;
    final topPercent = cards.isNotEmpty ? cards.first.compatibility : 88;

    return SafeArea(
      bottom: false,
      child: _SyncLane(
        padding: EdgeInsets.zero,
        child: ListView(
          primary: false,
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            kTruluraBottomNavClearance + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _CinematicSyncHero(
              glow: _glow,
              enabled: enabled,
              paused: _paused,
              percent: topPercent,
              purpose: _purpose,
              activeMatches: activeMatches,
              activeLimit: _activeLimit,
              onActivate: _handleActivate,
              onOpenFilters: () => _showFilters(fullSyncMode),
            ),
            const SizedBox(height: 12),
            if (ui == TruUiState.loading)
              const _SyncSkeleton()
            else if (ui == TruUiState.empty)
              TruStatePanel(
                tone: TruLuraModeTone.sync,
                glyph: TruLuraGlyph.sync,
                title: 'Express the frequency only you carry',
                message:
                    'Add intent, mood, and rhythm signals so Sync can read your resonance with others.',
                actions: [
                  TruStateAction(
                      label: 'Complete alignment setup',
                      glyph: TruLuraGlyph.insights,
                      onTap: () => context.push('/onboarding/intent'),
                      primary: true),
                  TruStateAction(
                      label: 'Add energy signals',
                      glyph: TruLuraGlyph.spark,
                      onTap: () => context.push('/onboarding/intent')),
                ],
              )
            else if (ui == TruUiState.action)
              TruStatePanel(
                tone: TruLuraModeTone.sync,
                glyph: TruLuraGlyph.heart,
                title: 'Soft Spark sent',
                message:
                    'Your resonance signal is pending. If the alignment is mutual, TruMessages opens the thread.',
                actions: [
                  TruStateAction(
                      label: 'Go to inbox',
                      glyph: TruLuraGlyph.messages,
                      onTap: () => context.go(AppRoutes.messages),
                      primary: true),
                  TruStateAction(
                      label: 'Return to Sync',
                      glyph: TruLuraGlyph.sync,
                      onTap: () {}),
                ],
              )
            else
              _buildBody(
                cards: cards,
                fullSyncMode: fullSyncMode,
                fullSyncEnabled: !soft,
                syncEnabled: enabled,
                activeMatches: activeMatches,
              ),
          ],
        ),
      ),
    );
  }

  void _showFilters(bool fullSyncMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SyncFiltersSheet(
        fullSyncMode: fullSyncMode,
        purpose: _purpose,
        verifiedOnly: _verifiedOnly,
        age: _age,
        distance: _distance,
        lowEnergy: _lowEnergy,
        paused: _paused,
        activeLimit: _activeLimit,
        backgroundVisibility: _backgroundVisibility,
        onChanged: (next) {
          setState(() {
            _purpose = next.purpose;
            _verifiedOnly = next.verifiedOnly;
            _age = next.age;
            _distance = next.distance;
            _lowEnergy = next.lowEnergy;
            _paused = next.paused;
            _activeLimit = next.activeLimit;
            _backgroundVisibility = next.backgroundVisibility;
          });
          unawaited(_persistPreferences());
          if (next.fullSyncMode != fullSyncMode) {
            context
                .read<AppProvider>()
                .setFullSyncModeEnabled(next.fullSyncMode);
          }
        },
      ),
    );
  }

  Future<void> _persistPreferences() async {
    final me = _currentUser;
    if (me == null) return;
    final current = _syncState ?? await _syncService.getState(userId: me.id);
    final prefs = current.preferences.copyWith(
      purpose: _purpose,
      verifiedOnly: _verifiedOnly,
      minAge: _age.start.round(),
      maxAge: _age.end.round(),
      maxDistanceMiles: _distance,
      lowEnergyMode: _lowEnergy,
      paused: _paused,
      activeMatchLimit: _activeLimit,
      backgroundVisibilityEnabled: _backgroundVisibility,
    );
    final next =
        await _syncService.updatePreferences(userId: me.id, preferences: prefs);
    if (!mounted) return;
    setState(() => _syncState = next);
  }

  Future<void> _refreshDaily() async {
    final me = _currentUser;
    if (me == null) return;
    final daily = await _syncService.getDailySuggestions(userId: me.id);
    final active = await _syncService.getActiveMatches(userId: me.id);
    if (!mounted) return;
    setState(() {
      _daily = daily;
      _activeMatches = active;
    });
  }

  Future<void> _handleActivate() async {
    final me = _currentUser;
    if (me == null) return;
    final next = await _syncService.setEnabled(userId: me.id, enabled: true);
    if (!mounted) return;
    setState(() => _syncState = next);
    await _persistPreferences();
    await _refreshDaily();
  }

  Future<void> _handleSignal(
      _SyncCardData card, TruInteractionSignal signal) async {
    final me = _currentUser;
    final s = card.suggestion;
    if (me == null || s == null) return;

    final activeCount = _activeMatches
        .where((m) => m.status != TruActiveMatchStatus.closed)
        .length;
    if (activeCount >= _activeLimit) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'You’re at your active match limit ($_activeLimit). Pause or close a match to make room.')));
      return;
    }

    setState(() {
      if (signal == TruInteractionSignal.spark) _sparkSent.add(card.user.id);
      if (signal == TruInteractionSignal.glow) _glowSent.add(card.user.id);
    });

    final result = await _syncService.sendSignal(
        userId: me.id,
        targetUserId: card.user.id,
        signal: signal,
        report: s.report);
    if (!mounted) return;

    if (result.status == TruInteractionResultStatus.pending ||
        result.status == TruInteractionResultStatus.alreadySent ||
        result.status == TruInteractionResultStatus.recorded) {
      final label = signal.label;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('$label sent • held as a soft signal until it’s mutual.')));
      // We keep the suggestion visible so the user can still explore.
      return;
    }

    if (result.status == TruInteractionResultStatus.mutual &&
        result.createdMatch != null) {
      // Create chat + register active match.
      final chat = await _chatService.ensureChatWithUser(
          currentUserId: me.id, targetUserId: card.user.id);
      if (chat == null) {
        debugPrint('Sync._handleSignal: chat creation failed');
        return;
      }

      await _syncService.addActiveMatchFromSignal(
          userId: me.id,
          targetUserId: card.user.id,
          chatId: chat.id,
          signal: signal);
      await _syncService.passSuggestion(userId: me.id, suggestionId: s.id);
      await _refreshDaily();
      if (!mounted) return;

      await _openGuidedPromptSheet(
          target: card.user, report: s.report, chatId: chat.id);
      return;
    }
  }

  Future<void> _openGuidedPromptSheet(
      {required User target,
      required TruPairCompatibilityReport report,
      required String chatId}) async {
    final me = _currentUser;
    if (me == null) return;
    final prompts = await _syncService.buildGuidedPrompts(
        viewer: me, target: target, report: report, lowEnergyMode: _lowEnergy);
    if (!mounted) return;

    // ignore: use_build_context_synchronously
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        final meetIdeas =
            _syncService.suggestSafeMeetIdeas(purpose: report.purpose);
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Guided start',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900))),
                    IconButton(
                        onPressed: () => context.pop(),
                        icon: const TruLuraIcon(
                            glyph: TruLuraGlyph.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                    'Optional prompts based on your compatibility layers. Keep it calm, specific, and real.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurface.withValues(alpha: 0.74))),
                const SizedBox(height: 12),
                ...prompts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TruLuraGlassCard(
                        radius: 18,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(p,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            height: 1.35,
                                            fontWeight: FontWeight.w700))),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: p));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied prompt')));
                              },
                              icon: Icon(Icons.content_copy_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.82)),
                              style: IconButton.styleFrom(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 6),
                Text('Safe meet ideas',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: meetIdeas
                      .take(5)
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: cs.outline.withValues(alpha: 0.12)),
                            ),
                            child: Text(e,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ))
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          context.pop();
                          context.go(AppRoutes.messages);
                        },
                        child: const Text('Go to inbox'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TruLuraPrimaryButton(
                        onPressed: () {
                          context.pop();
                          context.go('${AppRoutes.messages}/thread/$chatId');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Open chat'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required List<_SyncCardData> cards,
    required bool fullSyncMode,
    required bool fullSyncEnabled,
    required bool syncEnabled,
    required int activeMatches,
  }) {
    if (_isLoading) return const _SyncSkeleton();

    if (_hasError) {
      return TruStatePanel(
        tone: TruLuraModeTone.sync,
        glyph: TruLuraGlyph.info,
        title: 'Sync couldn’t load',
        message: 'We couldn’t load Sync right now. Try again.',
        actions: [
          TruStateAction(
              label: 'Retry',
              glyph: TruLuraGlyph.spark,
              onTap: _load,
              primary: true)
        ],
      );
    }

    if (_isProfileIncompleteForSync) {
      return _buildPreviewBody(
        title: 'Complete your Sync profile',
        subtitle:
            'Your alignment chamber is waiting for intent, mood, and bio details so it can recognize the right kind of connection.',
        primaryLabel: 'Finish setup',
        primaryGlyph: TruLuraGlyph.edit,
        onPrimary: () => context.push('/onboarding/intent'),
      );
    }

    final enabled = _syncState?.enabled ?? false;
    if (!enabled) {
      return _buildPreviewBody(
        title: 'Sync is ready when you are',
        subtitle:
            'Step into today\'s alignment chamber: aura chemistry, emotional rhythm, and safe first signals are already tuned.',
        primaryLabel: 'Activate Sync',
        primaryGlyph: TruLuraGlyph.spark,
        onPrimary: _handleActivate,
      );
    }

    if (_paused) {
      return TruStatePanel(
        tone: TruLuraModeTone.sync,
        glyph: TruLuraGlyph.info,
        title: 'Sync is paused',
        message:
            'You won’t receive new suggestions while paused. Your existing matches remain accessible.',
        actions: [
          TruStateAction(
              label: 'Resume Sync',
              glyph: TruLuraGlyph.sync,
              onTap: () async {
                setState(() => _paused = false);
                await _persistPreferences();
                await _refreshDaily();
              },
              primary: true)
        ],
      );
    }

    if (cards.isEmpty) {
      return _buildPreviewBody(
        title: _filtersAreStrict
            ? 'Your boundaries may be limiting your drop'
            : 'Your next curated drop is tuning itself',
        subtitle: _filtersAreStrict
            ? 'Try widening age, distance, or intent settings to reveal more potential connections.'
            : 'Sync waits for stronger alignment instead of forcing filler matches.',
        primaryLabel: _filtersAreStrict ? 'Reset filters' : 'Refresh drop',
        primaryGlyph:
            _filtersAreStrict ? TruLuraGlyph.close : TruLuraGlyph.sync,
        onPrimary: _filtersAreStrict
            ? () {
                setState(() {
                  _search.clear();
                  _purpose = TruMatchPurpose.dating;
                  _verifiedOnly = false;
                  _age = const RangeValues(21, 34);
                  _distance = 15;
                  _lowEnergy = false;
                  _activeLimit = 3;
                  _backgroundVisibility = false;
                });
                unawaited(_persistPreferences());
              }
            : () => unawaited(_refreshDaily()),
      );
    }

    final visibleCards = cards.take(4).toList(growable: false);
    final remainingToday = (3 - _sparkSent.length).clamp(0, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SyncSectionHeader(
          title: 'Resonance visualization',
          subtitle:
              'A live read of how your frequency, intent, and pacing are tuned for other people.',
        ),
        const SizedBox(height: 10),
        _SyncRhythmCard(
          remainingToday: remainingToday,
          lowEnergy: _lowEnergy,
          paused: _paused,
          activeMatches: activeMatches,
          activeLimit: _activeLimit,
        ),
        const SizedBox(height: 12),
        _CompatibilityAlignmentPreview(
          purpose: _purpose,
          lowEnergy: _lowEnergy,
          activeMatches: activeMatches,
          activeLimit: _activeLimit,
        ),
        const SizedBox(height: 12),
        const _SyncSectionHeader(
          title: 'Suggested connections',
          subtitle:
              'A small daily set of people whose signals may resonate with yours.',
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < visibleCards.length; i++) ...[
          _CuratedMatchCard(
            data: visibleCards[i],
            saved: _savedForLater.contains(visibleCards[i].user.id),
            sparkSent: _sparkSent.contains(visibleCards[i].user.id),
            onSpark: () => unawaited(
              _handleSignal(visibleCards[i], TruInteractionSignal.spark),
            ),
            onPreview: () => _openCuratedPreview(visibleCards[i]),
            onSave: () => setState(() {
              final id = visibleCards[i].user.id;
              if (_savedForLater.contains(id)) {
                _savedForLater.remove(id);
              } else {
                _savedForLater.add(id);
              }
            }),
          ),
          if (i < visibleCards.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        _WhyThisMatchPanel(cards: visibleCards),
        const SizedBox(height: 12),
        const _ConversationOpenersPanel(),
        const SizedBox(height: 12),
        _SyncCommandDeck(
          fullSyncMode: fullSyncMode,
          fullSyncEnabled: fullSyncEnabled,
          syncEnabled: syncEnabled,
          paused: _paused,
          purpose: _purpose,
          lowEnergyMode: _lowEnergy,
          activeMatches: activeMatches,
          activeLimit: _activeLimit,
          onActivate: _handleActivate,
          onOpenFilters: () => _showFilters(fullSyncMode),
          onToggleFullSync: (v) =>
              context.read<AppProvider>().setFullSyncModeEnabled(v),
          onTogglePause: (v) async {
            setState(() => _paused = v);
            await _persistPreferences();
            await _refreshDaily();
          },
          onToggleLowEnergy: (v) async {
            setState(() => _lowEnergy = v);
            await _persistPreferences();
            await _refreshDaily();
          },
        ),
        const SizedBox(height: 12),
        const _SyncSectionHeader(
          title: 'Discovery',
          subtitle:
              'Search the wider resonance field without turning Sync into another feed.',
        ),
        const SizedBox(height: 10),
        SyncPreviewPanel(
          mode: TruLuraMode.sync,
          controller: _search,
          filters: _previewFilters,
          selectedFilter: _selectedPreviewFilter,
          onFilterChanged: (f) => setState(() => _selectedPreviewFilter = f),
          onSearchChanged: (_) => setState(() {}),
          profiles: cards.take(12).map((c) {
            final u = c.user;
            final avatar = u.profileImage != null
                ? AssetImage(u.profileImage!)
                : const AssetImage(
                    'assets/images/portrait_young_woman_smiling_null_1772162274859.jpg');
            final descriptor = (c.reasons.isNotEmpty)
                ? 'Energy: ${c.reasons.first}'
                : 'Energy: mutual resonance';
            return MiniProfile(
                name: u.publicDisplayName,
                match: c.compatibility,
                descriptor: descriptor,
                avatar: avatar);
          }).toList(),
          onTapProfile: (m) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${m.name}')),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreviewBody({
    required String title,
    required String subtitle,
    required String primaryLabel,
    required TruLuraGlyph primaryGlyph,
    required VoidCallback onPrimary,
  }) {
    final activeMatches = _activeMatches
        .where((m) => m.status != TruActiveMatchStatus.closed)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SyncPreviewHero(
          title: title,
          subtitle: subtitle,
          primaryLabel: primaryLabel,
          primaryGlyph: primaryGlyph,
          onPrimary: onPrimary,
        ),
        const SizedBox(height: 12),
        _PreviewMatchSignal(
          onPrimary: onPrimary,
          primaryLabel: primaryLabel,
        ),
        const SizedBox(height: 12),
        _CompatibilityAlignmentPreview(
          purpose: _purpose,
          lowEnergy: _lowEnergy,
          activeMatches: activeMatches,
          activeLimit: _activeLimit,
        ),
        const SizedBox(height: 12),
        _DailyDropPlaceholder(
          paused: _paused,
          verifiedOnly: _verifiedOnly,
          distance: _distance,
          age: _age,
        ),
        const SizedBox(height: 12),
        const _ConversationOpenersPanel(),
      ],
    );
  }

  void _openCuratedPreview(_SyncCardData card) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        final tags = _syncTagsFor(card);
        final saved = _savedForLater.contains(card.user.id);
        final media = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (media.size.height * 0.72).clamp(340.0, 620.0),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
              ),
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.user.publicDisplayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        _CompatibilityPill(percent: card.compatibility),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const TruLuraIcon(
                              glyph: TruLuraGlyph.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _syncExplanationFor(card),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.76),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          TruluraFeedChip(label: tag, selected: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                if (saved) {
                                  _savedForLater.remove(card.user.id);
                                } else {
                                  _savedForLater.add(card.user.id);
                                }
                              });
                              context.pop();
                            },
                            child: Text(saved ? 'Saved' : 'Save Energy'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _sparkSent.contains(card.user.id)
                                ? null
                                : () {
                                    unawaited(_handleSignal(
                                        card, TruInteractionSignal.spark));
                                    context.pop();
                                  },
                            child: Text(_sparkSent.contains(card.user.id)
                                ? 'Spark Sent'
                                : 'Spark Softly'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CinematicSyncHero extends StatelessWidget {
  final Animation<double> glow;
  final bool enabled;
  final bool paused;
  final int percent;
  final TruMatchPurpose purpose;
  final int activeMatches;
  final int activeLimit;
  final VoidCallback onActivate;
  final VoidCallback onOpenFilters;

  const _CinematicSyncHero({
    required this.glow,
    required this.enabled,
    required this.paused,
    required this.percent,
    required this.purpose,
    required this.activeMatches,
    required this.activeLimit,
    required this.onActivate,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final t = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        final pulse = soft ? 0.0 : glow.value;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 360),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -90,
                top: -70,
                width: 360,
                height: 360,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        TruLuraTokens.auraPink
                            .withValues(alpha: 0.14 + pulse * 0.08),
                        TruLuraBrandColors.glowGold
                            .withValues(alpha: 0.05 + pulse * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SyncHeroAtmospherePainter(progress: pulse),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        TruLuraTokens.ink.withValues(alpha: 0.10),
                        TruLuraTokens.ink.withValues(alpha: 0.36),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final narrative = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SYNC RESONANCE ENGINE',
                          style: t.labelSmall?.copyWith(
                            color: TruLuraBrandColors.glowGold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Express the frequency only you carry.',
                          style: t.displaySmall?.copyWith(
                            color: TruLuraTokens.textPrimary,
                            fontFamily: 'Georgia',
                            height: 1.02,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          enabled
                              ? 'Sync reads how your frequency resonates with others before a Soft Spark is ever sent.'
                              : 'Turn on Sync to translate your frequency into resonance with other people.',
                          style: t.bodyMedium?.copyWith(
                            color: TruLuraTokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SyncMiniPill(
                                label:
                                    paused ? 'Pacing paused' : 'Pacing live'),
                            _SyncMiniPill(label: purpose.label),
                            _SyncMiniPill(
                                label: '$activeMatches/$activeLimit active'),
                            _SyncMiniPill(
                                label: enabled
                                    ? 'Resonance live'
                                    : 'Frequency ready'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: enabled ? null : onActivate,
                              icon: const TruLuraIcon(
                                glyph: TruLuraGlyph.spark,
                                size: 17,
                                active: true,
                              ),
                              label: Text(
                                  enabled ? 'Sync Active' : 'Activate Sync'),
                            ),
                            OutlinedButton.icon(
                              onPressed: onOpenFilters,
                              icon: const TruLuraIcon(
                                glyph: TruLuraGlyph.filter,
                                size: 17,
                              ),
                              label: const Text('Tune Field'),
                            ),
                          ],
                        ),
                      ],
                    );
                    final ring = _ResonanceRing(
                      progress: pulse,
                      percent: percent,
                      enabled: enabled,
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: ring),
                          const SizedBox(height: 18),
                          narrative,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 5, child: narrative),
                        const SizedBox(width: 26),
                        Expanded(flex: 4, child: Center(child: ring)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResonanceRing extends StatelessWidget {
  final double progress;
  final int percent;
  final bool enabled;

  const _ResonanceRing({
    required this.progress,
    required this.percent,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: _ResonanceRingPainter(progress: progress, percent: percent),
        child: Center(
          child: Container(
            width: 142,
            height: 142,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TruLuraTokens.auraPink.withValues(alpha: 0.38),
                  TruLuraBrandColors.glowGold.withValues(alpha: 0.16),
                  TruLuraTokens.ink.withValues(alpha: 0.78),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percent%',
                  style: t.headlineMedium?.copyWith(
                    color: TruLuraTokens.textPrimary,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enabled ? 'Resonance' : 'Frequency',
                  style: t.labelMedium?.copyWith(
                    color: TruLuraTokens.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncCommandDeck extends StatelessWidget {
  final bool fullSyncMode;
  final bool fullSyncEnabled;
  final bool syncEnabled;
  final bool paused;
  final TruMatchPurpose purpose;
  final bool lowEnergyMode;
  final int activeMatches;
  final int activeLimit;
  final VoidCallback onActivate;
  final VoidCallback onOpenFilters;
  final ValueChanged<bool> onToggleFullSync;
  final ValueChanged<bool> onTogglePause;
  final ValueChanged<bool> onToggleLowEnergy;

  const _SyncCommandDeck({
    required this.fullSyncMode,
    required this.fullSyncEnabled,
    required this.syncEnabled,
    required this.paused,
    required this.purpose,
    required this.lowEnergyMode,
    required this.activeMatches,
    required this.activeLimit,
    required this.onActivate,
    required this.onOpenFilters,
    required this.onToggleFullSync,
    required this.onTogglePause,
    required this.onToggleLowEnergy,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullSync = _FullSyncToggle(
          value: fullSyncMode,
          enabled: fullSyncEnabled,
          onChanged: onToggleFullSync,
        );
        final activation = _SyncActivationCard(
          enabled: syncEnabled,
          paused: paused,
          purpose: purpose,
          lowEnergyMode: lowEnergyMode,
          activeMatches: activeMatches,
          activeLimit: activeLimit,
          onActivate: onActivate,
          onTogglePause: onTogglePause,
          onToggleLowEnergy: onToggleLowEnergy,
        );
        final filterButton = _FilterButton(onTap: onOpenFilters);
        if (constraints.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 330, child: fullSync),
              const SizedBox(width: 12),
              Expanded(child: activation),
              const SizedBox(width: 12),
              filterButton,
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: fullSync),
                const SizedBox(width: 10),
                filterButton,
              ],
            ),
            const SizedBox(height: 8),
            activation,
          ],
        );
      },
    );
  }
}

class _SyncHeroAtmospherePainter extends CustomPainter {
  final double progress;

  const _SyncHeroAtmospherePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07030E),
            Color(0xFF1A0630),
            Color(0xFF331039),
            Color(0xFF140815),
          ],
        ).createShader(rect),
    );

    final warm = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(0.72 - progress * 0.18, -0.34 + progress * 0.10),
        radius: 0.96,
        colors: [
          TruLuraBrandColors.glowGold.withValues(alpha: 0.32),
          TruLuraTokens.auraPink.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, warm);

    final magenta = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(-0.65 + progress * 0.22, 0.48),
        radius: 0.92,
        colors: [
          TruLuraBrandColors.nebulaMagenta.withValues(alpha: 0.26),
          TruLuraBrandColors.nebulaViolet.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, magenta);

    final stars = Paint()
      ..color = Colors.white.withValues(alpha: 0.14 + progress * 0.06);
    for (var i = 0; i < 42; i++) {
      final x = ((math.sin(i * 41.7) + 1) / 2) * size.width;
      final y = ((math.cos(i * 29.1) + 1) / 2) * size.height * 0.72;
      canvas.drawCircle(Offset(x, y), i % 9 == 0 ? 1.1 : 0.55, stars);
    }
  }

  @override
  bool shouldRepaint(covariant _SyncHeroAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ResonanceRingPainter extends CustomPainter {
  final double progress;
  final int percent;

  const _ResonanceRingPainter({
    required this.progress,
    required this.percent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final normalized = (percent / 100).clamp(0.0, 1.0);
    for (var i = 0; i < 5; i++) {
      final radius = 62.0 + i * 18;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect.inflate(i.isEven ? 8 : -3),
        -math.pi / 2 + progress * math.pi * 0.2 + i * 0.22,
        math.pi * 2 * (0.45 + normalized * 0.36),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? 3 : 1.2
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [
              TruLuraTokens.auraPink.withValues(alpha: 0.12),
              TruLuraBrandColors.glowGold.withValues(alpha: 0.58),
              TruLuraBrandColors.nebulaMagenta.withValues(alpha: 0.48),
              TruLuraTokens.auraPink.withValues(alpha: 0.12),
            ],
          ).createShader(rect),
      );
    }

    final nodePaint = Paint()
      ..blendMode = BlendMode.plus
      ..color = TruLuraBrandColors.glowGold.withValues(alpha: 0.62);
    for (var i = 0; i < 7; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 2 / 7;
      final radius = 86 + (i % 3) * 15;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        i.isEven ? 2.4 : 1.5,
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResonanceRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.percent != percent;
  }
}

class _SyncPreviewHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryLabel;
  final TruLuraGlyph primaryGlyph;
  final VoidCallback onPrimary;

  const _SyncPreviewHero({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryGlyph,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      tone: TruLuraModeTone.sync,
      radius: 24,
      depth: true,
      glow: TruLuraBrandColors.syncRose,
      tint: TruLuraBrandColors.syncRose.withValues(alpha: 0.055),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TruLuraBrandColors.syncRose.withValues(alpha: 0.42),
                      TruLuraBrandColors.nebulaViolet.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: const TruLuraIcon(
                  glyph: TruLuraGlyph.sync,
                  size: 24,
                  active: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TruLuraPrimaryButton(
            onPressed: onPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TruLuraIcon(glyph: primaryGlyph, size: 18, active: true),
                const SizedBox(width: 10),
                Text(primaryLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMatchSignal extends StatelessWidget {
  final VoidCallback onPrimary;
  final String primaryLabel;

  const _PreviewMatchSignal({
    required this.onPrimary,
    required this.primaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      tone: TruLuraModeTone.sync,
      radius: 24,
      padding: const EdgeInsets.all(14),
      tint: TruLuraTokens.auraPink.withValues(alpha: 0.045),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 620;
          final visual = SizedBox(
            width: wide ? 190 : double.infinity,
            height: 156,
            child: CustomPaint(
              painter: const _PreviewSignalPainter(),
              child: Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        TruLuraBrandColors.glowGold.withValues(alpha: 0.30),
                        TruLuraTokens.auraPink.withValues(alpha: 0.20),
                        TruLuraTokens.ink.withValues(alpha: 0.72),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const TruLuraIcon(
                    glyph: TruLuraGlyph.heartOutline,
                    size: 34,
                    active: true,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emotional match preview',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                'A sample resonance drop shows the shape Sync is preparing: aura tags, intent, pacing, and a reason before any Soft Spark.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _SyncMiniPill(label: 'warm rhythm'),
                  _SyncMiniPill(label: 'clear intent'),
                  _SyncMiniPill(label: 'slow pacing'),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ],
          );
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                visual,
                const SizedBox(height: 12),
                copy,
              ],
            );
          }
          return Row(
            children: [
              visual,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewSignalPainter extends CustomPainter {
  const _PreviewSignalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            TruLuraTokens.auraPink.withValues(alpha: 0.18),
            TruLuraBrandColors.glowGold.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCircle(center: center, radius: 42 + i * 18)
            .inflate(i.isEven ? 6 : -3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color =
              (i.isEven ? TruLuraTokens.auraPink : TruLuraBrandColors.glowGold)
                  .withValues(alpha: 0.26 - i * 0.035),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewSignalPainter oldDelegate) => false;
}

class _CompatibilityAlignmentPreview extends StatelessWidget {
  final TruMatchPurpose purpose;
  final bool lowEnergy;
  final int activeMatches;
  final int activeLimit;

  const _CompatibilityAlignmentPreview({
    required this.purpose,
    required this.lowEnergy,
    required this.activeMatches,
    required this.activeLimit,
  });

  @override
  Widget build(BuildContext context) {
    return TruLuraGlassCard(
      tone: TruLuraModeTone.sync,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compatibility insights',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _AlignmentMeter(label: 'Emotional resonance', value: 82),
          const SizedBox(height: 9),
          _AlignmentMeter(
              label: 'Intent clarity (${purpose.label})', value: 76),
          const SizedBox(height: 9),
          _AlignmentMeter(
              label: lowEnergy ? 'Gentle pacing' : 'Conversation readiness',
              value: lowEnergy ? 88 : 71),
          const SizedBox(height: 12),
          Text(
            'Bandwidth $activeMatches/$activeLimit keeps the connection field focused, humane, and paced.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _AlignmentMeter extends StatelessWidget {
  final String label;
  final int value;

  const _AlignmentMeter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction = value.clamp(0, 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ),
            Text('$value%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w900,
                    )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: fraction,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.36),
            valueColor:
                const AlwaysStoppedAnimation(TruLuraBrandColors.syncRose),
          ),
        ),
      ],
    );
  }
}

class _DailyDropPlaceholder extends StatelessWidget {
  final bool paused;
  final bool verifiedOnly;
  final double distance;
  final RangeValues age;

  const _DailyDropPlaceholder({
    required this.paused,
    required this.verifiedOnly,
    required this.distance,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    return TruLuraGlassCard(
      tone: TruLuraModeTone.sync,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily soul drop',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SyncMiniPill(label: paused ? 'Paused' : 'Ready to tune'),
              _SyncMiniPill(
                  label: verifiedOnly ? 'Verified only' : 'Open trust'),
              _SyncMiniPill(label: '${distance.round()} mi radius'),
              _SyncMiniPill(
                  label: '${age.start.round()}-${age.end.round()} age band'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your connection field is shaped by emotional bandwidth, trust settings, and the kind of first conversation that would feel safe to begin.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.70),
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _SyncMiniPill extends StatelessWidget {
  final String label;

  const _SyncMiniPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: TruLuraBrandColors.syncRose.withValues(alpha: 0.10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
}

class _SyncLane extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SyncLane({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: truluraResponsiveContentMaxWidth(
              MediaQuery.sizeOf(context).width,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SyncSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SyncSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.70),
                height: 1.32,
              ),
        ),
      ],
    );
  }
}

class _SyncRhythmCard extends StatelessWidget {
  final int remainingToday;
  final bool lowEnergy;
  final bool paused;
  final int activeMatches;
  final int activeLimit;

  const _SyncRhythmCard({
    required this.remainingToday,
    required this.lowEnergy,
    required this.paused,
    required this.activeMatches,
    required this.activeLimit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = paused
        ? 'Sync paused - existing matches stay available'
        : lowEnergy
            ? 'Low-energy pacing active'
            : '$remainingToday curated introductions remaining today';
    return TruLuraGlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Row(
        children: [
          const TruLuraIcon(glyph: TruLuraGlyph.sync, size: 18, active: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$activeMatches/$activeLimit active',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CuratedMatchCard extends StatelessWidget {
  final _SyncCardData data;
  final bool saved;
  final bool sparkSent;
  final VoidCallback onSpark;
  final VoidCallback onPreview;
  final VoidCallback onSave;

  const _CuratedMatchCard({
    required this.data,
    required this.saved,
    required this.sparkSent,
    required this.onSpark,
    required this.onPreview,
    required this.onSave,
  });

  ImageProvider<Object>? _imageProviderFor(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    final isNetwork = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isNetwork ? NetworkImage(value) : AssetImage(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tags = _syncTagsFor(data);
    final image = _imageProviderFor(data.user.profileImage);
    return TruLuraGlassCard(
      tone: TruLuraModeTone.sync,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: image,
                backgroundColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.48),
                child: image == null
                    ? const TruLuraIcon(glyph: TruLuraGlyph.person, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.user.publicDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _syncExplanationFor(data),
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
              const SizedBox(width: 10),
              _CompatibilityPill(percent: data.compatibility),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              for (final tag in tags)
                TruluraFeedChip(label: tag, selected: tag == tags.first),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: sparkSent ? null : onSpark,
                  child: Text(sparkSent ? 'Spark Sent' : 'Spark Softly'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                    onPressed: onPreview, child: const Text('Preview')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: onSave,
                  child: Text(saved ? 'Saved' : 'Save Energy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompatibilityPill extends StatelessWidget {
  final int percent;

  const _CompatibilityPill({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: TruLuraTokens.auraGradient(opacity: 0.92),
      ),
      child: Text(
        percent >= 82
            ? 'deep rhythm'
            : percent >= 68
                ? 'warm rhythm'
                : 'soft opening',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _WhyThisMatchPanel extends StatelessWidget {
  final List<_SyncCardData> cards;

  const _WhyThisMatchPanel({required this.cards});

  @override
  Widget build(BuildContext context) {
    final signals = [
      'Similar conversation pacing',
      'Aligned social energy',
      'Shared quiet-night preferences',
      'Both active in reflective Aura',
    ];
    return TruLuraGlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why this resonance surfaced',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final signal in signals.take(cards.length.clamp(2, 4)))
                TruluraFeedChip(label: signal, selected: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversationOpenersPanel extends StatelessWidget {
  const _ConversationOpenersPanel();

  @override
  Widget build(BuildContext context) {
    const openers = [
      'What kind of energy are you protecting lately?',
      'What\'s been calming your mind recently?',
      'Are you more social or reflective tonight?',
    ];
    return TruLuraGlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Easy opener suggestions',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          for (final opener in openers) ...[
            Text(
              opener,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.32, fontWeight: FontWeight.w700),
            ),
            if (opener != openers.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

List<String> _syncTagsFor(_SyncCardData card) {
  final base = card.reasons
      .map((reason) => reason.replaceAll('✨', '').trim())
      .where((reason) => reason.isNotEmpty)
      .take(3)
      .toList(growable: true);
  if (base.length < 3) {
    base.addAll(const [
      'calm conversation',
      'reflective energy',
      'slow pacing',
    ].skip(base.length));
  }
  return base.take(3).toList(growable: false);
}

String _syncExplanationFor(_SyncCardData card) {
  final tags = _syncTagsFor(card);
  if (card.compatibility >= 88) {
    return 'Both value ${tags.first.toLowerCase()} and slower pacing.';
  }
  if (card.compatibility >= 78) {
    return 'Shared reflective communication style with similar emotional bandwidth tonight.';
  }
  return 'Similar social energy and enough overlap for a gentle first conversation.';
}

// ignore: unused_element
class _SyncHeroCardAdapter extends StatelessWidget {
  final _SyncCardData data;
  final double distanceMiles;
  final VoidCallback onPass;
  final VoidCallback onSpark;
  final VoidCallback onGlow;
  final bool sparkSent;
  final bool glowSent;

  const _SyncHeroCardAdapter({
    required this.data,
    required this.distanceMiles,
    required this.onPass,
    required this.onSpark,
    required this.onGlow,
    required this.sparkSent,
    required this.glowSent,
  });

  @override
  Widget build(BuildContext context) {
    final name = data.user.publicDisplayName;
    final age = 24 + (name.hashCode.abs() % 10);
    final bio = (data.user.bio?.trim().isNotEmpty ?? false)
        ? data.user.bio!.trim()
        : "Balance and passion. Let’s explore the cosmos together ✨";

    // Matches the new palette-driven SyncHeroCard API.
    final hero = SyncHeroCard(
      mode: TruLuraMode.sync,
      name: name,
      age: age,
      percent: data.compatibility,
      headline:
          (data.compatibility >= 85) ? 'Highly Compatible' : 'Good Potential',
      bioLine: bio,
      distance: 'Located nearby • ${distanceMiles.round()} mi',
      tags: data.reasons,
      onPass: onPass,
      glowLabel: glowSent ? 'GLOW SENT' : 'GLOW',
      onGlow: glowSent ? null : onGlow,
      connectLabel: sparkSent ? 'SPARK SENT' : 'SPARK',
      onConnect: sparkSent ? null : onSpark,
      onHelp: () => _openCompatibility(context),
      onTapCompatibility: () => _openCompatibility(context),
      onTapProfile: () => _openProfilePreview(context),
    );

    return hero;
  }

  void _openCompatibility(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Compatibility',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900))),
                    IconButton(
                        onPressed: () => context.pop(),
                        icon: const TruLuraIcon(
                            glyph: TruLuraGlyph.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 6),
                if (data.suggestion?.report.layers.isNotEmpty ?? false) ...[
                  Text(
                    'Layered compatibility (not a single score):',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  ...data.suggestion!.report.layers.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: cs.outline.withValues(alpha: 0.14)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient:
                                      TruLuraTokens.auraGradient(opacity: 0.95),
                                ),
                                child: Text('${l.score}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(l.note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                height: 1.35,
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.72))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ] else ...[
                  Text(
                    'Compatibility is a calm signal — not a verdict. In MVP it’s derived from shared intent + vibe tags, and we’ll refine it with real data over time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurface.withValues(alpha: 0.74)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProfilePreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(data.user.publicDisplayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900))),
                    IconButton(
                        onPressed: () => context.pop(),
                        icon: const TruLuraIcon(
                            glyph: TruLuraGlyph.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 6),
                if (data.user.publicUsername != null) ...[
                  Text('@${data.user.publicUsername}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                ],
                Text(
                    (data.user.bio ??
                            "Balance and passion. Let’s explore the cosmos together ✨")
                        .trim(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.45)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Energy saved')));
                          context.pop();
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: sparkSent
                            ? null
                            : () {
                                onSpark();
                                context.pop();
                              },
                        child: Text(sparkSent ? 'Spark sent' : 'Spark'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SyncActivationCard extends StatelessWidget {
  final bool enabled;
  final bool paused;
  final TruMatchPurpose purpose;
  final bool lowEnergyMode;
  final int activeMatches;
  final int activeLimit;
  final VoidCallback onActivate;
  final ValueChanged<bool> onTogglePause;
  final ValueChanged<bool> onToggleLowEnergy;

  const _SyncActivationCard({
    required this.enabled,
    required this.paused,
    required this.purpose,
    required this.lowEnergyMode,
    required this.activeMatches,
    required this.activeLimit,
    required this.onActivate,
    required this.onTogglePause,
    required this.onToggleLowEnergy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;

    return TruLuraGlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TruLuraIcon(glyph: TruLuraGlyph.sync, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Compatibility Field',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: enabled
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                      : cs.surface.withValues(alpha: 0.45),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                  boxShadow: (!soft && enabled)
                      ? TruLuraEffects.softGlow(
                          TruLuraBrandColors.nebulaMagenta,
                          intensity: 0.35 * app.glowScale)
                      : [],
                ),
                child: Text(enabled ? 'ON' : 'OFF',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            enabled
                ? 'Resonance live - ${purpose.label} - pacing $activeMatches/$activeLimit'
                : 'Activate when you want Sync to surface emotionally aligned drops.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72), height: 1.35),
          ),
          const SizedBox(height: 9),
          if (!enabled)
            TruLuraPrimaryButton(
              onPressed: onActivate,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Activate Sync'),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: cs.outline.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.battery_saver_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.82)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('Gentle pacing',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w900))),
                        TruToggle(
                            value: lowEnergyMode, onChanged: onToggleLowEnergy),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: cs.outline.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pause_circle_filled_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.82)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('Pause field',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w900))),
                        TruToggle(value: paused, onChanged: onTogglePause),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    return InkWell(
      onTap: onTap,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surface.withValues(alpha: 0.70),
          border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
          boxShadow: soft
              ? []
              : TruLuraEffects.softGlow(TruLuraBrandColors.nebulaMagenta,
                  intensity: 0.55 * app.glowScale),
        ),
        child: TruLuraIcon(
            glyph: TruLuraGlyph.filter,
            size: 20,
            active: true,
            color: cs.onSurface),
      ),
    );
  }
}

class _SyncSkeleton extends StatelessWidget {
  const _SyncSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TruShimmer(
          child: TruLuraGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                TruSkeletonCircle(size: 74),
                SizedBox(height: 14),
                TruSkeletonBox(width: 190, height: 16, radius: 10),
                SizedBox(height: 8),
                TruSkeletonBox(width: 150, height: 12, radius: 10),
                SizedBox(height: 14),
                TruSkeletonBox(width: double.infinity, height: 42, radius: 18),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: TruSkeletonBox(
                            width: double.infinity, height: 40, radius: 16)),
                    SizedBox(width: 12),
                    Expanded(
                        child: TruSkeletonBox(
                            width: double.infinity, height: 40, radius: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TruShimmer(
          child: TruLuraGlassCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                TruSkeletonBox(width: 150, height: 14, radius: 10),
                SizedBox(height: 12),
                TruSkeletonBox(width: double.infinity, height: 42, radius: 16),
                SizedBox(height: 12),
                TruSkeletonBox(width: double.infinity, height: 12, radius: 10),
                SizedBox(height: 10),
                TruSkeletonBox(width: double.infinity, height: 78, radius: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FullSyncToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _FullSyncToggle(
      {required this.value, required this.onChanged, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        boxShadow: (!soft && value)
            ? TruLuraEffects.softGlow(TruLuraBrandColors.nebulaMagenta,
                intensity: 0.55 * app.glowScale)
            : [],
      ),
      child: Row(
        children: [
          TruLuraIcon(
              glyph: TruLuraGlyph.sync,
              size: 18,
              active: value,
              color: cs.onSurface.withValues(alpha: value ? 0.95 : 0.72)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Resonance',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 1),
                Text(
                  value
                      ? 'Deeper compatibility, intent, and pacing signals.'
                      : 'Light alignment signals with softer discovery.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.35),
                ),
              ],
            ),
          ),
          TruToggle(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _SyncCardData {
  final User user;
  final int compatibility;
  final List<String> reasons;
  final TruSyncSuggestion? suggestion;

  const _SyncCardData(
      {required this.user,
      required this.compatibility,
      required this.reasons,
      this.suggestion});
}

class _SparkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SparkButton({required this.label, required this.onTap});

  @override
  State<_SparkButton> createState() => _SparkButtonState();
}

class _SparkButtonState extends State<_SparkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    await _burst.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;

    const a = Color(0xFF7C3BFF);
    const b = Color(0xFFFF5FA8);

    return Expanded(
      child: InkWell(
        onTap: _handleTap,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: AnimatedBuilder(
          animation: _burst,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_burst.value);
            final particleOpacity = (1 - t).clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Subtle particle burst (purple) + micro rose shimmer.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: soft ? 0.0 : particleOpacity,
                      child:
                          CustomPaint(painter: _SparkBurstPainter(progress: t)),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [a, b]),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    boxShadow: soft
                        ? []
                        : [
                            BoxShadow(
                                color: const Color.fromRGBO(180, 90, 255, 1)
                                    .withValues(alpha: 0.35),
                                blurRadius: 25,
                                offset: Offset.zero),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TruLuraIcon(
                          glyph: TruLuraGlyph.sync,
                          size: 18,
                          active: true,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      Text(widget.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SparkBurstPainter extends CustomPainter {
  final double progress;

  _SparkBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final p = progress.clamp(0.0, 1.0);
    final spread = 20 + 34 * p;

    final purple = Paint()
      ..color = const Color(0xFF8B4DFF).withValues(alpha: 0.28 * (1 - p));
    final rose = Paint()
      ..color = const Color(0xFFFF5FA8).withValues(alpha: 0.16 * (1 - p));

    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      final d = spread * (0.55 + (i.isEven ? 0.35 : 0.18));
      final o = Offset(math.cos(a) * d, math.sin(a) * d);
      canvas.drawCircle(center + o, 1.6 + 1.4 * (1 - p), purple);
    }

    // Tiny rose shimmer
    canvas.drawCircle(center + Offset(spread * 0.2, -spread * 0.15),
        2.0 + 2.0 * (1 - p), rose);
  }

  @override
  bool shouldRepaint(covariant _SparkBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SyncFiltersSheet extends StatelessWidget {
  final bool fullSyncMode;
  final TruMatchPurpose purpose;
  final bool verifiedOnly;
  final RangeValues age;
  final double distance;
  final bool lowEnergy;
  final bool paused;
  final int activeLimit;
  final bool backgroundVisibility;
  final ValueChanged<_SyncFiltersState> onChanged;

  const _SyncFiltersSheet({
    required this.fullSyncMode,
    required this.purpose,
    required this.verifiedOnly,
    required this.age,
    required this.distance,
    required this.lowEnergy,
    required this.paused,
    required this.activeLimit,
    required this.backgroundVisibility,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var state = _SyncFiltersState(
      fullSyncMode: fullSyncMode,
      purpose: purpose,
      verifiedOnly: verifiedOnly,
      age: age,
      distance: distance,
      lowEnergy: lowEnergy,
      paused: paused,
      activeLimit: activeLimit,
      backgroundVisibility: backgroundVisibility,
    );

    return StatefulBuilder(
      builder: (context, setModalState) {
        void update(_SyncFiltersState next) {
          state = next;
          setModalState(() {});
          onChanged(next);
        }

        final media = MediaQuery.of(context);
        final bottomNavGap = 82.0 + media.padding.bottom;
        final maxSheetHeight =
            (media.size.height - bottomNavGap - 24).clamp(340.0, 620.0);

        return Padding(
          padding:
              EdgeInsets.only(bottom: media.viewInsets.bottom + bottomNavGap),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: 680, maxHeight: maxSheetHeight),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                ),
                child: SafeArea(
                  top: false,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.04, 0.93, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text('Tune Compatibility Field',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w900))),
                            IconButton(
                                onPressed: () => context.pop(),
                                icon: const TruLuraIcon(
                                    glyph: TruLuraGlyph.close, size: 20)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _SheetGroup(
                          title: 'Intent',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _IntentChip(
                                  label: 'Romance',
                                  selected:
                                      state.purpose == TruMatchPurpose.dating,
                                  onTap: () => update(state.copyWith(
                                      purpose: TruMatchPurpose.dating))),
                              _IntentChip(
                                  label: 'Committed',
                                  selected:
                                      state.purpose == TruMatchPurpose.serious,
                                  onTap: () => update(state.copyWith(
                                      purpose: TruMatchPurpose.serious))),
                              _IntentChip(
                                  label: 'Exploring',
                                  selected: state.purpose ==
                                      TruMatchPurpose.exploring,
                                  onTap: () => update(state.copyWith(
                                      purpose: TruMatchPurpose.exploring))),
                              _IntentChip(
                                  label: 'Companionship',
                                  selected: state.purpose ==
                                      TruMatchPurpose.companionship,
                                  onTap: () => update(state.copyWith(
                                      purpose: TruMatchPurpose.companionship))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SheetGroup(
                          title: 'Energy Radius',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${state.distance.round()} miles',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w900)),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                ),
                                child: Slider(
                                  value: state.distance,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  onChanged: (v) =>
                                      update(state.copyWith(distance: v)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SheetGroup(
                          title: 'Life Stage Range',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${state.age.start.round()}–${state.age.end.round()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w900)),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                ),
                                child: RangeSlider(
                                  values: state.age,
                                  min: 18,
                                  max: 60,
                                  divisions: 42,
                                  onChanged: (v) =>
                                      update(state.copyWith(age: v)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _SheetToggleRow(
                          value: state.verifiedOnly,
                          onChanged: (v) =>
                              update(state.copyWith(verifiedOnly: v)),
                          title: 'Verified only',
                          subtitle:
                              'Keep Soft Spark signals inside more trusted profiles.',
                        ),
                        const SizedBox(height: 10),
                        _SheetGroup(
                          title: 'Pacing',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SheetToggleRow(
                                value: state.lowEnergy,
                                onChanged: (v) =>
                                    update(state.copyWith(lowEnergy: v)),
                                title: 'Gentle pacing',
                                subtitle:
                                    'Smaller resonance drops and softer prompts.',
                              ),
                              _SheetToggleRow(
                                value: state.paused,
                                onChanged: (v) =>
                                    update(state.copyWith(paused: v)),
                                title: 'Pause compatibility field',
                                subtitle:
                                    'Stop new resonance drops without losing existing signals.',
                              ),
                              const SizedBox(height: 4),
                              Text('Active rhythm limit: ${state.activeLimit}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w900)),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                ),
                                child: Slider(
                                  value: state.activeLimit.toDouble(),
                                  min: 1,
                                  max: 8,
                                  divisions: 7,
                                  label: '${state.activeLimit}',
                                  onChanged: (v) => update(
                                      state.copyWith(activeLimit: v.round())),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SheetGroup(
                          title: 'Trust & safety',
                          child: _SheetToggleRow(
                            value: state.backgroundVisibility,
                            onChanged: (v) =>
                                update(state.copyWith(backgroundVisibility: v)),
                            title: 'Background visibility (optional)',
                            subtitle:
                                'Show extra context to deeper alignments. Always optional.',
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetGroup extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetGroup({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        child
      ]),
    );
  }
}

class _SheetToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const _SheetToggleRow({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TruToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _IntentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IntentChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final accentA = TruLuraBrandColors.nebulaMagenta;
    final accentB = TruLuraBrandColors.nebulaViolet;

    return InkWell(
      onTap: onTap,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: AnimatedContainer(
        duration: app.motionDuration,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentA, accentB])
              : null,
          color: selected ? null : cs.surface.withValues(alpha: 0.55),
          border: Border.all(
              color: cs.outline.withValues(alpha: selected ? 0.18 : 0.14)),
          boxShadow: (!soft && selected)
              ? TruLuraEffects.multiAuraGlow(accentA, accentB,
                  intensity: 0.85 * app.glowScale)
              : [],
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : cs.onSurface,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SyncFiltersState {
  final bool fullSyncMode;
  final TruMatchPurpose purpose;
  final bool verifiedOnly;
  final RangeValues age;
  final double distance;
  final bool lowEnergy;
  final bool paused;
  final int activeLimit;
  final bool backgroundVisibility;

  _SyncFiltersState({
    required this.fullSyncMode,
    required this.purpose,
    required this.verifiedOnly,
    required this.age,
    required this.distance,
    required this.lowEnergy,
    required this.paused,
    required this.activeLimit,
    required this.backgroundVisibility,
  });

  _SyncFiltersState copyWith({
    bool? fullSyncMode,
    TruMatchPurpose? purpose,
    bool? verifiedOnly,
    RangeValues? age,
    double? distance,
    bool? lowEnergy,
    bool? paused,
    int? activeLimit,
    bool? backgroundVisibility,
  }) {
    return _SyncFiltersState(
      fullSyncMode: fullSyncMode ?? this.fullSyncMode,
      purpose: purpose ?? this.purpose,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      age: age ?? this.age,
      distance: distance ?? this.distance,
      lowEnergy: lowEnergy ?? this.lowEnergy,
      paused: paused ?? this.paused,
      activeLimit: activeLimit ?? this.activeLimit,
      backgroundVisibility: backgroundVisibility ?? this.backgroundVisibility,
    );
  }
}
