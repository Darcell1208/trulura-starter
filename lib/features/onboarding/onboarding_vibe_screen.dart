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

class OnboardingVibeScreen extends StatefulWidget {
  const OnboardingVibeScreen({super.key});

  @override
  State<OnboardingVibeScreen> createState() => _OnboardingVibeScreenState();
}

class _OnboardingVibeScreenState extends State<OnboardingVibeScreen> {
  String? selected;
  final vibes = const ['Reflective', 'Dreamy', 'Calm', 'Flirty', 'Healing', 'Energetic', 'Creative'];
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
        // Phase-1: store vibe as a mood tag.
        final updated = me.copyWith(moodTags: {selected!, ...me.moodTags}.toList(), updatedAt: DateTime.now());
        await UserService().saveUser(updated);
        await app.refreshCurrentUserFromSupabase();
      }
      if (!mounted) return;
      if (_explicitReturnTo != null) {
        context.go(_resolveReturnTo());
      } else {
        context.go(AppRoutes.onboardingInterests);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    return TruLuraOnboardingScaffold(
      title: 'Choose your current vibe',
      subtitle: 'Your vibe helps shape your feed, spaces, and social energy.',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: vibes.map((v) {
              final active = selected == v;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint('Tapped mood: $v');
                  setState(() => selected = v);
                },
                child: TruLuraGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Text(
                    v,
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
