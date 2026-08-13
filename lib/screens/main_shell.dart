import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_bottom_nav.dart';
import 'package:trulura/widgets/trulura_side_drawer.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_brand_logo.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';

class ExploreHubScreen extends StatelessWidget {
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        Text('Explore',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(letterSpacing: -0.6)),
        const SizedBox(height: 10),
        Text(
          'Worlds beyond me: creators, live spaces, events, and communities to discover.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.72), height: 1.45),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const TruLuraIcon(glyph: TruLuraGlyph.tv),
            title: const Text('TruTV'),
            subtitle: const Text('Short-form + long-form creator drops.'),
            trailing: const TruLuraIcon(glyph: TruLuraGlyph.chevronRight),
            onTap: () =>
                TruNavigation.pushWithReturnTo(context, '/p?title=TruTV'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const TruLuraIcon(glyph: TruLuraGlyph.video),
            title: const Text('Live'),
            subtitle: const Text('Join sessions or start a basic Live.'),
            trailing: const TruLuraIcon(glyph: TruLuraGlyph.chevronRight),
            onTap: () =>
                TruNavigation.pushWithReturnTo(context, AppRoutes.live),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _lastOpenedMenuRoute;
  String? _lastAuraRestoreRoute;

  void _openMenuIfRequested() {
    final route = GoRouterState.of(context).uri.toString();
    final shouldOpen = GoRouterState.of(context)
            .uri
            .queryParameters[TruNavigation.openMenuParam] ==
        '1';
    if (!shouldOpen || _lastOpenedMenuRoute == route) return;
    _lastOpenedMenuRoute = route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scaffoldKey.currentState?.openDrawer();
    });
  }

  void _restoreAuraIfRequested() {
    final route = GoRouterState.of(context).uri.toString();
    final shouldRestore = GoRouterState.of(context)
            .uri
            .queryParameters[TruNavigation.restoreAuraParam] ==
        '1';
    if (!shouldRestore || _lastAuraRestoreRoute == route) return;
    _lastAuraRestoreRoute = route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().setTab('aura');
      context.read<TruLuraModeController>().setMode(TruLuraMode.aura);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final app = context.watch<AppProvider>();
    final mode = context.watch<TruLuraModeController>();
    final currentIndex = widget.navigationShell.currentIndex.clamp(0, 3);
    _openMenuIfRequested();
    _restoreAuraIfRequested();

    // Keep provider state in sync for existing call sites that still rely on it.
    if (app.mainTabIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppProvider>().setMainTabIndex(currentIndex);
      });
    }

    TruLuraMode modeForHomeTab(String tab) {
      switch (tab) {
        case 'sync':
          return TruLuraMode.sync;
        case 'explore':
          return TruLuraMode.trending;
        case 'aura':
        default:
          return TruLuraMode.aura;
      }
    }

    TruLuraMode modeForNavIndex(int i) {
      switch (i) {
        case 1:
          return TruLuraMode.social;
        case 2:
          // Notifications should stay neutral; avoid pulling in Explore palette.
          return TruLuraMode.social;
        case 3:
          return TruLuraMode.social;
        default:
          return modeForHomeTab(context.watch<AppState>().currentTab);
      }
    }

    TruLuraModeTone toneForNavIndex(int i) {
      switch (i) {
        case 1:
          return TruLuraModeTone.messages;
        case 2:
          return TruLuraModeTone.notifications;
        case 3:
          return TruLuraModeTone.profile;
        default:
          switch (context.watch<AppState>().currentTab) {
            case 'sync':
              return TruLuraModeTone.sync;
            case 'explore':
              return TruLuraModeTone.explore;
            case 'aura':
            default:
              return TruLuraModeTone.aura;
          }
      }
    }

    final activeMode = modeForNavIndex(currentIndex);
    final activeTone = toneForNavIndex(currentIndex);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: const TruLuraSideDrawer(),
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 58,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const TruLuraIcon(glyph: TruLuraGlyph.menu, size: 22),
          ),
        ),
        title: const _CinematicTopTitle(),
        actions: [
          IconButton(
            onPressed: () => context.read<AppProvider>().setSoftModeEnabled(
                  !app.softModeEnabled,
                ),
            icon: TruLuraIcon(
              glyph: TruLuraGlyph.moon,
              size: 18,
              active: app.softModeEnabled,
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
            tooltip: app.softModeEnabled
                ? 'Turn off Soft Mode'
                : 'Turn on Soft Mode',
          ),
          IconButton(
            onPressed: () =>
                TruNavigation.pushWithReturnTo(context, '/p?title=Search'),
            icon: const TruLuraIcon(glyph: TruLuraGlyph.search, size: 22),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {
              widget.navigationShell.goBranch(3);
              mode.setMode(TruLuraMode.social);
            },
            icon: const TruLuraIcon(glyph: TruLuraGlyph.person, size: 22),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 6),
        ],
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: app.softModeEnabled
                    ? TruLuraSurfaces.glassBlurSoft
                    : TruLuraSurfaces.glassBlurStrong,
                sigmaY: app.softModeEnabled
                    ? TruLuraSurfaces.glassBlurSoft
                    : TruLuraSurfaces.glassBlurStrong,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surface.withValues(
                          alpha: brightness == Brightness.dark
                              ? TruLuraSurfaces.glassDarkA
                              : TruLuraSurfaces.glassLightA),
                      cs.surfaceContainerHighest.withValues(
                          alpha: brightness == Brightness.dark
                              ? TruLuraSurfaces.glassDarkB
                              : TruLuraSurfaces.glassLightB),
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(
                          alpha: app.softModeEnabled ? 0.10 : 0.085),
                      width: TruLuraSurfaces.hairline),
                ),
              ),
            ),
          ),
        ),
      ),
      body: TruLuraLayeredBackground(
        tone: activeTone,
        mode: activeMode,
        modeAccent:
            activeTone == TruLuraModeTone.sync ? const Color(0x40FF5AA0) : null,
        child: TweenAnimationBuilder<double>(
          key: ValueKey<String>(
            '${currentIndex}_${context.watch<AppState>().currentTab}',
          ),
          tween: Tween<double>(begin: 0, end: 1),
          duration: app.motionDuration + const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final slide = (1 - value) * 10;
            return Stack(
              children: [
                Positioned.fill(
                  child: _EnvironmentalShiftOverlay(
                    value: value,
                    tone: activeTone,
                    mode: activeMode,
                  ),
                ),
                Opacity(
                  opacity: 0.94 + value * 0.06,
                  child: Transform.translate(
                    offset: Offset(0, slide),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: TruLuraBottomNav(
        mode: activeMode,
        index: currentIndex,
        onTap: (i) {
          if (i == 0) {
            context.read<AppState>().setTab('aura');
            context.go(AppRoutes.homeTab('aura'));
          } else {
            widget.navigationShell.goBranch(i);
          }
          mode.setMode(modeForNavIndex(i));
        },
        onPost: () =>
            TruNavigation.pushWithReturnTo(context, AppRoutes.createPost),
      ),
    );
  }
}

class _CinematicTopTitle extends StatelessWidget {
  const _CinematicTopTitle();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: TruLuraBrandLogo(size: 30, radius: 12, neon: false),
    );
  }
}

class _EnvironmentalShiftOverlay extends StatelessWidget {
  final double value;
  final TruLuraModeTone tone;
  final TruLuraMode mode;

  const _EnvironmentalShiftOverlay({
    required this.value,
    required this.tone,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (toneA, toneB) = tone.resolve(cs);
    final p = kTruLuraPalettes[mode]!;
    final settling = (1 - value).clamp(0.0, 1.0);
    final accentA = Color.alphaBlend(toneA.withValues(alpha: 0.5), p.glowA);
    final accentB = Color.alphaBlend(toneB.withValues(alpha: 0.5), p.glowB);
    return IgnorePointer(
      child: Opacity(
        opacity: settling,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: switch (tone) {
                TruLuraModeTone.sync => const Alignment(0.45, -0.08),
                TruLuraModeTone.explore => const Alignment(-0.28, -0.18),
                TruLuraModeTone.profile => const Alignment(0.0, -0.36),
                TruLuraModeTone.messages => const Alignment(-0.55, 0.12),
                TruLuraModeTone.notifications => const Alignment(0.58, -0.22),
                TruLuraModeTone.aura => const Alignment(-0.22, -0.30),
              },
              radius: 1.1,
              colors: [
                accentA.withValues(alpha: 0.24),
                accentB.withValues(alpha: 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
