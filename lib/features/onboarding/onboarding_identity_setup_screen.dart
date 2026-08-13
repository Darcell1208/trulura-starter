import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/features/onboarding/onboarding_scaffold.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/services/identity_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/tru_toggle.dart';
import 'package:trulura/widgets/trulura_segmented_pill.dart';

class OnboardingIdentitySetupScreen extends StatefulWidget {
  const OnboardingIdentitySetupScreen({super.key});

  @override
  State<OnboardingIdentitySetupScreen> createState() => _OnboardingIdentitySetupScreenState();
}

class _OnboardingIdentitySetupScreenState extends State<OnboardingIdentitySetupScreen> {
  final _identity = IdentityService();
  final _users = UserService();

  bool _loading = true;
  bool _saving = false;

  TruIdentityMode _mode = TruIdentityMode.social;
  TruProfileVisibility _visibility = TruProfileVisibility.public;
  bool _anonymous = false;
  final Set<String> _intents = <String>{};

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await _users.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _mode = me?.activeIdentityMode ?? TruIdentityMode.social;
        _visibility = me?.profileVisibility ?? TruProfileVisibility.public;
        _anonymous = me?.anonymousOverlayEnabled ?? false;
        _intents
          ..clear()
          ..addAll(me?.intents ?? const <String>[]);
        _loading = false;
      });
    } catch (e) {
      debugPrint('OnboardingIdentitySetupScreen load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final me = await _users.getCurrentUser();
      if (me == null) return;

      await _identity.setActiveMode(_mode);
      await _identity.setAnonymousOverlay(_anonymous);
      await _identity.setPrivacy(profileVisibility: _visibility);

      await _users.saveUser(me.copyWith(intents: _intents.toList(growable: false), updatedAt: DateTime.now()));

      if (!mounted) return;
      context.go(_nextRoute());
    } catch (e) {
      debugPrint('OnboardingIdentitySetupScreen save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TruLuraOnboardingScaffold(
      title: 'Identity layers',
      subtitle: 'One account. Multiple personas. You stay in control.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 16),
          ],
          Text('Primary layer', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TruluraSegmentedPill(
            options: const ['Social', 'Dating', 'Creator', 'Luxe'],
            selectedIndex: [_mode == TruIdentityMode.social, _mode == TruIdentityMode.dating, _mode == TruIdentityMode.creator, _mode == TruIdentityMode.luxe].indexOf(true),
            onChanged: (i) {
              setState(() {
                _mode = switch (i) { 0 => TruIdentityMode.social, 1 => TruIdentityMode.dating, 2 => TruIdentityMode.creator, _ => TruIdentityMode.luxe };
              });
            },
            activeGradient: TruLuraTokens.identityGradient(_mode, opacity: 0.95),
          ),
          const SizedBox(height: 18),
          Text('Intent (optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _IntentChip(label: 'Exploring', selected: _intents.contains('exploring'), onTap: () => _toggleIntent('exploring')),
              _IntentChip(label: 'Dating', selected: _intents.contains('dating'), onTap: () => _toggleIntent('dating')),
              _IntentChip(label: 'Serious', selected: _intents.contains('serious'), onTap: () => _toggleIntent('serious')),
              _IntentChip(label: 'Companionship', selected: _intents.contains('companionship'), onTap: () => _toggleIntent('companionship')),
            ],
          ),
          const SizedBox(height: 18),
          Text('Visibility', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: TruLuraSurfaces.hairline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TruProfileVisibility>(
                value: _visibility,
                isExpanded: true,
                dropdownColor: cs.surface,
                items: TruProfileVisibility.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                onChanged: (v) => setState(() => _visibility = v ?? TruProfileVisibility.public),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: TruLuraSurfaces.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Anonymous overlay', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Mask your handle + details across this persona.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, height: 1.3)),
                    ],
                  ),
                ),
                TruToggle(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(_saving ? 'Saving…' : 'Continue'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _saving ? null : () => context.go(_nextRoute()),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  void _toggleIntent(String value) {
    setState(() {
      if (_intents.contains(value)) {
        _intents.remove(value);
      } else {
        _intents.add(value);
      }
    });
  }
}

class _IntentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IntentChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: selected ? Colors.white.withValues(alpha: 0.28) : cs.outline.withValues(alpha: 0.18), width: TruLuraSurfaces.hairline),
          boxShadow: selected ? TruLuraTokens.softGlow(TruLuraTokens.auraPink).map((s) => s.copyWith(color: s.color.withValues(alpha: 0.10), blurRadius: s.blurRadius * 0.6)).toList() : const [],
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
