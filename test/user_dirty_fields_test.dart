import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/user_service.dart';

User _inMemory() => User(
    id: 'u1',
    name: 'Nova',
    username: 'nova',
    email: '',
    age: 18,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a User built in memory is not hydrated, and copyWith keeps it that way',
      () {
    final user = _inMemory();
    expect(user.isHydrated, isFalse);
    expect(user.copyWith(name: 'Max').isHydrated, isFalse);
  });

  test('seeded defaults are not dirty; only fields changed since hydration are',
      () {
    final hydrated = _inMemory().markHydrated();
    // temperament oldSoul, identity mode social, trustScore 70 are all present
    // and none of them is dirty, because none was changed after the read.
    expect(hydrated.dirtyFields(), isEmpty);

    final edited = hydrated.copyWith(
        activeIdentityMode: TruIdentityMode.dating,
        updatedAt: DateTime.utc(2027));
    expect(edited.isHydrated, isTrue);
    expect(edited.dirtyFields(), {'activeIdentityMode'},
        reason: 'updatedAt is bookkeeping, not an answer');
  });

  test('list fields compare by value, not identity', () {
    final hydrated =
        _inMemory().copyWith(intents: ['Friendship']).markHydrated();
    expect(hydrated.copyWith(intents: ['Friendship']).dirtyFields(), isEmpty);
    expect(hydrated.copyWith(intents: ['Dating']).dirtyFields(), {'intents'});
  });

  test('the hydration snapshot does not survive the local cache round trip',
      () {
    final restored = User.fromJson(_inMemory().markHydrated().toJson());
    expect(restored.isHydrated, isFalse);
  });

  test('saveUser refuses an unhydrated user before touching any storage',
      () async {
    SharedPreferences.setMockInitialValues({});
    await UserService().saveUser(_inMemory().copyWith(name: 'Max'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
