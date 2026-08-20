import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_orb_chip.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: TruLuraLayeredBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Pick your vibe',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your aura sets the tone for what you see and who finds you.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: Mood.values.map((mood) {
                        final isSelected = aura.mood == mood;
                        return TruLuraOrbChip(
                          label: _labelForMood(mood),
                          selected: isSelected,
                          glyph: _glyphForMood(mood),
                          onTap: () {
                            debugPrint('Tapped mood: $mood');
                            context.read<AuraController>().updateMood(mood);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TruLuraPrimaryButton(
                  onPressed: () {
                    debugPrint('Tapped mood continue');
                    context.push('/onboarding/photo');
                  },
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelForMood(Mood mood) {
    switch (mood) {
      case Mood.reflective:
        return 'Reflective';
      case Mood.flirty:
        return 'Flirty';
      case Mood.calm:
        return 'Calm';
      case Mood.social:
        return 'Social';
      case Mood.healing:
        return 'Healing';
    }
  }

  TruLuraGlyph _glyphForMood(Mood mood) {
    switch (mood) {
      case Mood.reflective:
        return TruLuraGlyph.moon;
      case Mood.flirty:
        return TruLuraGlyph.spark;
      case Mood.calm:
        return TruLuraGlyph.moon;
      case Mood.social:
        return TruLuraGlyph.star;
      case Mood.healing:
        return TruLuraGlyph.spark;
    }
  }
}
