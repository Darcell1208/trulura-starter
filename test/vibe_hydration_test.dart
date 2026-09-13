import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/profile_completion_service.dart';

void main() {
  test('fresh profile Vibe reaches completion and survives cache round trip', () {
    final user = User.fromJson({'vibe': ' Dreamy '});
    expect(user.moodTags, ['Dreamy']);
    expect(User.fromJson(user.toJson()).moodTags, ['Dreamy']);
    expect(ProfileCompletionService().summarize(user).percent, 12);
  });
  test('canonical Vibe wins, including an explicitly empty value', () {
    expect(User.vibeFromJson({'vibe': 'Creative', 'moodTags': ['Dreamy']}), ['Creative']);
    for (final empty in [null, '', '  ']) {
      expect(User.vibeFromJson({'vibe': empty, 'moodTags': ['Dreamy'], 'mood_tag': 'calm'}), isEmpty);
    }
  });
  test('older Vibe names remain readable without crossing concepts', () {
    expect(User.vibeFromJson({'moodTags': ['Dreamy']}), ['Dreamy']);
    expect(User.vibeFromJson({'mood_tags': ['Creative']}), ['Creative']);
    expect(User.vibeFromJson({'mood_tag': 'calm', 'temperament': 'grounded', 'vibe_status': 'grounded'}), isEmpty);
  });
}
