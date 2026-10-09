import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/features/onboarding/account_age_screen.dart';

void main() {
  testWidgets('Missing birthday stays on completion screen with a useful error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountAgeScreen()));
    await tester.tap(find.text('Save and continue'));
    await tester.pump();
    expect(find.text('Enter a valid birthday (YYYY-MM-DD).'), findsOneWidget);
    expect(find.byType(AccountAgeScreen), findsOneWidget);
    expect(find.text('Saving…'), findsNothing);
  });

  testWidgets('Invalid dates cannot bypass birthday completion', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountAgeScreen()));
    for (final input in ['0', 'abc', '2008-02-30', '2999-01-01']) {
      await tester.enterText(find.byType(TextField), input);
      await tester.tap(find.text('Save and continue'));
      await tester.pump();
      expect(find.text('Enter a valid birthday (YYYY-MM-DD).'), findsOneWidget);
      expect(find.text('Saving…'), findsNothing);
    }
  });
}
