import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  String? _photoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Add your photo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Show the world your best self',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _photoPath = 'assets/images/portrait_young_woman_smiling_null_1772162274859.jpg';
                    });
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: _photoPath != null
                        ? ClipOval(
                            child: Image.asset(_photoPath!, fit: BoxFit.cover),
                          )
                        : TruLuraIcon(glyph: TruLuraGlyph.image, size: 48, active: false, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const Spacer(),
              TruLuraPrimaryButton(
                onPressed: _photoPath == null ? null : () => context.push('/onboarding/profile'),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/onboarding/profile'),
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
