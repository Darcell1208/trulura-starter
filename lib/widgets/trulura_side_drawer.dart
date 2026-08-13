import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/identity_service.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_ui_kit.dart';
import 'package:trulura/widgets/trulura_brand_logo.dart';

const Map<String, String> kTruLuraDestinationOwnership = {
  'Aura': 'My Emotional Universe',
  'Sync': 'My Resonance With Others',
  'Explore': 'Worlds Beyond Me',
  'Vent': 'Emotional Sanctuary',
  'Profile': 'Living Identity',
};

class TruLuraSideDrawer extends StatelessWidget {
  final String? activeKey;

  const TruLuraSideDrawer({super.key, this.activeKey});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final activeMode =
        app.currentUser?.activeIdentityMode ?? TruIdentityMode.social;
    final coreWorlds = <_DrawerDestination>[
      _DrawerDestination(
        icon: Icons.visibility,
        label: 'Aura',
        subtitle: kTruLuraDestinationOwnership['Aura'],
        active: activeKey == 'aura',
        onTap: () => _goTab(context, 0),
      ),
      _DrawerDestination(
        icon: Icons.all_inclusive,
        label: 'Sync',
        subtitle: kTruLuraDestinationOwnership['Sync'],
        active: activeKey == 'sync',
        onTap: () => _goTab(context, 1),
      ),
      _DrawerDestination(
        icon: Icons.explore,
        label: 'Explore',
        subtitle: kTruLuraDestinationOwnership['Explore'],
        active: activeKey == 'explore',
        onTap: () => _goTab(context, 2),
      ),
      _DrawerDestination(
        icon: Icons.shield,
        label: 'Vent',
        subtitle: kTruLuraDestinationOwnership['Vent'],
        active: activeKey == 'vent',
        onTap: () => _pushFromDrawer(context, AppRoutes.vent),
      ),
    ];
    final livingSystems = <_DrawerDestination>[
      _DrawerDestination(
        icon: Icons.map,
        label: 'TruJourney',
        subtitle: 'Life arc and growth path',
        active: activeKey == 'journey',
        onTap: () => _goPlaceholder(context, 'TruJourney'),
      ),
      _DrawerDestination(
        icon: Icons.videocam,
        label: 'TruTV',
        subtitle: 'Live rooms and stories',
        active: activeKey == 'live',
        onTap: () => _pushFromDrawer(context, AppRoutes.live),
      ),
      _DrawerDestination(
        icon: Icons.psychology_alt,
        label: 'TruStudio',
        subtitle: 'Create from your signal',
        active: activeKey == 'trustudio',
        onTap: () => _pushFromDrawer(context, AppRoutes.truStudio),
      ),
      _DrawerDestination(
        icon: Icons.psychology,
        label: 'TruCompanion',
        subtitle: 'Presence and reflection',
        active: activeKey == 'ai',
        onTap: () => _pushFromDrawer(context, AppRoutes.aiCompanionHub),
      ),
    ];
    final personalSpaces = <_DrawerDestination>[
      _DrawerDestination(
        icon: Icons.person,
        label: 'Profile',
        subtitle: kTruLuraDestinationOwnership['Profile'],
        active: activeKey == 'profile',
        onTap: () => _goTab(context, 5),
      ),
      _DrawerDestination(
        icon: Icons.settings,
        label: 'Experience Center',
        subtitle: 'Tune your TruLura world',
        active: activeKey == 'settings',
        onTap: () => _pushFromDrawer(context, AppRoutes.settings),
      ),
      _DrawerDestination(
        icon: Icons.lock,
        label: 'Safety Center',
        subtitle: 'Privacy, trust, and protection',
        active: activeKey == 'safety',
        onTap: () => _pushFromDrawer(context, AppRoutes.safetyCenter),
      ),
    ];

    // Keep the existing route wiring + tab switching logic, but update the
    // visual language to the TruLura kit (glass cards + cinematic background).

    final drawerWidth =
        (MediaQuery.of(context).size.width * 0.84).clamp(322.0, 430.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      child: TruLuraBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: soft ? 0.14 : 0.24),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TruLuraTokens.auraViolet
                          .withValues(alpha: soft ? 0.08 : 0.18),
                      TruLuraTokens.deepIndigo.withValues(alpha: 0.20),
                      TruLuraTokens.auraCyan
                          .withValues(alpha: soft ? 0.05 : 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -120,
              top: 90,
              width: 300,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        (soft ? TruLuraTokens.auraCyan : TruLuraTokens.auraPink)
                            .withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -90,
              bottom: 40,
              width: 240,
              height: 300,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        TruLuraBrandColors.glowGold.withValues(
                          alpha: soft ? 0.08 : 0.15,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                      stops: const [0.0, 0.22, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _DrawerLivingField(
                  accentA:
                      soft ? TruLuraTokens.auraCyan : TruLuraTokens.auraViolet,
                  accentB: TruLuraTokens.auraPink,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 16, 16),
                child: TruLuraGlassCard(
                  radius: 34,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  depth: true,
                  glow:
                      soft ? TruLuraTokens.auraCyan : TruLuraTokens.auraViolet,
                  tint: Colors.white.withValues(alpha: soft ? 0.06 : 0.045),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const TruLuraBrandLogo(size: 38, radius: 12),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TruLura',
                                    style: TextStyle(
                                        color: TruLuraKitPalette.text,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(soft ? 'Soft Mode' : 'Living Field',
                                    style: const TextStyle(
                                        color: TruLuraKitPalette.textDim,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.close,
                                  color: TruLuraKitPalette.text)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DrawerAtmosphereStatus(soft: soft),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: [
                                _DrawerIsland(
                                  title: 'CORE WORLDS',
                                  glow: soft
                                      ? TruLuraTokens.auraCyan
                                      : TruLuraTokens.auraViolet,
                                  children: [
                                    for (final item in coreWorlds)
                                      _KitDrawerItem(
                                        icon: item.icon,
                                        label: item.label,
                                        subtitle: item.subtitle,
                                        active: item.active,
                                        onTap: item.onTap,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                _ModeConstellation(
                                  activeMode: activeMode,
                                  onSelected: (mode) =>
                                      _selectMode(context, mode),
                                ),
                                const SizedBox(height: 13),
                                _DrawerIsland(
                                  title: 'LIVING SYSTEMS',
                                  glow: TruLuraBrandColors.glowGold,
                                  children: [
                                    for (final item in livingSystems)
                                      _KitDrawerItem(
                                        icon: item.icon,
                                        label: item.label,
                                        subtitle: item.subtitle,
                                        active: item.active,
                                        onTap: item.onTap,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                _DrawerIsland(
                                  title: 'PERSONAL',
                                  glow: TruLuraTokens.auraPink,
                                  children: [
                                    for (final item in personalSpaces)
                                      _KitDrawerItem(
                                        icon: item.icon,
                                        label: item.label,
                                        subtitle: item.subtitle,
                                        active: item.active,
                                        onTap: item.onTap,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTab(BuildContext context, int tabIndex) {
    final origin = TruNavigation.currentRoute(context);
    final String route = switch (tabIndex) {
      // Top tabs (inside Home)
      0 => AppRoutes.homeTab('aura'),
      1 => AppRoutes.homeTab('sync'),
      2 => AppRoutes.homeTab('explore'),
      // Bottom nav
      3 => AppRoutes.messages,
      4 => AppRoutes.notifications,
      5 => AppRoutes.profile,
      _ => AppRoutes.home,
    };
    final isMenuSurface = tabIndex >= 3;
    final target = isMenuSurface
        ? TruNavigation.routeWithMenuLayer(context, route, origin: origin)
        : route;
    final extra = isMenuSurface
        ? TruNavigation.withMenuLayer(context, origin: origin)
        : {'returnTo': origin};
    context.pop();
    context.go(target, extra: extra);
  }

  void _goPlaceholder(BuildContext context, String title) {
    final origin = TruNavigation.currentRoute(context);
    final route = Uri(
      path: AppRoutes.placeholder,
      queryParameters: {
        'title': title,
      },
    ).toString();
    final target =
        TruNavigation.routeWithMenuLayer(context, route, origin: origin);
    final extra = TruNavigation.withMenuLayer(context, origin: origin);
    context.pop();
    context.push(target, extra: extra);
  }

  void _pushFromDrawer(BuildContext context, String route) {
    final origin = TruNavigation.currentRoute(context);
    final target =
        TruNavigation.routeWithMenuLayer(context, route, origin: origin);
    final extra = TruNavigation.withMenuLayer(context, origin: origin);
    context.pop();
    context.push(target, extra: extra);
  }

  Future<void> _selectMode(
    BuildContext context,
    TruIdentityMode mode,
  ) async {
    await IdentityService().setActiveMode(mode);
    if (!context.mounted) return;
    context.pop();
    context.go(AppRoutes.profile);
  }
}

class _DrawerAtmosphereStatus extends StatelessWidget {
  final bool soft;

  const _DrawerAtmosphereStatus({required this.soft});

  @override
  Widget build(BuildContext context) {
    final accent = soft ? TruLuraTokens.auraCyan : TruLuraTokens.auraViolet;
    return TruLuraGlassCard(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      tint: accent.withValues(alpha: 0.055),
      glow: accent,
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.30),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Ecosystem status: field tuned',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: TruLuraKitPalette.textDim,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            soft ? 'calm' : 'alive',
            style: TextStyle(
              color: accent.withValues(alpha: 0.90),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerLivingField extends StatefulWidget {
  final Color accentA;
  final Color accentB;

  const _DrawerLivingField({
    required this.accentA,
    required this.accentB,
  });

  @override
  State<_DrawerLivingField> createState() => _DrawerLivingFieldState();
}

class _DrawerLivingFieldState extends State<_DrawerLivingField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
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
      builder: (context, _) => CustomPaint(
        painter: _DrawerDimensionFieldPainter(
          accentA: widget.accentA,
          accentB: widget.accentB,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _DrawerDimensionFieldPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final double progress;

  const _DrawerDimensionFieldPainter({
    required this.accentA,
    required this.accentB,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withValues(alpha: 0.045);
    for (var i = 0; i < 5; i++) {
      final y = size.height *
          (0.18 + i * 0.16 + math.sin(progress * math.pi * 2 + i) * 0.010);
      final path = Path()
        ..moveTo(-12, y)
        ..cubicTo(size.width * 0.26, y - 18, size.width * 0.58, y + 24,
            size.width + 18, y - 8);
      canvas.drawPath(path, line);
    }

    final dot = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 16; i++) {
      dot.color = (i.isEven ? accentA : accentB).withValues(alpha: 0.055);
      canvas.drawCircle(
        Offset(
          size.width *
              (0.10 +
                  ((i * 23) % 78) / 100 +
                  math.sin(progress * math.pi * 2 + i) * 0.012),
          size.height *
              (0.10 + ((i * 31) % 82) / 100 + progress * 0.020) %
              size.height,
        ),
        1.1 + (i % 3) * 0.45,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DrawerDimensionFieldPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.progress != progress;
  }
}

class _ModeConstellation extends StatelessWidget {
  final TruIdentityMode activeMode;
  final ValueChanged<TruIdentityMode> onSelected;

  const _ModeConstellation({
    required this.activeMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const modes = [
      (TruIdentityMode.friendship, 'Friendship', Icons.people_outline),
      (TruIdentityMode.dating, 'Dating', Icons.favorite_border),
      (TruIdentityMode.creator, 'Creator', Icons.auto_awesome),
      (TruIdentityMode.luxe, 'Luxe', Icons.diamond_outlined),
      (TruIdentityMode.social, 'Social', Icons.public),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 10),
            child: Text(
              'MODES',
              style: TextStyle(
                color: TruLuraKitPalette.textDim,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 24,
                  right: 24,
                  top: 27,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          TruLuraTokens.auraPink.withValues(alpha: 0.26),
                          TruLuraTokens.auraCyan.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final mode in modes)
                      _ModeSignal(
                        label: mode.$2,
                        icon: mode.$3,
                        selected: activeMode == mode.$1,
                        onTap: () => onSelected(mode.$1),
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
}

class _ModeSignal extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSignal({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? TruLuraTokens.auraPink : TruLuraTokens.auraCyan;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 38 : 32,
              height: selected ? 38 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: selected ? 0.20 : 0.08),
                border: Border.all(
                  color: accent.withValues(alpha: selected ? 0.55 : 0.18),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 22,
                          spreadRadius: -5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 17,
                color: selected
                    ? TruLuraKitPalette.text
                    : TruLuraKitPalette.textDim,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: selected
                    ? TruLuraKitPalette.text
                    : TruLuraKitPalette.textDim,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDestination {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool active;
  final VoidCallback onTap;

  const _DrawerDestination({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.active,
    required this.onTap,
  });
}

class _DrawerGroupTitle extends StatelessWidget {
  final String text;

  const _DrawerGroupTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final Color glow = text == 'EXTENSIONS'
        ? TruLuraKitPalette.mint
        : TruLuraKitPalette.purple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: TruLuraKitPalette.textDim,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        _GlowingDivider(glow: glow),
      ],
    );
  }
}

class _DrawerIsland extends StatelessWidget {
  final String title;
  final Color glow;
  final List<Widget> children;

  const _DrawerIsland({
    required this.title,
    required this.glow,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(title == 'LIVING SYSTEMS' ? 8 : 0, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glow.withValues(alpha: 0.085),
                  Colors.white.withValues(alpha: 0.035),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: TruLuraSurfaces.hairline,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.18),
                  blurRadius: 38,
                  spreadRadius: -20,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DrawerGroupTitle(title),
                  const SizedBox(height: 8),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingDivider extends StatelessWidget {
  final Color glow;

  const _GlowingDivider({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            glow.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.62, 1.0],
        ),
        boxShadow: [
          BoxShadow(
              color: glow.withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: 0),
        ],
      ),
    );
  }
}

class _KitDrawerItem extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _KitDrawerItem(
      {required this.icon,
      required this.label,
      this.subtitle,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final isWorld = const {'Aura', 'Sync', 'Explore', 'Vent'}.contains(label);
    final isSystem = const {
      'TruJourney',
      'TruTV',
      'TruStudio',
      'TruCompanion',
    }.contains(label);

    final Color accent = _accentFor(label, soft: soft);
    final Color tint = active
        ? accent.withValues(alpha: 0.13)
        : Colors.white.withValues(alpha: 0.045);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: TruLuraGlassCard(
          radius: active ? 20 : 18,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isWorld
                ? 15
                : isSystem
                    ? 9
                    : 12,
          ),
          tint: tint,
          glow: accent,
          depth: active,
          gradientStroke: active,
          child: Row(
            children: [
              Container(
                width: isWorld ? 36 : 30,
                height: isWorld ? 36 : 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: active ? 0.50 : 0.24),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: active ? 0.14 : 0.07),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: Icon(
                  icon,
                  color: TruLuraKitPalette.text,
                  size: isWorld ? 20 : 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: active
                                ? TruLuraKitPalette.text
                                : TruLuraKitPalette.text
                                    .withValues(alpha: 0.90),
                            fontWeight:
                                active ? FontWeight.w900 : FontWeight.w700)),
                    if ((subtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TruLuraKitPalette.textDim
                              .withValues(alpha: active ? 0.92 : 0.78),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: active ? accent : TruLuraKitPalette.textDim),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(String label, {required bool soft}) {
    if (soft) return TruLuraTokens.auraCyan;
    final lower = label.toLowerCase();
    if (lower.contains('sync') || lower.contains('luxe')) {
      return TruLuraTokens.auraPink;
    }
    if (lower.contains('vent') || lower.contains('safety')) {
      return TruLuraTokens.auraCyan;
    }
    if (lower.contains('explore') || lower.contains('live')) {
      return TruLuraBrandColors.glowGold;
    }
    if (lower.contains('studio') || lower.contains('creator')) {
      return TruLuraTokens.auraCyan;
    }
    return TruLuraTokens.auraViolet;
  }
}
