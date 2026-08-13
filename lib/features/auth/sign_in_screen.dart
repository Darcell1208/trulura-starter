import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/aura_background.dart';
import 'package:trulura/widgets/trulura_cinematic_components.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.clearMaterialBanners();
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: _email.text.trim(),
        password: _password.text,
      );
      final user = await UserService().getCurrentUser();
      if (!mounted) return;
      messenger?.clearSnackBars();
      messenger?.clearMaterialBanners();
      context.read<AppProvider>().setCurrentUser(user);
      context.go(AppRoutes.home);
    } catch (e) {
      debugPrint('Sign in failed: $e');
      if (!mounted) return;

      var message = 'Sign in failed.';
      SnackBarAction? action;

      if (e is AuthApiException) {
        switch (e.code) {
          case 'email_not_confirmed':
            message = 'Confirm your email to sign in. Check your inbox.';
            action = SnackBarAction(
              label: 'Resend',
              onPressed: () async {
                try {
                  await AuthService.instance.resendSignupConfirmationEmail(
                    email: _email.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confirmation email resent.')),
                  );
                } catch (err) {
                  debugPrint('Resend confirmation failed: $err');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not resend email. Try again.'),
                    ),
                  );
                }
              },
            );
            break;
          case 'invalid_credentials':
            message = 'Wrong email or password.';
            action = SnackBarAction(
              label: 'Reset',
              onPressed: () async {
                final localMessenger = ScaffoldMessenger.of(context);
                try {
                  await AuthService.instance.sendPasswordReset(
                    email: _email.text.trim(),
                  );
                  if (!mounted) return;
                  localMessenger.showSnackBar(
                    const SnackBar(content: Text('Password reset email sent.')),
                  );
                } catch (err) {
                  debugPrint('Password reset failed: $err');
                  if (!mounted) return;
                  localMessenger.showSnackBar(
                    const SnackBar(
                        content: Text('Could not send reset email.')),
                  );
                }
              },
            );
            break;
          default:
            message = e.message;
        }
      } else {
        message = 'Sign in failed. Check your credentials.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), action: action),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        accentA: TruLuraTokens.auraViolet,
        accentB: TruLuraBrandColors.glowGold,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        (viewport.maxHeight - 44).clamp(0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          final brand = _AuthBrandPanel(wide: wide);
                          final form = _AuthFormPanel(
                            formKey: _formKey,
                            email: _email,
                            password: _password,
                            loading: _loading,
                            onSubmit: _submit,
                          );
                          if (!wide) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                brand,
                                const SizedBox(height: 16),
                                form,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 6, child: brand),
                              const SizedBox(width: 18),
                              Expanded(flex: 5, child: form),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  final bool wide;

  const _AuthBrandPanel({required this.wide});

  @override
  Widget build(BuildContext context) {
    return CosmicGlassCard(
      radius: 34,
      accent: TruLuraBrandColors.glowGold,
      padding: EdgeInsets.fromLTRB(28, wide ? 34 : 28, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TruLuraLogoHeader(),
          const SizedBox(height: 30),
          Text(
            'The emotional universe where truth, safety, and connection glow in the same orbit.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TruLuraTokens.textPrimary,
                  fontFamily: 'Georgia',
                  height: 1.20,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 22),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              EmotionalChip(
                label: 'Aura Safe',
                glyph: TruLuraGlyph.shield,
                selected: true,
              ),
              EmotionalChip(
                label: 'Soul Aligned',
                glyph: TruLuraGlyph.sync,
                accent: TruLuraBrandColors.glowGold,
              ),
              EmotionalChip(
                label: 'Human First',
                glyph: TruLuraGlyph.heartOutline,
                accent: TruLuraTokens.auraPink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final VoidCallback onSubmit;

  const _AuthFormPanel({
    required this.formKey,
    required this.email,
    required this.password,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CosmicGlassCard(
      radius: 32,
      accent: TruLuraTokens.auraPink,
      padding: const EdgeInsets.all(22),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: TruLuraTokens.textPrimary,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Return to your aura, your people, and your protected emotional world.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TruLuraTokens.textSecondary,
                    height: 1.38,
                  ),
            ),
            const SizedBox(height: 22),
            _Field(
              controller: email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: password,
              label: 'Password',
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      TruLuraTokens.auraViolet,
                      TruLuraTokens.auraPink,
                      TruLuraBrandColors.glowGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: TruLuraTokens.auraPink.withValues(alpha: 0.26),
                      blurRadius: 28,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: loading ? null : onSubmit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enter TruLura'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: loading ? null : () => context.push(AppRoutes.signUp),
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              child: const Text(
                'New here? Create an account',
                style: TextStyle(
                  color: TruLuraTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: loading ? null : () => _resetPassword(context),
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: TruLuraTokens.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final address = email.text.trim();
    if (address.isEmpty || !address.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your email first.')),
      );
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email: address);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      debugPrint('Forgot password failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send reset email.')),
      );
    }
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: TruLuraTokens.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: TruLuraTokens.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.065),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TruLuraTokens.auraCyan),
        ),
      ),
    );
  }
}
