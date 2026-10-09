import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/screens/post/create_post_screen.dart';
import 'package:trulura/widgets/trulura_post_composer.dart';

void main() {
  testWidgets('unavailable database retains Vent draft and releases submit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = AppProvider();
    final modes = ExperienceModeController(appProvider: app);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const CreatePostScreen())]);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<AppProvider>.value(value: app),
      ChangeNotifierProvider<ExperienceModeController>.value(value: modes),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Vent').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, 'Keep this private draft');
    await tester.ensureVisible(find.text('Post').last);
    await tester.tap(find.text('Post').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CreatePostScreen), findsOneWidget);
    expect(find.text('Keep this private draft'), findsOneWidget);
    expect(find.text('Posted ✨'), findsNothing);
    expect(find.textContaining('Posting is unavailable right now.'), findsOneWidget);
    final composer = tester.widget<TruluraPostComposer>(find.byType(TruluraPostComposer));
    expect(composer.isPosting, isFalse);
    expect(composer.onSubmit, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    modes.dispose();
    app.dispose();
  });
}
