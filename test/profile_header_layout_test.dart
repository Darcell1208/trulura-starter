import 'package:flutter/material.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/widgets/trulura_profile_hero_card.dart';

void main() {
  for (final width in [320.0, 900.0]) {
    testWidgets('Profile header fits $width with enlarged text and actions', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final app = AppProvider();
      await app.setAppearanceMode('light');
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var edits = 0;
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AppProvider>.value(value: app),
        ChangeNotifierProvider<AuraStateController>.value(value: AuraStateController()),
      ], child: MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: Size(width, 1600), textScaler: const TextScaler.linear(1.5)),
        child: Scaffold(body: SingleChildScrollView(child: TruluraProfileHeroCard(
          name: 'Darcell', handle: '@darcell', bio: 'A personal space for creativity and connection.',
          avatarPath: '', auraStrength: 70, onOpenSettings: () {}, onEditProfile: () => edits++,
        ))),
      ))));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Edit Profile'));
      await tester.tap(find.text('Edit Profile'));
      expect(edits, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    });
  }
}

