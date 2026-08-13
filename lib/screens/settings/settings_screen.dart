import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_route_observer.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RouteAware {
  final ScrollController _scrollController = ScrollController();

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
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final currentRoute = GoRouterState.of(context).uri.toString();
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 1180 ? 1040.0 : double.infinity;

    String directRoute(String path) => Uri(
          path: path,
          queryParameters: {'returnTo': currentRoute},
        ).toString();

    String placeholderRoute(String title, String subtitle) => Uri(
          path: AppRoutes.placeholder,
          queryParameters: {
            'title': title,
            'subtitle': subtitle,
            'returnTo': currentRoute,
          },
        ).toString();

    final destinations = <_ExperienceDestination>[
      _ExperienceDestination(
        title: 'Appearance Worlds',
        subtitle: 'Choose how TruLura feels around you.',
        glyph: TruLuraGlyph.moon,
        accent: TruLuraTokens.auraViolet,
        body: _AppearanceWorldControl(app: app),
      ),
      _ExperienceDestination(
        title: 'Accessibility Modes',
        subtitle: app.softModeEnabled
            ? 'Soft Mode is calming motion and glow.'
            : 'Adjust motion, glow, and sensory intensity.',
        glyph: TruLuraGlyph.moon,
        accent: TruLuraTokens.auraCyan,
        onTap: () => context.push(directRoute(AppRoutes.accessibility)),
        body: TruToggle(
          value: app.softModeEnabled,
          onChanged: (v) => app.setSoftModeEnabled(v),
        ),
      ),
      _ExperienceDestination(
        title: 'Emotional Safety',
        subtitle: 'Boundaries, blocks, reports, and protection tools.',
        glyph: TruLuraGlyph.shield,
        accent: TruLuraBrandColors.neonBlue,
        onTap: () => context.push(directRoute(AppRoutes.safetyCenter)),
      ),
      _ExperienceDestination(
        title: 'Recovery & Rest',
        subtitle: app.lowEnergyFeedEnabled
            ? 'Low-energy pacing is active.'
            : 'Create a softer recovery rhythm.',
        glyph: TruLuraGlyph.heartOutline,
        accent: TruLuraBrandColors.glowGold,
        body: TruToggle(
          value: app.lowEnergyFeedEnabled,
          onChanged: (v) => app.setLowEnergyFeedEnabled(v),
        ),
      ),
      _ExperienceDestination(
        title: 'Adaptive Intelligence',
        subtitle: 'Tune feed intelligence, emotional pacing, and suggestions.',
        glyph: TruLuraGlyph.insights,
        accent: TruLuraTokens.auraPink,
        onTap: () => context.push(directRoute(AppRoutes.feedPersonalization)),
      ),
      _ExperienceDestination(
        title: 'Notifications & Energy',
        subtitle: app.showLivesInFeed
            ? 'Live and message energy can reach you.'
            : 'Live energy is quieted.',
        glyph: TruLuraGlyph.messages,
        accent: TruLuraBrandColors.nebulaMagenta,
        body: TruToggle(
          value: app.showLivesInFeed,
          onChanged: (v) => app.setShowLivesInFeed(v),
        ),
      ),
      _ExperienceDestination(
        title: 'Privacy & Trust',
        subtitle: 'Profile visibility, screenshots, verification, and trust.',
        glyph: TruLuraGlyph.lock,
        accent: TruLuraTokens.auraCyan,
        onTap: () => context.push(directRoute(AppRoutes.privacy)),
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        title: 'Experience Center',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                TruLuraGlassCard(
                  radius: 30,
                  depth: true,
                  glow: TruLuraTokens.auraViolet,
                  tint: TruLuraTokens.auraViolet.withValues(alpha: 0.045),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TruLura Experience Center',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shape the worlds around you: appearance, rest, safety, intelligence, energy, privacy, and trust.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.72),
                              height: 1.42,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 620
                            ? 2
                            : 1;
                    return GridView.builder(
                      primary: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: destinations.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: columns == 1 ? 2.5 : 1.28,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return _ExperienceDestinationCard(
                          destination: destinations[index],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ExperienceLinks(
                  onProfile: () => context.push(
                    directRoute(AppRoutes.onboardingProfileSetup),
                  ),
                  onVerification: () => context.push(
                    directRoute(AppRoutes.safetyVerification),
                  ),
                  onHelp: () =>
                      context.push(directRoute(AppRoutes.helpSupport)),
                  onAbout: () =>
                      context.push(directRoute(AppRoutes.aboutTruLura)),
                  onModes: () =>
                      context.push(directRoute(AppRoutes.experienceModes)),
                  onAura: () => context.push(placeholderRoute(
                    'Aura Mode Settings',
                    'Tune aura prompts, reflection pacing, and emotional orbit behavior.',
                  )),
                  onSync: () => context.push(placeholderRoute(
                    'Sync Mode Settings',
                    'Tune resonance preferences, boundaries, and connection rooms.',
                  )),
                  onExplore: () => context.push(placeholderRoute(
                    'Explore Mode Settings',
                    'Tune discovery lanes, categories, and worlds beyond you.',
                  )),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    await UserService().logout();
                    if (!context.mounted) return;
                    context.read<AppProvider>().setCurrentUser(null);
                    context.go('/auth/sign_in');
                  },
                  icon: const TruLuraIcon(glyph: TruLuraGlyph.logout, size: 18),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceDestination {
  final String title;
  final String subtitle;
  final TruLuraGlyph glyph;
  final Color accent;
  final VoidCallback? onTap;
  final Widget? body;

  const _ExperienceDestination({
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.accent,
    this.onTap,
    this.body,
  });
}

class _ExperienceDestinationCard extends StatelessWidget {
  final _ExperienceDestination destination;

  const _ExperienceDestinationCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 24,
      depth: true,
      glow: destination.accent,
      tint: destination.accent.withValues(alpha: 0.04),
      padding: const EdgeInsets.all(14),
      onTap: destination.onTap,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            width: 110,
            height: 110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      destination.accent.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: destination.accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: TruLuraSurfaces.hairline,
                      ),
                    ),
                    child: TruLuraIcon(
                      glyph: destination.glyph,
                      size: 20,
                      active: true,
                      color: destination.accent,
                    ),
                  ),
                  const Spacer(),
                  if (destination.body != null) destination.body!,
                  if (destination.body == null && destination.onTap != null)
                    TruLuraIcon(
                      glyph: TruLuraGlyph.chevronRight,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.62),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                destination.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                destination.subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.32,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppearanceWorldControl extends StatelessWidget {
  final AppProvider app;

  const _AppearanceWorldControl({required this.app});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: app.appearanceMode,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'trulura', child: Text('TruLura')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
          ],
          onChanged: (value) {
            if (value != null) app.setAppearanceMode(value);
          },
        ),
      ),
    );
  }
}

class _ExperienceLinks extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onVerification;
  final VoidCallback onHelp;
  final VoidCallback onAbout;
  final VoidCallback onModes;
  final VoidCallback onAura;
  final VoidCallback onSync;
  final VoidCallback onExplore;

  const _ExperienceLinks({
    required this.onProfile,
    required this.onVerification,
    required this.onHelp,
    required this.onAbout,
    required this.onModes,
    required this.onAura,
    required this.onSync,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      ('Profile setup', TruLuraGlyph.person, onProfile),
      ('Verification', TruLuraGlyph.check, onVerification),
      ('Experience modes', TruLuraGlyph.spark, onModes),
      ('Aura tuning', TruLuraGlyph.aura, onAura),
      ('Sync tuning', TruLuraGlyph.sync, onSync),
      ('Explore tuning', TruLuraGlyph.explore, onExplore),
      ('Help', TruLuraGlyph.help, onHelp),
      ('About', TruLuraGlyph.info, onAbout),
    ];
    return TruLuraGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final link in links)
            ActionChip(
              avatar: TruLuraIcon(glyph: link.$2, size: 16),
              label: Text(link.$1),
              onPressed: link.$3,
            ),
        ],
      ),
    );
  }
}
