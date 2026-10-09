import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:trulura/models/post.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'profile_remote_save_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sent = <Map<String, dynamic>>[];
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await sb.Supabase.initialize(
      url: 'https://trulura-tests.invalid', anonKey: 'test-key', debug: false,
      httpClient: MockClient((request) async {
        sent.add(jsonDecode(request.body) as Map<String, dynamic>);
        return fixture.response(request, null, 201);
      }),
      authOptions: const sb.FlutterAuthClientOptions(
        localStorage: sb.EmptyLocalStorage(), detectSessionInUri: false,
        autoRefreshToken: false),
    );
    await DatabaseService.instance.initialize();
    await fixture.session(fixture.member);
  });
  tearDownAll(() async => sb.Supabase.instance.dispose());
  test('unknown privacy is never published publicly', () async {
    final now = DateTime.now();
    final post = Post(id: '33333333-3333-4333-8333-333333333333',
      userId: fixture.member, content: 'test only', type: 'text',
      privacy: 'unexpected', category: 'Vent', isAnonymous: true,
      createdAt: now, updatedAt: now);
    await PostService().savePost(post);
    expect(sent, hasLength(1));
    expect(sent.single['category'], 'Vent');
    expect(sent.single['post_privacy'], 'private');
    expect(sent.single['is_anonymous'], true);
  });
}
