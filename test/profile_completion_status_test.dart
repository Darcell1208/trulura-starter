import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/profile_completion_service.dart';

void main() {
  const scorer = ProfileCompletionService();

  test('status never claims basics the breakdown lists as missing', () {
    // The shape of two live accounts: username, vibe, intent and interests,
    // no bio. The percentage cut-offs used to label this "Basics added".
    final summary = scorer.summarize(User.fromJson({
      'username': 'someone',
      'vibe': 'Dreamy',
      'intents': ['Friendship'],
      'interests': ['Music'],
    }));
    expect(summary.percent, 54);
    expect(summary.basicsComplete, isFalse);
    expect(summary.statusLabel, 'Building discovery');
  });

  test('labels follow the section checks', () {
    expect(scorer.summarize(User.fromJson({})).statusLabel, 'Just started');
    expect(
      scorer.summarize(User.fromJson({'username': 'a', 'bio': 'b'})).statusLabel,
      'Basics added',
    );
  });

  test('a discovery-ready profile is Strong and meaningful at its minimum', () {
    final summary = scorer.summarize(User.fromJson({
      'username': 'a',
      'bio': 'b',
      'profileImage': 'https://example.com/a.png',
      'vibe': 'Calm',
      'interests': ['Music'],
      'intents': ['Social'],
      'expressionShortPost': 'hello',
    }));
    expect(summary.discoveryReady, isTrue);
    expect(summary.percent, 90);
    expect(summary.statusLabel, 'Strong profile');
    expect(summary.hasMeaningfulProfile, isTrue);
  });
}
