import 'package:trulura/theme.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/widgets/feed_card.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/services/post_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/screens/vent/vent_screen.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_safe_avatar.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [
    200.0,
    210.0,
    240.0,
    260.0,
    280.0,
    300.0,
    320.0,
    340.0,
    390.0
  ]) {
    testWidgets('populated Vent card fits width $width', (tester) async {
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
      final app = AppProvider();
      final experience = ExperienceModeController(appProvider: app);
      expect(
          await experience.setActiveMode(TruExperienceMode.vent,
              confirmed: true),
          isTrue);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>(create: (_) => app),
          ChangeNotifierProvider<TruLuraModeController>(
              create: (_) => TruLuraModeController(TruLuraMode.vent)),
          ChangeNotifierProvider<ExperienceModeController>(
              create: (_) => experience),
        ],
        child: MaterialApp(
            theme: darkTheme,
            home: Scaffold(
                body: SingleChildScrollView(
              child: Center(
                  child: SizedBox(width: width, child: FeedCard(post: post))),
            ))),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Anonymous share'), findsOneWidget);
      final identity = find
          .ancestor(
              of: find.text('Anonymous share'), matching: find.byType(Column))
          .first;
      final header = find
          .ancestor(of: identity, matching: find.byType(LayoutBuilder))
          .first;
      // Measure the allocated identity box, not just the absence of errors.
      if (tester.getSize(header).width < 320) {
        expect(tester.getSize(identity).width, tester.getSize(header).width);
        expect(tester.getSize(identity).width, greaterThan(130));
      }
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics && widget.properties.label == 'More'),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Semantics &&
              widget.properties.label == 'Why am I seeing this?'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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

  test('remote profile photos never use the asset loader', () {
    expect(profileImageProvider('https://example.com/photo.jpg?size=200'),
        isA<NetworkImage>());
    expect(profileImageProvider('assets/images/photo.jpg'), isA<AssetImage>());
    expect(profileImageProvider('  '), isNull);
  });

  testWidgets('state panel actions remain reachable in a short viewport',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>(create: (_) => AppProvider()),
        ChangeNotifierProvider<ExperienceModeController>(
            create: (context) => ExperienceModeController(
                appProvider: context.read<AppProvider>()))
      ],
      child: MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  height: 140,
                  child: TruStatePanel(
                    glyph: TruLuraGlyph.info,
                    title: 'Could not load',
                    message: 'Try again when ready.',
                    actions: [
                      TruStateAction(
                          label: 'Retry',
                          glyph: TruLuraGlyph.spark,
                          onTap: () => pressed = true)
                    ],
                  )))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Retry'));
    await tester.pump();
    await tester.tap(find.text('Retry'));
    expect(pressed, isTrue);
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
