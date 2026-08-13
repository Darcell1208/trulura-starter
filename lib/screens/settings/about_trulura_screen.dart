import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

class AboutTruLuraScreen extends StatelessWidget {
  const AboutTruLuraScreen({super.key});

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
        title: 'About TruLura',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: const [
            _AboutCard(
              title: 'Platform purpose',
              text:
                  'TruLura is a social-first platform built around expressive identity, discovery, and emotionally aware connection.',
            ),
            SizedBox(height: 14),
            _AboutCard(
              title: 'Social-first, optional dating',
              text:
                  'Dating is optional here. Social, friendship, creator, and deeper personal discovery can all exist without forcing a dating-first flow.',
            ),
            SizedBox(height: 14),
            _AboutCard(
              title: 'Mode-aware discovery',
              text:
                  'Aura, Sync, Explore, identity layers, and personalization signals work together to shape what feels relevant without hard-locking the app into one mode.',
            ),
            SizedBox(height: 14),
            _AboutCard(
              title: 'Safety-first',
              text:
                  'Trust, privacy, consent cues, and safety layers are meant to support user control, not override it.',
            ),
            SizedBox(height: 14),
            _AboutCard(
              title: 'Current build phase',
              text:
                  'This build is still wiring together real flows and local-first systems. Some verification, media, and support tools remain backend-dependent stubs.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final String text;

  const _AboutCard({required this.title, required this.text});

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
                glyph: TruLuraGlyph.info,
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
          Text(
            text,
            style: t.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
