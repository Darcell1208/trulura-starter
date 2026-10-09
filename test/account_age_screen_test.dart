import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/features/onboarding/account_age_screen.dart';

void main() {
  testWidgets('Missing age stays on completion screen with a useful error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountAgeScreen()));
    await tester.tap(find.text('Save and continue'));
    await tester.pump();
    expect(find.text('Enter your age to continue.'), findsOneWidget);
    expect(find.byType(AccountAgeScreen), findsOneWidget);
    expect(find.text('Saving…'), findsNothing);
  });

  testWidgets('Zero and nonnumeric input cannot bypass age completion', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountAgeScreen()));
    for (final input in ['0', 'abc']) {
      await tester.enterText(find.byType(TextField), input);
      await tester.tap(find.text('Save and continue'));
      await tester.pump();
      expect(find.text('Enter your age to continue.'), findsOneWidget);
      expect(find.text('Saving…'), findsNothing);
    }
  });
}
