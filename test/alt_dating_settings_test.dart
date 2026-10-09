import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/screens/settings/experience_modes_screen.dart';
import 'package:trulura/models/experience/experience_mode.dart';

void main() {
  testWidgets('Alt settings are nested under the dating expansion', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = AppProvider();
    final modes = ExperienceModeController(appProvider: app);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const ExperienceModesScreen())]);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<AppProvider>.value(value: app),
      ChangeNotifierProvider<ExperienceModeController>.value(value: modes),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pump(const Duration(milliseconds: 300));
    final expansion = find.widgetWithText(ExpansionTile, 'Alternative dating');
    expect(expansion, findsOneWidget);
    final altCard = find.byWidgetPredicate((widget) => widget is ExperienceModeCard && widget.mode == TruExperienceMode.altIntimate);
    expect(altCard, findsNothing);
    await tester.ensureVisible(expansion);
    await tester.tap(find.text('Alternative dating'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(altCard, findsOneWidget);
    expect(find.descendant(of: expansion, matching: altCard), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    modes.dispose();
    app.dispose();
  });
}
