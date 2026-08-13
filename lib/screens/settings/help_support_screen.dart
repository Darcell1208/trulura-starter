import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        showClose: true,
        onBack: () =>
            TruNavigation.goBackOrReturn(context, fallback: AppRoutes.settings),
        onClose: () =>
            TruNavigation.closeModule(context, fallback: AppRoutes.settings),
        title: 'Help & Support',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.explore,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: const [
            _InfoCard(
              title: 'Help topics',
              lines: [
                'Account help: signing in, editing your profile, and updating identity layers.',
                'Privacy and safety help: messaging boundaries, Privacy settings, blocks, and reports.',
                'Creator and onboarding help: persona setup, profile completion, and creator approval guidance.',
              ],
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Reporting and blocking guidance',
              lines: [
                'Use Safety Center when you need to adjust boundaries or review blocked users.',
                'Use reporting when behavior crosses the line or feels unsafe.',
                'Blocking removes contact and reduces future visibility.',
              ],
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Support contact',
              lines: [
                'Support requests are held in a calm, private pathway.',
                'For urgent safety concerns, use Safety Center so boundaries and reports stay tied to your current context.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TruLuraIcon(
                glyph: TruLuraGlyph.help,
                size: 18,
                active: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Text(
              line,
              style: t.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.82),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
