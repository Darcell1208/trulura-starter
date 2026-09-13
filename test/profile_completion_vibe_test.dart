import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/profile_completion_service.dart';

void main() {
  const scorer = ProfileCompletionService();

  test('a non-default temperament is not evidence of Vibe', () {
    for (final temperament in TruTemperament.values) {
      final user = User.fromJson({'temperament': temperament.name});
      final summary = scorer.summarize(user);
      expect(summary.percent, 0, reason: temperament.name);
      expect(summary.identityComplete, isFalse, reason: temperament.name);
      expect(scorer.remainingGuidedFields(user, maxItems: 10), contains('vibe'));
    }
  });

  test('a vibe scores the same whatever the temperament', () {
    for (final temperament in TruTemperament.values) {
      final user =
          User.fromJson({'vibe': 'Dreamy', 'temperament': temperament.name});
      expect(scorer.summarize(user).percent, 12, reason: temperament.name);
    }
  });
}
