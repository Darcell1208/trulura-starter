import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/user_service.dart';

class AccountAgeScreen extends StatefulWidget {
  const AccountAgeScreen({super.key});
  @override
  State<AccountAgeScreen> createState() => _AccountAgeScreenState();
}

class _AccountAgeScreenState extends State<AccountAgeScreen> {
  final _birthday = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _birthday.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final birthday = _birthday.text.trim();
    final age = UserService.accountAge({'trulura_birth_date': birthday});
    if (age <= 0) {
      setState(() => _error = 'Enter a valid birthday (YYYY-MM-DD).');
      return;
    }
    final app = context.read<AppProvider>();
    final id = app.currentUser?.id;
    if (id == null) {
      context.go('/auth/sign_in');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await UserService().saveAccountBirthday(id, birthday);
      await app.refreshCurrentUserFromSupabase();
      if (!mounted) return;
      if (app.currentUser?.id != id || app.currentUser?.age != age) {
        throw StateError('Account age was not refreshed.');
      }
      context.go('/home');
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not save your birthday. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Complete your basic setup'),
            automaticallyImplyLeading: false),
        body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Your birthday is required to use TruLura.',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            const Text(
                                'TruLura is a social platform. Dating is optional and available only to people 18 and older.'),
                            const SizedBox(height: 24),
                            TextField(
                                controller: _birthday,
                                enabled: !_saving,
                                keyboardType: TextInputType.datetime,
                                decoration: InputDecoration(
                                    labelText: 'Birthday', hintText: 'YYYY-MM-DD', errorText: _error),
                                onSubmitted: (_) => _save()),
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(
                                    _saving ? 'Saving…' : 'Save and continue')),
                          ])))),
        ),
      );
}
