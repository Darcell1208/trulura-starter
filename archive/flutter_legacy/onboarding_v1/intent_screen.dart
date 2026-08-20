import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class IntentScreen extends StatefulWidget {
  const IntentScreen({super.key});

  @override
  State<IntentScreen> createState() => _IntentScreenState();
}

class _IntentScreenState extends State<IntentScreen> {
  final List<String> _selectedIntents = [];
  final List<String> _intents = ['Aura', 'Dating', 'Friendship', 'Networking'];

  String _nextRoute() {
    final returnTo =
        TruNavigation.resolveReturnTo(context) ??
        GoRouterState.of(context).uri.queryParameters['returnTo'];
    return Uri(
      path: AppRoutes.onboardingVibe,
      queryParameters: {
        if (returnTo != null && returnTo.trim().isNotEmpty)
          'returnTo': returnTo,
      },
    ).toString();
  }

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
                'What brings you here?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select all that apply',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: _intents.length,
                  itemBuilder: (context, index) {
                    final intent = _intents[index];
                    final isSelected = _selectedIntents.contains(intent);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IntentCard(
                        title: intent,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIntents.remove(intent);
                            } else {
                              _selectedIntents.add(intent);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              TruLuraPrimaryButton(
                onPressed: _selectedIntents.isEmpty
                    ? null
                    : () => context.push(_nextRoute()),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class IntentCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const IntentCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            TruLuraIcon(
              glyph: isSelected ? TruLuraGlyph.check : TruLuraGlyph.circle,
              active: isSelected,
              size: 22,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
