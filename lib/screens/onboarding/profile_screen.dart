import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const TruLuraIcon(glyph: TruLuraGlyph.back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Tell us about you',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This is how others will see you',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.person, size: 20)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.at, size: 20)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.edit, size: 20)),
                  hintText: 'Tell us something interesting...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              TruLuraPrimaryButton(
                onPressed: () => context.push('/onboarding/basics'),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
