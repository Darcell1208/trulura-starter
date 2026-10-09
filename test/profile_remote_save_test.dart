import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:trulura/models/user.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/providers/app_provider.dart';

const member = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
String b64(Object value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
Map<String, dynamic> authUser(String id,
        [Map<String, dynamic> metadata = const {}]) =>
    {
      'id': id,
      'aud': 'authenticated',
      'role': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': <String, dynamic>{},
      'user_metadata': metadata,
    };
Future<void> session(String id) =>
    sb.Supabase.instance.client.auth.recoverSession(jsonEncode({
      'access_token': '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64({
            'sub': id,
            'role': 'authenticated',
            'exp': 4102444800
          })}.test',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': authUser(id),
    }));
http.Response response(http.Request request, Object? body,
        [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        request: request, headers: {'content-type': 'application/json'});
User baseline() => User.fromJson(
        {'id': member, 'name': 'Member', 'username': 'member', 'age': 25})
    .markHydrated();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) handler;
  final requests = <http.Request>[];
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await sb.Supabase.initialize(
      url: 'https://trulura-tests.invalid',
      anonKey: 'test-key',
      debug: false,
      httpClient: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
      authOptions: const sb.FlutterAuthClientOptions(
        localStorage: sb.EmptyLocalStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
    await DatabaseService.instance.initialize();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    handler = (request) async => response(request, [
          {'id': member}
        ]);
    await session(member);
  });
  tearDownAll(() async => sb.Supabase.instance.dispose());

  Future<void> expectNoSuccessCache() async {
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('current_user:$member'), isFalse);
    expect(prefs.containsKey('current_user:$other'), isFalse);
  }

  test('birthday save sends date and confirms the returned account receipt', () async {
    handler = (request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['data']['trulura_birth_date'], '2000-01-15');
      return response(request, authUser(member, Map<String, dynamic>.from(body['data'])));
    };
    await UserService().saveAccountBirthday(member, '2000-01-15');
  });
  test('birthday save rejects a missing receipt', () async {
    handler = (request) async => response(request, authUser(member));
    await expectLater(UserService().saveAccountBirthday(member, '2000-01-15'), throwsStateError);
  });
  test('birthday save rejects the wrong signed-in account before sending', () async {
    await expectLater(UserService().saveAccountBirthday(other, '2000-01-15'), throwsStateError);
    expect(requests, isEmpty);
  });
  test('birthday save surfaces backend rejection', () async {
    handler = (request) async => response(request, {'message': 'Denied'}, 403);
    await expectLater(UserService().saveAccountBirthday(member, '2000-01-15'), throwsA(isA<sb.AuthException>()));
  });
  test('backend rejection surfaces and does not cache an unsaved profile',
      () async {
    handler = (request) async =>
        response(request, {'code': '42501', 'message': 'Denied'}, 403);
    await expectLater(
        UserService().saveUser(baseline().copyWith(bio: 'new bio'),
            requireRemoteSuccess: true),
        throwsA(isA<sb.PostgrestException>()));
    await expectNoSuccessCache();
  });
  test('zero-row base profile receipt is not a successful save', () async {
    handler = (request) async => response(request, []);
    await expectLater(
        UserService().saveUser(baseline().copyWith(bio: 'new bio'),
            requireRemoteSuccess: true),
        throwsStateError);
    await expectNoSuccessCache();
  });
  test('optional selected field missing from schema surfaces', () async {
    handler = (request) async => response(
        request,
        {'code': 'PGRST204', 'message': 'Could not find social_preference'},
        400);
    await expectLater(
        UserService().saveUser(
            baseline().copyWith(socialPreference: 'Balanced energy'),
            requireRemoteSuccess: true),
        throwsA(isA<sb.PostgrestException>()));
    await expectNoSuccessCache();
  });
  test('zero-row optional field receipt is not success', () async {
    handler = (request) async => response(request, []);
    await expectLater(
        UserService().saveUser(
            baseline().copyWith(socialPreference: 'Balanced energy'),
            requireRemoteSuccess: true),
        throwsStateError);
    await expectNoSuccessCache();
  });
  test('failed preference read never overwrites unread preferences', () async {
    handler = (request) async =>
        response(request, {'code': '42501', 'message': 'Denied'}, 403);
    await expectLater(
        UserService().saveUser(baseline().copyWith(interests: ['Music']),
            requireRemoteSuccess: true),
        throwsA(isA<sb.PostgrestException>()));
    expect(requests.where((r) => r.method != 'GET'), isEmpty);
    await expectNoSuccessCache();
  });
  test('zero-row temperament receipt is not success', () async {
    handler = (request) async => response(request, []);
    await expectLater(
        UserService().saveUser(
            baseline().copyWith(temperament: TruTemperament.grounded),
            requireRemoteSuccess: true),
        throwsStateError);
  });
  test('zero-row Vibe receipt is not success', () async {
    handler = (request) async => response(request, []);
    await expectLater(
        UserService().saveUser(baseline().copyWith(moodTags: ['Dreamy']),
            requireRemoteSuccess: true),
        throwsStateError);
  });
  test('confirmed base profile write caches saved own account', () async {
    await UserService().saveUser(baseline().copyWith(bio: 'saved bio'),
        requireRemoteSuccess: true);
    final prefs = await SharedPreferences.getInstance();
    final cached = jsonDecode(prefs.getString('current_user:$member')!) as Map;
    expect(cached['bio'], 'saved bio');
    expect(cached['id'], member);
  });
  test('account change during write never caches data into next account',
      () async {
    handler = (request) async {
      await session(other);
      return response(request, [
        {'id': member}
      ]);
    };
    await expectLater(
        UserService().saveUser(baseline().copyWith(bio: 'old account'),
            requireRemoteSuccess: true),
        throwsStateError);
    await expectNoSuccessCache();
  });
  test('account change during hydration discards the old response', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    handler = (request) async {
      if (request.url.path.endsWith('/profiles')) {
        started.complete();
        await release.future;
        return response(request, {'id': member, 'display_name': 'Old account'});
      }
      return response(request, null);
    };
    final loading = UserService().getCurrentUser();
    await started.future;
    await session(other);
    release.complete();
    expect(await loading, isNull);
    await expectNoSuccessCache();
  });
  test('old app refresh cannot replace a newly selected account', () async {
    final app = AppProvider();
    addTearDown(app.dispose);
    final started = Completer<void>();
    final release = Completer<void>();
    handler = (request) async {
      if (request.url.path.endsWith('/profiles')) {
        if (!started.isCompleted) started.complete();
        await release.future;
        return response(request, {'id': member, 'display_name': 'Old account'});
      }
      return response(request, null);
    };
    final loading = app.refreshCurrentUserFromSupabase();
    await started.future;
    await session(other);
    app.setCurrentUser(User.fromJson({'id': other, 'age': 18}));
    release.complete();
    await loading;
    expect(app.currentUser?.id, other);
  });
}
