import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/features/onboarding/profile_setup_screen.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/user_service.dart';

void main() {
  test('Required remote profile save rejects unavailable backend', () async {
    SharedPreferences.setMockInitialValues({});
    final user = User.fromJson({'id': 'member', 'age': 18});
    await expectLater(
      UserService().saveUser(user, requireRemoteSuccess: true),
      throwsStateError,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('current_user:local'), isFalse);
  });
  testWidgets('Finish later cannot bypass missing required basics', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider<AppProvider>(create: (_) => AppProvider())],
      child: const MaterialApp(home: ProfileSetupScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('YYYY-MM-DD (required)'), findsOneWidget);
    expect(find.text('Your gender (required)'), findsOneWidget);
    expect(find.text('Location (optional)'), findsOneWidget);
    expect(find.text('Pronouns (optional)'), findsOneWidget);
    await tester.ensureVisible(find.text('Finish later'));
    await tester.tap(find.text('Finish later'));
    await tester.pump();
    expect(find.text('Enter your name, username, birthday and gender to continue.'), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });
}
