import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/trulura_mode.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _continue() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter name, email, and a 6+ character password.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await AuthService.instance.signUpWithEmail(email: email, password: password, name: name);

      if (resp.session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email to confirm your account, then sign in.')),
        );
        context.go('/auth/sign_in');
        return;
      }

      final user = await UserService().getCurrentUser();
      if (!mounted) return;
      context.read<AppProvider>().setCurrentUser(user);
      context.push('/onboarding/intent');
    } catch (e) {
      debugPrint('Signup failed: $e');
      if (!mounted) return;
      String message = 'Sign up failed.';
      if (e is AuthApiException) {
        message = e.message;
      } else if (e is AuthRetryableFetchException) {
        message = 'Sign up failed: ${e.message}';
      } else {
        message = 'Sign up failed: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        title: 'Create Account',
        showBack: true,
        mode: TruLuraMode.aura,
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.fromLTRB(18, 86, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Text(
                'Ready to get glowing?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your profile in a few steps.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TruLuraGlassCard(
                mode: TruLuraMode.aura,
                radius: 26,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.person, size: 20)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.at, size: 20)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.lock, size: 20)),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    TruLuraPrimaryButton(
                      onPressed: _isLoading ? null : _continue,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Continue'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Already have an account? Sign In', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.86))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
