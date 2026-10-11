import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme/trulura_theme.dart';

/// Shared onboarding scaffold used across the Phase-1 onboarding flow.
class TruLuraOnboardingScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onClose;

  const TruLuraOnboardingScaffold({super.key, required this.title, required this.subtitle, required this.child, this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final illustrated = context.watch<AppProvider>().appearanceMode == 'trulura';
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: cs.surface, gradient: illustrated ? TruluraTheme.cosmicGradient : null),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => TruNavigation.goBackOrReturn(context),
                          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                          tooltip: 'Back',
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onClose ?? () => TruNavigation.closeModule(context),
                          icon: Icon(Icons.close_rounded, color: cs.onSurface),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
