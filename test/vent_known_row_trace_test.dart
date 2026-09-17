// Trace probe: one known vent_feed row through CLIENT QUERY -> MODEL -> STATE
// -> RENDER, using the real PostService and the real VentScreen.
//
// The response body and the target row id come from the environment, so no
// real post content lives in the repo:
//   VENT_TRACE_BODY  path to a JSON file holding the exact vent_feed response
//   VENT_TRACE_ID    id of the row that must survive every stage
//   VENT_TRACE_SUB   account the session is recovered as
// Skipped when they are absent.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/compat/provider_compat.dart' as p;
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/screens/vent/vent_screen.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/supabase/supabase_config.dart';
import 'package:trulura/widgets/feed_card.dart';

String _b64(Object o) =>
    base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');

void main() {
  final env = Platform.environment;
  final bodyPath = env['VENT_TRACE_BODY'];
  final targetId = env['VENT_TRACE_ID'];
  final sub = env['VENT_TRACE_SUB'];
  final skip = bodyPath == null || targetId == null || sub == null;
  // VENT_TRACE_FAIL=1 makes vent_feed answer 500, to see which panel a failed
  // load produces. The row-survival tests are skipped in that mode.
  final failMode = env['VENT_TRACE_FAIL'] == '1';
  final requests = <String>[];
  final logs = <String>[];

  setUpAll(() async {
    if (skip) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final body = File(bodyPath).readAsStringSync();
    final client = MockClient((http.Request req) async {
      requests.add('${req.method} ${req.url.path}');
      if (req.url.path == '/rest/v1/vent_feed' && failMode) {
        return http.Response(
            '{"code":"XX000","message":"probe failure","details":null,"hint":null}',
            500,
            request: req,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      if (req.url.path == '/rest/v1/vent_feed') {
        final n = (jsonDecode(body) as List).length;
        // postgrest reads response.request!, so every mock response carries it.
        return http.Response(body, 200, request: req, headers: {
          'content-type': 'application/json; charset=utf-8',
          'content-range': '0-${n - 1}/*',
        });
      }
      if (req.url.path.startsWith('/rest/v1/')) {
        return http.Response('[]', 200,
            request: req,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return http.Response('{}', 200,
          request: req, headers: {'content-type': 'application/json'});
    });
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.anonKey,
      httpClient: client,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    // Supabase is already initialized, so this only flips the service flag;
    // the app's own client is the mock-backed one above.
    await DatabaseService.instance.initialize();
    final token = '${_b64({
          'alg': 'HS256',
          'typ': 'JWT'
        })}.${_b64({
          'sub': sub,
          'role': 'authenticated',
          'aud': 'authenticated',
          'exp': 4102444800,
        })}.sig';
    await Supabase.instance.client.auth.recoverSession(jsonEncode({
      'access_token': token,
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': sub,
        'aud': 'authenticated',
        'role': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
      },
    }));
  });

  test('B: client query returns the row', () async {
    final rows = await PostService().fetchVentFeed();
    // ignore: avoid_print
    print('TRACE B rows=${rows.length} ids=${rows.map((r) => r['id']).toList()}');
    expect(rows.any((r) => r['id'] == targetId), isTrue);
  }, skip: skip || failMode);

  test('MODEL: getPostsByCategory keeps the row', () async {
    final posts = await PostService().getPostsByCategory('Vent');
    final hit = posts.where((x) => x.id == targetId).toList();
    // ignore: avoid_print
    print('TRACE MODEL posts=${posts.length} hit=${hit.length} '
        '${hit.isEmpty ? '' : 'category=${hit.first.category} anon=${hit.first.isAnonymous} privacy=${hit.first.privacy}'}');
    expect(hit, hasLength(1));
  }, skip: skip || failMode);

  for (final size in [const Size(390, 844), const Size(1333, 650)]) {
    testWidgets('STATE+RENDER: VentScreen paints the row at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // Let the binding capture exceptions and read them back. Overriding
      // FlutterError.onError swallowed a render exception at HEAD and made
      // the binding assert, which hid the very thing being traced.
      final errors = <String>[];
      void drain() {
        for (var e = tester.takeException();
            e != null;
            e = tester.takeException()) {
          errors.add(e.toString().split('\n').take(3).join(' | '));
        }
      }
      final prevPrint = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) {
        if (m != null) logs.add(m);
      };
      addTearDown(() => debugPrint = prevPrint);

      final router = GoRouter(initialLocation: '/vent', routes: [
        GoRoute(path: '/vent', builder: (_, __) => const VentScreen()),
      ]);
      addTearDown(router.dispose);
      final app = AppProvider();
      await tester.pumpWidget(p.MultiProvider(
        providers: [
          p.ChangeNotifierProvider<AppProvider>(create: (_) => app),
          p.ChangeNotifierProvider<TruLuraModeController>(
              create: (_) => TruLuraModeController(TruLuraMode.vent)),
          p.ChangeNotifierProvider<ExperienceModeController>(
              create: (_) => ExperienceModeController(appProvider: app)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
        drain();
      }

      String ladder() {
        if (find
            .byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_VentSkeleton')
            .evaluate()
            .isNotEmpty) {
          return 'loading skeleton';
        }
        if (find.text('Vent Space couldn’t load').evaluate().isNotEmpty) {
          return 'error panel';
        }
        if (find.text('Vent Space is quiet').evaluate().isNotEmpty) {
          return 'empty panel';
        }
        if (find.text('No posts in this support circle').evaluate().isNotEmpty) {
          return 'filtered-empty panel';
        }
        return 'list';
      }

      final cards = find.byType(FeedCard, skipOffstage: false);
      final target = find.byWidgetPredicate(
          (w) => w is FeedCard && w.post.id == targetId,
          skipOffstage: false);
      // ignore: avoid_print
      print('TRACE STATE size=$size ladder=${ladder()} '
          'feedCards=${cards.evaluate().length} target=${target.evaluate().length}');
      if (target.evaluate().isEmpty) {
        debugPrint = prevPrint;
        // ignore: avoid_print
        print('TRACE errors=${errors.length} ${errors.take(3).toList()}');
        // ignore: avoid_print
        print('TRACE logs=${logs.where((l) => l.contains('Vent')).toList()}');
      }

      expect(target, findsOneWidget, reason: 'row lost before RENDER');

      final vertical = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      await tester.scrollUntilVisible(target, 200,
          scrollable: vertical.first, maxScrolls: 60);
      await tester.pump(const Duration(milliseconds: 300));
      drain();
      final rect = tester.getRect(target);
      final viewport = Offset.zero & size;
      final painted = find.descendant(
          of: target, matching: find.byType(Text), skipOffstage: true);
      // ignore: avoid_print
      print('TRACE RENDER size=$size rect=$rect onScreen=${viewport.overlaps(rect)} '
          'textWidgets=${painted.evaluate().length} hitTestable=${target.hitTestable().evaluate().length}');
      // ignore: avoid_print
      print('TRACE errors=${errors.length} ${errors.take(3).toList()}');
      // ignore: avoid_print
      print('TRACE logs=${logs.where((l) => l.contains('Vent')).toList()}');
      debugPrint = prevPrint;

      expect(rect.height, greaterThan(0));
      expect(viewport.overlaps(rect), isTrue);
      expect(target.hitTestable(), findsOneWidget);
      expect(errors, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }, skip: skip || failMode);
  }

  testWidgets('FAIL: a failed Vent load shows the error panel, not empty',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(initialLocation: '/vent', routes: [
      GoRoute(path: '/vent', builder: (_, __) => const VentScreen()),
    ]);
    addTearDown(router.dispose);
    final app = AppProvider();
    await tester.pumpWidget(p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider<AppProvider>(create: (_) => app),
        p.ChangeNotifierProvider<TruLuraModeController>(
            create: (_) => TruLuraModeController(TruLuraMode.vent)),
        p.ChangeNotifierProvider<ExperienceModeController>(
            create: (_) => ExperienceModeController(appProvider: app)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    final vertical = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.drag(vertical.first, const Offset(0, -1200));
    await tester.pump(const Duration(milliseconds: 300));
    final error =
        find.text('Vent Space couldn’t load', skipOffstage: false).evaluate();
    final quiet =
        find.text('Vent Space is quiet', skipOffstage: false).evaluate();
    // ignore: avoid_print
    print('TRACE FAIL errorPanel=${error.length} quietPanel=${quiet.length} '
        'feedCards=${find.byType(FeedCard, skipOffstage: false).evaluate().length}');
    expect(error, hasLength(1));
    expect(quiet, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }, skip: skip || !failMode);

  tearDownAll(() {
    // ignore: avoid_print
    print('TRACE requests=$requests');
  });
}
