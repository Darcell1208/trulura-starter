import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/widgets/trulura_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Phase-1: start with Auth quickly.
    // We keep a very short delay so the brand moment still feels intentional,
    // but we avoid the old 2s block that made the app feel “stuck”.
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    try {
      final app = context.read<AppProvider>();
      if (!AuthService.instance.isSignedIn) {
        _go(AppRoutes.signIn);
        return;
      }

      final user = await UserService()
          .getCurrentUser()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (!mounted) return;

      if (user == null) {
        app.setCurrentUser(null);
        _go(AppRoutes.signIn);
        return;
      }

      app.setCurrentUser(user);
      _go(app.needsOnboarding ? AppRoutes.onboardingIntent : AppRoutes.home);
    } catch (e) {
      debugPrint('SplashScreen auth gate failed: $e');
      if (mounted) _go(AppRoutes.signIn);
    }
  }

  void _go(String location) {
    if (_didNavigate || !mounted) return;
    _didNavigate = true;
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: TruLuraGradients.cosmicAuraBase,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TruLuraBrandLogo(size: 120, radius: 30),
              const SizedBox(height: 32),
              Text(
                'TruLura',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aura-first connection.\nDating optional.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
