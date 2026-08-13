import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class LiveHubScreen extends StatelessWidget {
  const LiveHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => TruNavigation.goBackOrReturn(context),
        ),
        actions: [
          IconButton(
            icon: const TruLuraIcon(glyph: TruLuraGlyph.close, size: 20),
            onPressed: () => TruNavigation.closeModule(context),
          ),
        ],
        title: Row(
          children: [
            const Text('Live'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                boxShadow: app.softModeEnabled ? [] : TruLuraEffects.softGlow(TruLuraBrandColors.nebulaMagenta, intensity: 0.7 * app.glowScale),
              ),
              child: Text('LIVE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ),
          ],
        ),
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.explore,
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            Text('Join a session', style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: -0.6)),
            const SizedBox(height: 12),
            _LiveCard(
              title: 'Featured rooms',
              subtitle: 'Browse public Lives and jump in instantly.',
              icon: TruLuraGlyph.groups,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'))),
            ),
            const SizedBox(height: 18),
            Text('Start a Live', style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: -0.6)),
            const SizedBox(height: 12),
            _LiveCard(
              title: 'Basic Live (Everyone)',
              subtitle: 'Go live with a clean, structured layout.',
              icon: TruLuraGlyph.video,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Basic Live session started (stub)'))),
            ),
            const SizedBox(height: 12),
            if (app.creatorModeEnabled &&
                app.creatorOnboardingComplete &&
                app.creatorApproved)
              _LiveCard(
                title: 'TruStudio Tools',
                subtitle: 'Creator overlays + advanced hosting tools.',
                icon: TruLuraGlyph.star,
                onTap: () => TruNavigation.pushWithInheritedReturnTo(
                  context,
                  AppRoutes.truStudio,
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Want creator tools?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Hosting is open to everyone, but TruStudio overlays, analytics, and monetization require creator onboarding and approval.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      TruLuraPrimaryButton(
                        expand: false,
                        onPressed: () => TruNavigation.pushWithInheritedReturnTo(
                          context,
                          AppRoutes.settings,
                        ),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TruLuraGlyph icon;
  final VoidCallback onTap;

  const _LiveCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                ),
                child: TruLuraIcon(glyph: icon, size: 22, active: true, color: cs.onSurface),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.3)),
                  ],
                ),
              ),
              TruLuraIcon(glyph: TruLuraGlyph.chevronRight, size: 18, active: false, color: cs.onSurface.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
