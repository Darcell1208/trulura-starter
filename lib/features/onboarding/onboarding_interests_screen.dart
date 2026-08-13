import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme/trulura_theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';

import 'package:trulura/features/onboarding/onboarding_scaffold.dart';

class OnboardingInterestsScreen extends StatefulWidget {
  const OnboardingInterestsScreen({super.key});

  @override
  State<OnboardingInterestsScreen> createState() => _OnboardingInterestsScreenState();
}

class _OnboardingInterestsScreenState extends State<OnboardingInterestsScreen> {
  final selected = <String>{};
  bool _saving = false;
  final interests = const [
    'Anime',
    'Travel',
    'Cooking',
    'Gaming',
    'Parenting',
    'Music',
    'Healing',
    'Fitness',
    'Creativity',
    'Emotional Depth',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final user = await UserService().getCurrentUser();
    if (!mounted || user == null) return;
    setState(() {
      selected
        ..clear()
        ..addAll(user.interests);
    });
  }

  String _resolveReturnTo() {
    final extraReturnTo = TruNavigation.resolveReturnTo(context);
    if (extraReturnTo != null) return extraReturnTo;
    final route = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (route != null && route.trim().isNotEmpty) return route;
    return AppRoutes.homeTab('aura');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    final hasSelection = selected.isNotEmpty;
    return TruLuraOnboardingScaffold(
      title: 'Pick a few interests',
      subtitle: 'These help us shape your community and discovery flow.',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: interests.map((interest) {
              final active = selected.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    active ? selected.remove(interest) : selected.add(interest);
                  });
                },
                child: TruLuraGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: active ? activeColor : cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: TruluraTheme.primaryGlow, borderRadius: BorderRadius.circular(18)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: !hasSelection || _saving ? null : _saveAndContinue,
                child: Text(_saving ? 'Saving...' : 'Continue'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _saving ? null : () => context.go(_resolveReturnTo()),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    final app = context.read<AppProvider>();
    final appState = context.read<AppState>();
    final user = app.currentUser;
    if (user == null) {
      context.go(_resolveReturnTo());
      return;
    }

    setState(() => _saving = true);
    await UserService().saveInterests(
      userId: user.id,
      interests: selected.toList(growable: false),
    );
    await appState.markInterestQuizCompleted(userId: user.id);
    await app.refreshCurrentUserFromSupabase();
    if (!mounted) return;
    context.go(_resolveReturnTo());
  }
}
