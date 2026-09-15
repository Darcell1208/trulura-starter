import 'package:trulura/services/post_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/screens/vent/vent_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Vent failures are not reported as an empty feed', () async {
    await expectLater(
        PostService().getPostsByCategory('Vent'), throwsStateError);
  });

  test('anonymous Vent rows map without an author or subcategory', () {
    final post = PostService().fromAuraRow({
      'id': 'post-test',
      'user_id': null,
      'content_text': 'A reflection',
      'category': 'Vent',
      'is_anonymous': true,
      'post_privacy': 'private',
      'post_type': 'text',
      'created_at': '2026-09-08T23:52:46Z',
    });
    expect(post.content, 'A reflection');
    expect(post.category, 'Vent');
    expect(post.isAnonymous, isTrue);
  });

  for (final size in [
    const Size(700, 475),
    const Size(1333, 650),
    const Size(345, 600),
    const Size(390, 600)
  ]) {
    for (final state in ['empty', 'loading', 'action']) {
      testWidgets('Vent $state scrolls without overflow at $size',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final router = GoRouter(initialLocation: '/vent?ui=$state', routes: [
          GoRoute(path: '/vent', builder: (_, __) => const VentScreen()),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<AppProvider>(create: (_) => AppProvider()),
            ChangeNotifierProvider<ExperienceModeController>(
                create: (context) => ExperienceModeController(
                    appProvider: context.read<AppProvider>()))
          ],
          child: MaterialApp.router(routerConfig: router),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.drag(
            find.byType(CustomScrollView), const Offset(0, -1200));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.text('Enter Reflection'), findsOneWidget);
        expect(tester.getTopLeft(find.byType(CustomScrollView)).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy));
      });
    }
  }
}
