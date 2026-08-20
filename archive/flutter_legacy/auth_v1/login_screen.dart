import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_brand_logo.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/breathing_glow.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  InputDecoration _authDecoration({required String hint, required TruLuraGlyph icon}) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: TruLuraIcon(
          glyph: icon,
          size: 18,
          color: cs.onSurface.withValues(alpha: 0.78),
          active: true,
        ),
      ),
      filled: true,
      fillColor: brightness == Brightness.dark
          ? cs.surfaceContainerHighest.withValues(alpha: 0.30)
          : cs.surface.withValues(alpha: 0.85),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: TruLuraTokens.auraViolet.withValues(alpha: 0.45), width: 1.2),
      ),
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.60),
            fontWeight: FontWeight.w600,
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signInWithEmail(email: _emailController.text.trim(), password: _passwordController.text);
      final user = await UserService().getCurrentUser();
      if (!mounted) return;
      context.read<AppProvider>().setCurrentUser(user);
      context.go('/home/aura');
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;

      String message = 'Sign in failed. Check your credentials.';
      SnackBarAction? action;
      if (e is AuthApiException) {
        if (e.code == 'email_not_confirmed') {
          message = 'Confirm your email to sign in.';
          action = SnackBarAction(
            label: 'Resend',
            onPressed: () async {
              try {
                await AuthService.instance.resendSignupConfirmationEmail(email: _emailController.text.trim());
              } catch (err) {
                debugPrint('Resend confirmation failed: $err');
              }
            },
          );
        } else if (e.code == 'invalid_credentials') {
          message = 'Wrong email or password.';
          action = SnackBarAction(
            label: 'Reset',
            onPressed: () async {
              try {
                await AuthService.instance.sendPasswordReset(email: _emailController.text.trim());
              } catch (err) {
                debugPrint('Password reset failed: $err');
              }
            },
          );
        } else {
          message = e.message;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), action: action));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: EdgeInsets.zero,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TruLuraGlowPill(
                        label: 'TruLura',
                        selected: false,
                        onTap: null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        tone: TruLuraModeTone.aura,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Center(
                      child: BreathingGlow(
                        glowColor: TruLuraTokens.auraViolet,
                        duration: const Duration(milliseconds: 6200),
                        minBlur: 10,
                        maxBlur: 34,
                        minAlpha: 0.10,
                        maxAlpha: 0.22,
                        minSpread: 0.5,
                        maxSpread: 3.5,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: TruLuraTokens.softGlow(TruLuraTokens.auraPink),
                          ),
                          child: const TruLuraBrandLogo(size: 108, radius: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Social-first connection. Dating optional.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.45),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TruLuraGlassCard(
                      mode: TruLuraMode.aura,
                      radius: 28,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: _authDecoration(hint: 'Email', icon: TruLuraGlyph.at),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            decoration: _authDecoration(hint: 'Password', icon: TruLuraGlyph.lock),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _isLoading ? null : _login(),
                          ),
                          const SizedBox(height: 16),
                          TruLuraPrimaryButton(
                            onPressed: _isLoading ? null : _login,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                            borderRadius: 22,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Sign In'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => context.push('/auth/sign_up'),
                            style: ButtonStyle(
                              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                              foregroundColor: WidgetStatePropertyAll(cs.onSurface.withValues(alpha: 0.86)),
                            ),
                            child: Text(
                              "Don't have an account? Sign Up",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.86),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
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
