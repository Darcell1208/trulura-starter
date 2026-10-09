import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/services/user_service.dart';

void main() {
  test('birthday age changes on the birthday, not at the start of the year', () {
    final data = {'trulura_birth_date': '2008-10-09', 'trulura_age': 30};
    expect(UserService.accountAge(data, today: DateTime(2026, 10, 8)), 17);
    expect(UserService.accountAge(data, today: DateTime(2026, 10, 9)), 18);
    expect(UserService.accountAge(data, today: DateTime(2026, 10, 10)), 18);
  });
  test('invalid birthday cannot fall back to a conflicting adult age', () {
    for (final birth in [null, '', '2008-02-30', '2008-13-01', '2008-1-1', 2008, '2030-01-01']) {
      expect(UserService.accountAge({'trulura_birth_date': birth, 'trulura_age': 30},
        today: DateTime(2026, 10, 9)), 0);
    }
  });
  test('legacy age remains supported only when birthday is absent', () {
    expect(UserService.accountAge({'trulura_age': 25}), 25);
    expect(UserService.accountAge({'trulura_age': '25'}), 0);
    expect(UserService.accountAge(null), 0);
  });
}
