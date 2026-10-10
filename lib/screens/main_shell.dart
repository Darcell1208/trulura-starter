import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (!mounted || GoRouterState.of(context).uri.toString() != route) return;
      // Consume the one-time request so refresh does not reopen the drawer.
      final uri = Uri.parse(route);
      final query = Map<String, String>.from(uri.queryParameters)
        ..remove(TruNavigation.openMenuParam)
        ..remove('menuPulse');
      context.replace(uri.replace(queryParameters: query).toString());
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

    final homeHeader = GoRouterState.of(context).uri.path == AppRoutes.home;
    final wideHeader = homeHeader && MediaQuery.sizeOf(context).width >= 900;
    final activeMode = modeForNavIndex(currentIndex);
    final activeTone = toneForNavIndex(currentIndex);

    return Scaffold(
      key: _scaffoldKey,
      // Reserve the navigation bar's actual height on every main tab.
      extendBody: false,
      drawer: const TruLuraSideDrawer(),
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: homeHeader ? (wideHeader ? 108 : 78) : 58,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: MediaQuery.sizeOf(context).width >= 1100 &&
                    GoRouterState.of(context).uri.path == AppRoutes.home &&
                    (GoRouterState.of(context).uri.queryParameters['tab'] ?? 'aura') == 'aura'
                ? (app.homeSidebarVisible ? 'Close sidebar' : 'Open sidebar')
                : 'Open menu',
            onPressed: () {
              if (MediaQuery.sizeOf(context).width >= 1100 &&
                  GoRouterState.of(context).uri.path == AppRoutes.home &&
                  (GoRouterState.of(context).uri.queryParameters['tab'] ?? 'aura') == 'aura') {
                app.toggleHomeSidebar();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
            icon: const TruLuraIcon(glyph: TruLuraGlyph.menu, size: 22),
          ),
        ),
        title: homeHeader
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                _CinematicTopTitle(large: wideHeader),
                const SizedBox(height: 3),
                Text('CONNECT · FEEL · GROW · BELONG',
                    style: TextStyle(fontSize: wideHeader ? 10 : 7,
                        letterSpacing: wideHeader ? 3 : 1.4,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])
            : const _CinematicTopTitle(),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Appearance and Soft Mode',
            icon: TruLuraIcon(
              glyph: TruLuraGlyph.moon,
              size: 18,
              active: app.softModeEnabled,
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
            onSelected: (value) {
              final settings = context.read<AppProvider>();
              if (value == 'soft') {
                settings.setSoftModeEnabled(!settings.softModeEnabled);
              } else {
                settings.setAppearanceMode(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                enabled: false,
                child: Text('Appearance'),
              ),
              for (final entry in const {
                'trulura': 'TruLura',
                'light': 'Light',
                'dark': 'Dark',
                'neutral': 'Neutral',
              }.entries)
                CheckedPopupMenuItem<String>(
                  value: entry.key,
                  checked: app.appearanceMode == entry.key,
                  child: Text(entry.value),
                ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<String>(
                value: 'soft',
                checked: app.softModeEnabled,
                child: const Text('Soft Mode · Reduce glow'),
              ),
            ],
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
        flexibleSpace: homeHeader && app.appearanceMode == 'trulura' ? Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/trulura_home_atmosphere.png'),
              fit: BoxFit.cover, alignment: Alignment(0, -0.8)),
          ),
          child: const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x22050913), Color(0xCC050913)]))),
        ) : Padding(
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
                if (app.appearanceMode == 'trulura')
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
  final bool large;
  const _CinematicTopTitle({this.large = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TruLura',
      image: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: large ? 226 : 158,
            height: large ? 73 : 54,
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                top: 1,
                right: large ? 40 : 25,
                width: large ? 62 : 48,
                height: large ? 20 : 16,
                child: CustomPaint(painter: _BrandInfinityPainter()),
              ),
              Positioned(
                bottom: 0,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.light
                        ? const [Color(0xFF39234E), Color(0xFF68436F), Color(0xFF39234E)]
                        : const [Color(0xFFFFDDBA), Color(0xFFF1C6F5), Color(0xFFFFDEB9)],
                  ).createShader(bounds),
                  child: Text('TruLura',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: large ? 56 : 39,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      )),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The reference wordmark's infinity accent, drawn crisply at header size.
class _BrandInfinityPainter extends CustomPainter {
  const _BrandInfinityPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..cubicTo(size.width * .27, -size.height * .12, 1, 0, 1, size.height / 2)
      ..cubicTo(1, size.height, size.width * .27, size.height * 1.12,
          size.width / 2, size.height / 2)
      ..cubicTo(size.width * .73, -size.height * .12, size.width - 1, 0,
          size.width - 1, size.height / 2)
      ..cubicTo(size.width - 1, size.height, size.width * .73,
          size.height * 1.12, size.width / 2, size.height / 2);
    final shader = const LinearGradient(
            colors: [Color(0xFF85CBFF), Color(0xFFD4A4FA), Color(0xFFFFC38A)])
        .createShader(Offset.zero & size);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _BrandInfinityPainter oldDelegate) => false;
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
