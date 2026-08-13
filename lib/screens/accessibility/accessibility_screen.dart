import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();

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
        title: 'Accessibility',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            kTruluraBottomNavClearance,
          ),
          children: [
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const TruLuraIcon(
                      glyph: TruLuraGlyph.moon, size: 20, active: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soft Mode',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reduce glow and motion, soften transitions, and make the app feel quieter without hiding important controls.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.70),
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  TruToggle(
                    value: app.softModeEnabled,
                    onChanged: (v) => app.setSoftModeEnabled(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _ModePreviewTile(
              glyph: TruLuraGlyph.shield,
              title: 'Seizure Safe Mode',
              body:
                  'Static glow, no flashing, no rapid pulsing, and reduced particle systems.',
            ),
            const SizedBox(height: 10),
            const _ModePreviewTile(
              glyph: TruLuraGlyph.groups,
              title: 'Autism Friendly Mode',
              body:
                  'Predictable layouts, simpler motion, clear sections, and lower sensory load.',
            ),
            const SizedBox(height: 10),
            const _ModePreviewTile(
              glyph: TruLuraGlyph.insights,
              title: 'ADHD Focus Mode',
              body:
                  'Reduced visual noise, focused task surfaces, and fewer non-essential prompts.',
            ),
            const SizedBox(height: 10),
            const _ModePreviewTile(
              glyph: TruLuraGlyph.person,
              title: 'Elder / Low Vision Mode',
              body:
                  'Larger text targets, stronger contrast, clearer labels, and steadier navigation.',
            ),
            const SizedBox(height: 10),
            const _ModePreviewTile(
              glyph: TruLuraGlyph.moon,
              title: 'Recovery Mode',
              body:
                  'Gentle pacing, low energy browsing, softened visuals, and rest-first reminders.',
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best for',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const _BulletLine(
                      text: 'Lower visual stimulation during long sessions'),
                  const _BulletLine(
                      text:
                          'Softer motion when you want the app to feel calmer'),
                  const _BulletLine(
                      text:
                          'A quieter presentation without losing core navigation'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What changes',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _BulletLine(text: 'Particles turn off'),
                  _BulletLine(text: 'Glow intensity is reduced'),
                  _BulletLine(text: 'Transitions become softer'),
                  _BulletLine(text: 'Autoplay pauses where supported'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TruLuraGlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Text(
                'Accessibility in TruLura is meant to calm the experience, not strip away identity. You can switch it back instantly at any time.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.35,
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

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.74),
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePreviewTile extends StatelessWidget {
  final TruLuraGlyph glyph;
  final String title;
  final String body;

  const _ModePreviewTile({
    required this.glyph,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TruLuraGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          TruLuraIcon(
            glyph: glyph,
            size: 22,
            active: true,
            color: cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
