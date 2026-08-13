import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class SoftModeGateScreen extends StatelessWidget {
  const SoftModeGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    const TruLuraIcon(glyph: TruLuraGlyph.moon, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Soft Mode',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: -0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Designed for accessibility and low-stimulation moments.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.82), height: 1.45),
                ),
                const SizedBox(height: 22),
                _SoftModeBullet(
                  glyph: TruLuraGlyph.filter,
                  title: 'Less motion + glow',
                  subtitle: 'Reduces neon intensity and disables particle effects.',
                ),
                const SizedBox(height: 12),
                _SoftModeBullet(
                  glyph: TruLuraGlyph.video,
                  title: 'No autoplay',
                  subtitle: 'Motion feed requires tap to play.',
                ),
                const Spacer(),
                TruLuraPrimaryButton(
                  onPressed: () async {
                    await context.read<AppProvider>().completeSoftModeGate(enabled: false);
                    if (context.mounted) context.go('/login');
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [TruLuraIcon(glyph: TruLuraGlyph.spark, size: 20, active: true, color: Colors.white), SizedBox(width: 10), Text('Continue in Cinematic Mode')],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await context.read<AppProvider>().completeSoftModeGate(enabled: true);
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurface,
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [TruLuraIcon(glyph: TruLuraGlyph.moon, size: 20, active: true), SizedBox(width: 10), Text('Enable Soft Mode')],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You can change this later in Settings → Accessibility.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftModeBullet extends StatelessWidget {
  final TruLuraGlyph glyph;
  final String title;
  final String subtitle;

  const _SoftModeBullet({required this.glyph, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        boxShadow: TruLuraEffects.premiumCardDepth(Colors.black, intensity: 0.35),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: TruLuraGradients.primaryButton,
              boxShadow: TruLuraEffects.softGlow(cs.primary, intensity: 0.8),
            ),
            child: TruLuraIcon(glyph: glyph, size: 20, active: true, color: cs.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
