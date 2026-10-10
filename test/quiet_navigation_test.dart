import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/widgets/trulura_bottom_nav.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';

void main() {
  testWidgets('light navigation preserves destinations and Create action', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    await app.setAppearanceMode('light');
    final mode = TruLuraModeController(TruLuraMode.aura);
    final destinations = <int>[];
    var creates = 0;
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<AppProvider>.value(value: app),
      ChangeNotifierProvider<TruLuraModeController>.value(value: mode),
    ], child: MaterialApp(theme: ThemeData.light(), home: Scaffold(
      body: const TruLuraLayeredBackground(child: Text('Content')),
      bottomNavigationBar: TruLuraBottomNav(index: 0,
        onTap: destinations.add, onPost: () => creates++),
    ))));
    for (final label in ['Connect', 'Create', 'Pulse', 'Profile', 'Worlds']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(destinations, [1, 2, 3, 0]);
    expect(creates, 1);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).backgroundColor,
      ThemeData.light().colorScheme.surface);
    final background = find.descendant(of: find.byType(TruLuraLayeredBackground), matching: find.byType(Material));
    expect(tester.widget<Material>(background).color, Colors.white);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    mode.dispose(); app.dispose();
  });
}
