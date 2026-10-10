import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/screens/explore/explore_screen.dart';

void main() {
  for (final width in [320.0, 800.0]) {
    testWidgets('realm labels do not overlap at $width and doubled text', (tester) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? chosen;
      final app = AppProvider();
      await tester.pumpWidget(MultiProvider(providers: [ChangeNotifierProvider<AppProvider>.value(value: app)], child: MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: Size(width,1600), textScaler: const TextScaler.linear(2)),
        child: Scaffold(body: SingleChildScrollView(child: ExploreDiscoveryMap(
          selectedCategory: '', onCategory: (value) => chosen = value,
          onOpenVent: () {}, onTune: () {},
        )))))));
      await tester.pumpAndSettle();
      const labels = ['Anime Realm','Gaming Realm','Creator Worlds','Travel Worlds','Support Spaces'];
      for (var i=0; i<labels.length; i++) {
        for (var j=i+1; j<labels.length; j++) {
          expect(tester.getRect(find.text(labels[i])).overlaps(tester.getRect(find.text(labels[j]))), isFalse);
        }
      }
      await tester.ensureVisible(find.text('Travel Worlds'));
      await tester.tap(find.text('Travel Worlds'));
      expect(chosen, 'Travel');
      expect(tester.takeException(), isNull);
    });
  }
}

