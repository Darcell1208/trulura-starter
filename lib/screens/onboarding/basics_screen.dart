import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class BasicsScreen extends StatefulWidget {
  const BasicsScreen({super.key});

  @override
  State<BasicsScreen> createState() => _BasicsScreenState();
}

class _BasicsScreenState extends State<BasicsScreen> {
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedPronouns = 'she/her';
  final List<String> _selectedLanguages = [];
  final List<String> _languages = ['English', 'Spanish', 'French', 'Mandarin', 'Arabic', 'Portuguese'];

  @override
  void dispose() {
    _locationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final current = await UserService().getCurrentUser();
    if (current == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      context.go('/auth/sign_in');
      return;
    }

    final age = int.tryParse(_ageController.text.trim()) ?? current.age;
    final updated = current.copyWith(
      location: _locationController.text.trim().isEmpty ? current.location : _locationController.text.trim(),
      age: age,
      pronouns: _selectedPronouns,
      languages: _selectedLanguages,
      updatedAt: DateTime.now(),
    );
    await UserService().saveUser(updated);
    if (!mounted) return;
    context.read<AppProvider>().setCurrentUser(updated);
    context.go('/home/aura');
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
                'The basics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Help us personalize your experience',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.pin, size: 20)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.cake, size: 20)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedPronouns,
                decoration: const InputDecoration(
                  labelText: 'Pronouns',
                  prefixIcon: Padding(padding: EdgeInsets.all(12), child: TruLuraIcon(glyph: TruLuraGlyph.person, size: 20)),
                ),
                items: ['she/her', 'he/him', 'they/them', 'prefer not to say']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPronouns = value!),
              ),
              const SizedBox(height: 24),
              Text(
                'Languages you speak',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedLanguages.remove(lang);
                        } else {
                          _selectedLanguages.add(lang);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        lang,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              TruLuraPrimaryButton(
                onPressed: _complete,
                child: const Text('Get Started 🎉'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
