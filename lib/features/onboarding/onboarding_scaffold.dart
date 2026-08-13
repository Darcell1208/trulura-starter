import 'package:flutter/material.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/theme/trulura_theme.dart';

/// Shared onboarding scaffold used across the Phase-1 onboarding flow.
class TruLuraOnboardingScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const TruLuraOnboardingScaffold({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: TruluraTheme.cosmicGradient),
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
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          tooltip: 'Back',
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => TruNavigation.closeModule(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
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
