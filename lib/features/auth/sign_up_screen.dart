import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme/trulura_theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final resp = await AuthService.instance.signUpWithEmail(email: _email.text.trim(), password: _password.text, name: _name.text.trim());

      // If email confirmation is enabled, Supabase returns a user but no session.
      // In that case, the user is NOT signed in yet, so we should not proceed.
      if (resp.session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email to confirm your account, then sign in.')),
        );
        context.go(AppRoutes.signIn);
        return;
      }

      final user = await UserService().getCurrentUser();
      if (!mounted) return;
      context.read<AppProvider>().setCurrentUser(user);
      context.go(AppRoutes.home);
    } catch (e) {
      debugPrint('Sign up failed: $e');
      if (!mounted) return;
      String message = 'Sign up failed.';
      if (e is AuthApiException) {
        message = e.message;
      } else if (e is AuthRetryableFetchException) {
        // Supabase sometimes returns JSON in the message for unexpected failures.
        message = 'Sign up failed: ${e.message}';
      } else {
        message = 'Sign up failed: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                constraints: const BoxConstraints(maxWidth: 430),
                child: TruLuraGlassCard(
                  radius: 28,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Create your TruLura account',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 20),
                        _Field(
                          controller: _name,
                          label: 'Display Name',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _email,
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
                          controller: _password,
                          label: 'Password',
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter a password';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _confirm,
                          label: 'Confirm Password',
                          obscureText: true,
                          validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: TruluraTheme.primaryGlow, borderRadius: BorderRadius.circular(18)),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Continue'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _loading ? null : () => context.pop(),
                          style: const ButtonStyle(overlayColor: WidgetStatePropertyAll(Colors.transparent)),
                          child: const Text('Already have an account? Sign in', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({required this.controller, required this.label, this.obscureText = false, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: TruluraTheme.cyan)),
      ),
    );
  }
}
