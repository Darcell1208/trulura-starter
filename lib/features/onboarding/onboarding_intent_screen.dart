import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme/trulura_theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';

import 'package:trulura/features/onboarding/onboarding_scaffold.dart';

class OnboardingIntentScreen extends StatefulWidget {
  const OnboardingIntentScreen({super.key});

  @override
  State<OnboardingIntentScreen> createState() => _OnboardingIntentScreenState();
}

class _OnboardingIntentScreenState extends State<OnboardingIntentScreen> {
  String? selected;
  final options = const ['Social', 'Dating', 'Friendship', 'Networking', 'Healing', 'Exploration'];
  bool _saving = false;

  String? get _explicitReturnTo {
    final extraReturnTo = TruNavigation.resolveReturnTo(context);
    if (extraReturnTo != null) return extraReturnTo;
    final route = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (route != null && route.trim().isNotEmpty) return route;
    return null;
  }

  String _resolveReturnTo() {
    return _explicitReturnTo ?? AppRoutes.homeTab('aura');
  }

  Future<void> _continue() async {
    if (_saving || selected == null) return;
    setState(() => _saving = true);
    try {
      final app = context.read<AppProvider>();
      final me = app.currentUser;
      if (me != null) {
        final updated = me.copyWith(intents: [selected!], updatedAt: DateTime.now());
        await UserService().saveUser(updated);
        await app.refreshCurrentUserFromSupabase();
      }
      if (!mounted) return;
      if (_explicitReturnTo != null) {
        context.go(_resolveReturnTo());
      } else {
        context.go(AppRoutes.onboardingVibe);
      }
    } catch (e) {
      debugPrint('Failed to save onboarding intent: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save intent. Try again.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TruLuraOnboardingScaffold(
      title: 'Choose your primary intent',
      subtitle: 'This shapes how TruLura introduces you to people and spaces.',
      child: Column(
        children: [
          ...options.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => selected = item),
                child: TruLuraGlassCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      Icon(
                        selected == item ? Icons.check_circle : Icons.circle_outlined,
                        color: selected == item ? TruluraTheme.cyan : Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                onPressed: selected == null || _saving ? null : _continue,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_explicitReturnTo != null)
            TextButton(
              onPressed: _saving ? null : () => context.go(_resolveReturnTo()),
              child: const Text('Skip for now'),
            ),
        ],
      ),
    );
  }
}
