import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/aura_state.dart' as aura_state;
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_brand_logo.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_side_drawer.dart';

class TruCompanionScreen extends StatefulWidget {
  const TruCompanionScreen({super.key});

  @override
  State<TruCompanionScreen> createState() => _TruCompanionScreenState();
}

class _TruCompanionScreenState extends State<TruCompanionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();

  bool _holdingPresence = false;
  String _activeSpace = 'Reflect';
  final List<String> _reflectionHistory = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectSpace(String space) {
    final prompt = switch (space) {
      'Reflect' => 'I want to reflect on what I am feeling.',
      'Vent' => 'I need presence while I let something out.',
      'Process' => 'Help me process what happened with clarity.',
      'Dream' => 'I want to explore a dream, hope, or future version of me.',
      'Heal' => 'Help me ground and move gently through this.',
      'Plan' => 'Help me turn this feeling into one clear intention.',
      'Grow' => 'Help me notice the growth taking shape in this season.',
      'Connect' => 'Help me understand how to reach out with care.',
      'Journal' => 'Hold this moment with me as I put it into words.',
      'Ground' => 'Help me return to my body, breath, and the present moment.',
      _ => 'I want to begin with presence.',
    };

    setState(() {
      _activeSpace = space;
      _controller.text = prompt;
      _controller.selection = TextSelection.collapsed(offset: prompt.length);
    });
  }

  void _holdReflection(Color surface) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _reflectionHistory.insert(0, '$_activeSpace: $text');
      _holdingPresence = true;
    });

    unawaited(Future<void>.delayed(const Duration(milliseconds: 820), () {
      if (!mounted) return;
      setState(() => _holdingPresence = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presence held in $_activeSpace.'),
          backgroundColor: surface.withValues(alpha: 0.94),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final aura = context.watch<aura_state.AuraStateController>().state;
    final presence = app.emotionalPresenceState;
    final user = app.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const TruLuraSideDrawer(activeKey: 'ai'),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        modeAccent: aura.auraColor.withValues(alpha: 0.22),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                _TopBar(
                  onBack: () => TruNavigation.goBackOrReturn(context),
                  onClose: () => TruNavigation.closeModule(context),
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onSearch: () => TruNavigation.pushWithInheritedReturnTo(
                    context,
                    '/p?title=${Uri.encodeComponent('Search')}',
                  ),
                  onProfile: () => TruNavigation.pushWithInheritedReturnTo(
                    context,
                    AppRoutes.profile,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _CompanionHeader(
                          activeSpace: _activeSpace,
                          presenceLabel: presence.label,
                          displayName: user?.publicDisplayName ?? 'you',
                          aura: aura,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      if (ui == TruUiState.action)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: TruInlineBanner(
                              glyph: TruLuraGlyph.spark,
                              text:
                                  'Reflection held - your companion is staying with the next layer.',
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final core = _PresenceSanctuary(
                              aura: aura,
                              activeSpace: _activeSpace,
                              presenceLabel: presence.label,
                              reflectionCount: _reflectionHistory.length,
                              displayName: user?.publicDisplayName ?? 'you',
                              onSelectSpace: _selectSpace,
                            );
                            final stream = _AuraIntegrationPanel(
                              aura: aura,
                              presenceLabel: presence.label,
                              recentActivity: _recentActivityFor(app),
                              reflectionCount: _reflectionHistory.length,
                              mutedTopics: app.feedMutedTopics,
                              history: _reflectionHistory,
                              onSelectSpace: _selectSpace,
                            );
                            if (constraints.maxWidth < 860) {
                              return Column(
                                children: [
                                  core,
                                  const SizedBox(height: 18),
                                  stream,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: core),
                                const SizedBox(width: 28),
                                Expanded(flex: 3, child: stream),
                              ],
                            );
                          },
                        ),
                      ),
                      if (ui == TruUiState.loading || _holdingPresence) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        const SliverToBoxAdapter(child: _PresenceShimmer()),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _ConversationSpaces(
                          activeSpace: _activeSpace,
                          onSelect: _selectSpace,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 72)),
                    ],
                  ),
                ),
                _ComposerDock(
                  activeSpace: _activeSpace,
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  onSend: _controller.text.trim().isEmpty
                      ? null
                      : () => _holdReflection(cs.surface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _recentActivityFor(AppProvider app) {
    final user = app.currentUser;
    final pieces = <String>[
      if ((user?.moodTags ?? const <String>[]).isNotEmpty)
        '${user!.moodTags.take(2).join(' + ')} mood signal',
      if ((user?.intents ?? const <String>[]).isNotEmpty)
        '${user!.intents.first} intention',
      if (app.isLowEnergyContext) 'low-energy pacing',
      if (app.softModeEnabled) 'soft mode atmosphere',
    ];
    return pieces.isEmpty ? 'quiet aura baseline' : pieces.take(2).join(' / ');
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onProfile;

  const _TopBar({
    required this.onBack,
    required this.onClose,
    required this.onMenu,
    required this.onSearch,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _RoundIconButton(icon: TruLuraGlyph.back, onTap: onBack),
        const SizedBox(width: 10),
        InkWell(
          onTap: onMenu,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Row(
            children: [
              const TruLuraBrandLogo(size: 34, radius: 12),
              const SizedBox(width: 10),
              Text(
                'TruCompanion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _RoundIconButton(icon: TruLuraGlyph.close, onTap: onClose),
        const SizedBox(width: 10),
        _RoundIconButton(icon: TruLuraGlyph.search, onTap: onSearch),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: TruLuraGlyph.person,
          onTap: onProfile,
          tint: cs.primary,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final TruLuraGlyph icon;
  final VoidCallback onTap;
  final Color? tint;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 999,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: TruLuraIcon(
              glyph: icon,
              size: 20,
              active: true,
              color: (tint ?? cs.onSurface).withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionHeader extends StatelessWidget {
  final String activeSpace;
  final String presenceLabel;
  final String displayName;
  final aura_state.AuraState aura;

  const _CompanionHeader({
    required this.activeSpace,
    required this.presenceLabel,
    required this.displayName,
    required this.aura,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'PRESENCE',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 2.4,
                fontWeight: FontWeight.w900,
                color: cs.onSurface.withValues(alpha: 0.70),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          displayName == 'you'
              ? 'Welcome back.'
              : 'Welcome back, ${displayName.split(' ').first}.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _acknowledgement(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72),
                height: 1.42,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'I am here with you in $activeSpace.',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: aura.auraColor,
                fontWeight: FontWeight.w900,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _acknowledgement() {
    final energy = switch (aura.energyLevel) {
      aura_state.EnergyLevel.low => 'quieter than usual',
      aura_state.EnergyLevel.medium => 'steady',
      aura_state.EnergyLevel.high => 'bright and active',
    };
    final movement = switch (aura.mood) {
      aura_state.Mood.reflective => 'Reflection may be asking for room.',
      aura_state.Mood.flirty => 'Connection feels close to the surface.',
      aura_state.Mood.calm => 'There is space to breathe before choosing.',
      aura_state.Mood.social => 'Your energy seems ready to move outward.',
      aura_state.Mood.healing => 'We can move gently and stay grounded.',
    };
    return 'Your energy feels $energy today. $movement';
  }
}

class _PresenceSanctuary extends StatefulWidget {
  final aura_state.AuraState aura;
  final String activeSpace;
  final String presenceLabel;
  final int reflectionCount;
  final String displayName;
  final ValueChanged<String> onSelectSpace;

  const _PresenceSanctuary({
    required this.aura,
    required this.activeSpace,
    required this.presenceLabel,
    required this.reflectionCount,
    required this.displayName,
    required this.onSelectSpace,
  });

  @override
  State<_PresenceSanctuary> createState() => _PresenceSanctuaryState();
}

class _PresenceSanctuaryState extends State<_PresenceSanctuary>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).width < 860 ? 420 : 560,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    width: 420,
                    height: 420,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.aura.auraColor.withValues(alpha: 0.18),
                            TruLuraTokens.auraViolet.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CompanionEnergyPainter(
                        progress: _pulse.value,
                        aura: widget.aura.auraColor,
                        activeSpace: widget.activeSpace,
                      ),
                    ),
                  ),
                  _AuraCore(
                    aura: widget.aura,
                    progress: _pulse.value,
                    activeSpace: widget.activeSpace,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          widget.displayName == 'you'
              ? 'I am here with you.'
              : '${widget.displayName}, I am here with you.',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Your aura state, emotional rhythm, recent reflections, and intentions are present with us in ${widget.activeSpace}.',
          style: t.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.72),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AuraCore extends StatelessWidget {
  final aura_state.AuraState aura;
  final double progress;
  final String activeSpace;

  const _AuraCore({
    required this.aura,
    required this.progress,
    required this.activeSpace,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final breath = 0.5 + math.sin(progress * math.pi * 2) * 0.5;
    return Container(
      width: 220 + breath * 16,
      height: 220 + breath * 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.88),
            aura.auraColor.withValues(alpha: 0.58),
            TruLuraTokens.auraViolet.withValues(alpha: 0.20),
            Colors.transparent,
          ],
          stops: const [0.0, 0.30, 0.66, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: TruLuraEffects.multiAuraGlow(
          aura.auraColor,
          TruLuraTokens.auraViolet,
          intensity: 0.72,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TruLuraIcon(
              glyph: TruLuraGlyph.aura,
              size: 42,
              active: true,
              color: Colors.white,
            ),
            const SizedBox(height: 7),
            Text(
              activeSpace,
              style: t.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionEnergyPainter extends CustomPainter {
  final double progress;
  final Color aura;
  final String activeSpace;

  const _CompanionEnergyPainter({
    required this.progress,
    required this.aura,
    required this.activeSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final spaceBias = activeSpace.length % 7;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < 5; i++) {
      final p = (progress + i * 0.13) % 1.0;
      final radius = 50 + i * 18 + math.sin(p * math.pi * 2) * 5;
      ring.color = Color.lerp(aura, TruLuraBrandColors.glowGold, i / 5)!
          .withValues(alpha: 0.22 - i * 0.025);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * (2.35 + i * 0.05),
          height: radius * (1.42 + (spaceBias * 0.018)),
        ),
        ring,
      );
    }

    final dot = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 18; i++) {
      final angle = progress * math.pi * 2 + i * 0.72;
      final distance = 82 + (i % 4) * 18;
      final wobble = math.sin(progress * math.pi * 2 + i) * 9;
      final point = center +
          Offset(
            math.cos(angle) * (distance + wobble),
            math.sin(angle * 0.86) * (distance * 0.58),
          );
      dot.color = (i.isEven ? aura : TruLuraTokens.auraCyan)
          .withValues(alpha: 0.18 + (i % 3) * 0.025);
      canvas.drawCircle(point, 1.5 + (i % 3) * 0.6, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _CompanionEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.aura != aura ||
        oldDelegate.activeSpace != activeSpace;
  }
}

class _AuraIntegrationPanel extends StatelessWidget {
  final aura_state.AuraState aura;
  final String presenceLabel;
  final String recentActivity;
  final int reflectionCount;
  final List<String> mutedTopics;
  final List<String> history;
  final ValueChanged<String> onSelectSpace;

  const _AuraIntegrationPanel({
    required this.aura,
    required this.presenceLabel,
    required this.recentActivity,
    required this.reflectionCount,
    required this.mutedTopics,
    required this.history,
    required this.onSelectSpace,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        'Thought',
        _thought(),
        TruLuraGlyph.aura,
      ),
      (
        'Insight',
        '$recentActivity. Your emotional rhythm feels ${_energyLabel(aura)}, with $presenceLabel presence.',
        TruLuraGlyph.insights,
      ),
      (
        'Reflection',
        history.isEmpty
            ? 'Nothing needs to be solved before we begin.'
            : history.first,
        TruLuraGlyph.bookmark,
      ),
      (
        'Suggestion',
        _suggestion(),
        TruLuraGlyph.spark,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presence stream',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TruLuraTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < entries.length; i++) ...[
            InkWell(
              onTap: i == entries.length - 1
                  ? () => onSelectSpace(_suggestedSpace())
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TruLuraIcon(
                      glyph: entries[i].$3,
                      size: 19,
                      color: i.isEven
                          ? aura.auraColor
                          : TruLuraBrandColors.glowGold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entries[i].$1,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: TruLuraTokens.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            entries[i].$2,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: TruLuraTokens.textSecondary,
                                      height: 1.4,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != entries.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 31),
                color: aura.auraColor.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }

  String _thought() {
    if (reflectionCount > 0) {
      return 'I am still holding the shape of your latest reflection.';
    }
    return 'I am listening for what feels present beneath the surface.';
  }

  String _suggestedSpace() {
    return switch (aura.energyLevel) {
      aura_state.EnergyLevel.low => 'Ground',
      aura_state.EnergyLevel.medium => 'Reflect',
      aura_state.EnergyLevel.high => 'Grow',
    };
  }

  String _suggestion() {
    final space = _suggestedSpace();
    final boundary = mutedTopics.isEmpty
        ? 'Your usual pacing is open.'
        : 'Your boundaries are remembered.';
    return '$boundary We could enter $space together.';
  }

  String _energyLabel(aura_state.AuraState aura) => switch (aura.energyLevel) {
        aura_state.EnergyLevel.low => 'quiet',
        aura_state.EnergyLevel.medium => 'steady',
        aura_state.EnergyLevel.high => 'bright',
      };
}

class _ConversationSpaces extends StatelessWidget {
  final String activeSpace;
  final ValueChanged<String> onSelect;

  const _ConversationSpaces({
    required this.activeSpace,
    required this.onSelect,
  });

  static const List<_SpaceData> _spaces = [
    _SpaceData('Reflect', TruLuraGlyph.bookmark,
        'Name what is present without forcing an answer.'),
    _SpaceData('Vent', TruLuraGlyph.heartOutline,
        'Release pressure inside a private container.'),
    _SpaceData(
        'Process', TruLuraGlyph.insights, 'Find clarity around what happened.'),
    _SpaceData('Dream', TruLuraGlyph.moon,
        'Follow hope, symbols, and future self signals.'),
    _SpaceData('Heal', TruLuraGlyph.shield,
        'Ground gently and restore emotional rhythm.'),
    _SpaceData(
        'Plan', TruLuraGlyph.spark, 'Turn feeling into one clear intention.'),
    _SpaceData('Grow', TruLuraGlyph.star,
        'Notice emotional evolution and the next becoming.'),
    _SpaceData('Connect', TruLuraGlyph.groups,
        'Prepare a caring reach-out or repair note.'),
    _SpaceData('Journal', TruLuraGlyph.bookmark,
        'Hold a private moment in your reflection history.'),
    _SpaceData('Ground', TruLuraGlyph.aura,
        'Return to breath, body, and the present moment.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Companion spaces',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          primary: false,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < _spaces.length; index++) ...[
                _SpaceCard(
                  data: _spaces[index],
                  selected: activeSpace == _spaces[index].title,
                  onTap: () => onSelect(_spaces[index].title),
                ),
                if (index != _spaces.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SpaceData {
  final String title;
  final TruLuraGlyph glyph;
  final String subtitle;

  const _SpaceData(this.title, this.glyph, this.subtitle);
}

class _SpaceCard extends StatelessWidget {
  final _SpaceData data;
  final bool selected;
  final VoidCallback onTap;

  const _SpaceCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? TruLuraTokens.auraPink : TruLuraTokens.auraCyan;
    return InkResponse(
      onTap: onTap,
      radius: 42,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: selected ? 58 : 50,
            height: selected ? 58 : 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: selected ? 0.18 : 0.07),
              border: Border.all(
                color: accent.withValues(alpha: selected ? 0.48 : 0.16),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.24),
                        blurRadius: 24,
                        spreadRadius: -6,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: TruLuraIcon(
                glyph: data.glyph,
                size: selected ? 22 : 19,
                active: selected,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 74,
            child: Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? TruLuraTokens.textPrimary
                        : TruLuraTokens.textSecondary,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceShimmer extends StatelessWidget {
  const _PresenceShimmer();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: TruLuraGlassCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            TruSkeletonBox(width: 190, height: 14, radius: 10),
            SizedBox(height: 10),
            TruSkeletonBox(width: double.infinity, height: 12, radius: 10),
            SizedBox(height: 10),
            TruSkeletonBox(width: 250, height: 12, radius: 10),
          ],
        ),
      ),
    );
  }
}

class _ComposerDock extends StatelessWidget {
  final String activeSpace;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSend;

  const _ComposerDock({
    required this.activeSpace,
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onSend != null;
    return TruLuraGlassCard(
      radius: 999,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend?.call(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.92),
                  ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '$activeSpace with presence...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.52),
                    ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedOpacity(
            duration: context.watch<AppProvider>().motionDuration,
            opacity: enabled ? 1 : 0.5,
            child: InkWell(
              onTap: enabled ? onSend : null,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: enabled
                      ? TruLuraGradients.primaryButton
                      : LinearGradient(
                          colors: [cs.surfaceContainerHighest, cs.surface],
                        ),
                  boxShadow: enabled
                      ? TruLuraEffects.softGlow(
                          TruLuraBrandColors.neonPurple,
                          intensity: 0.35,
                        )
                      : const <BoxShadow>[],
                ),
                child: Center(
                  child: TruLuraIcon(
                    glyph: TruLuraGlyph.send,
                    size: 18,
                    active: true,
                    color: cs.onPrimary.withValues(alpha: 0.96),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
