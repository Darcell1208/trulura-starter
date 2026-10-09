import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/services/post_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Vent cannot report success or cache content without a database', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final post = Post(id: 'offline-test', userId: 'test-member',
      content: 'private test content', type: 'text', privacy: 'private',
      category: 'Vent', isAnonymous: true, createdAt: now, updatedAt: now);
    await expectLater(PostService().savePost(post), throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
