import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/services/user_service.dart';

/// Build Status known issue 17: the cached current user lived under one
/// device-global SharedPreferences key, so the next account to sign in on a
/// shared device inherited the previous account's privacy controls.
///
/// Supabase is not initialised under test, so `_cacheScope` resolves to
/// 'local' — which is what makes the logout test meaningful: it proves signing
/// out of one scope leaves another account's record alone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the legacy device-global cache is deleted, never migrated', () async {
    SharedPreferences.setMockInitialValues({
      // A record from some earlier account. There is no way to know whose.
      'current_user': '{"id":"account-A","name":"A"}',
      'current_user:account-B': '{"id":"account-B","name":"B"}',
    });

    await UserService().clearAllCachedAccounts();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.containsKey('current_user'), isFalse,
        reason: 'the device-global key must be removed. Migrating it to the '
            'current account is the defect, not the fix: the value belongs to '
            'an account this device can no longer identify.');
    expect(prefs.containsKey('current_user:account-B'), isFalse,
        reason: 'clearAllCachedAccounts clears every account on the device');
  });

  test('signing out of one account leaves another account untouched', () async {
    SharedPreferences.setMockInitialValues({
      'current_user:local': '{"id":"","name":"stub"}',
      'current_user:account-B': '{"id":"account-B","name":"B"}',
    });

    await UserService().logout();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.containsKey('current_user:local'), isFalse,
        reason: 'logout clears the scope it is signing out of');
    expect(prefs.containsKey('current_user:account-B'), isTrue,
        reason: 'and only that scope. Before this change there was a single '
            'key, so any sign-out path touched whatever the device held.');
  });

  test('logout also removes a legacy key if one survives', () async {
    SharedPreferences.setMockInitialValues({
      'current_user': '{"id":"account-A","name":"A"}',
    });

    await UserService().logout();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.containsKey('current_user'), isFalse);
  });

  test('no code path reads the device-global key', () {
    final source = File('lib/services/user_service.dart').readAsStringSync();

    // Structural, and narrow on purpose: the legacy key may only be tested for
    // and removed. The moment something reads it, the inheritance bug is back
    // regardless of how the per-account keys are written.
    expect(source.contains('getString(_legacyCurrentUserKey)'), isFalse,
        reason: 'the legacy device-global key must never be read');
    expect(source.contains('setString(_legacyCurrentUserKey'), isFalse,
        reason: 'and never written');
    expect(source.contains('_currentUserKeyFor('), isTrue,
        reason: 'reads and writes go through the per-account key');
  });
}
