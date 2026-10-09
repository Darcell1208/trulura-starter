import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/user.dart';

ModePermissions permissions(TruExperienceMode mode, User? user) =>
    TruExperienceModePolicy.permissionsFor(
      mode: mode,
      user: user,
      creatorOnboardingComplete: true,
      creatorApproved: true,
      hasAdvancedVerification: true,
      hasLuxeInvite: true,
      hasLuxeSubscription: true,
    );

void expectBlocked(ModePermissions value) {
  expect(value.messaging, TruPermissionLevel.blocked);
  expect(value.matching, TruPermissionLevel.blocked);
  expect(value.monetization, TruPermissionLevel.blocked);
  expect(value.anonymousUse, TruPermissionLevel.blocked);
  expect(value.groups, TruPermissionLevel.blocked);
  expect(value.live, TruPermissionLevel.blocked);
  expect(value.events, TruPermissionLevel.blocked);
  expect(value.allowRomanticEscalation, isFalse);
}

void main() {
  for (final mode in [
    TruExperienceMode.dating,
    TruExperienceMode.luxe,
    TruExperienceMode.altIntimate
  ]) {
    for (final age in <int?>[null, 0, 17]) {
      test('$mode blocks every adult capability for age $age', () {
        final user = age == null
            ? null
            : User.fromJson({'id': 'member', 'age': age})
                .copyWith(verificationLevel: TruVerificationLevel.level3);
        final lock = mode.lockStatus(
            user: user,
            creatorOnboardingComplete: true,
            creatorApproved: true,
            hasAdvancedVerification: true,
            hasLuxeInvite: true,
            hasLuxeSubscription: true);
        expect(lock.locked, isTrue);
        for (final from in TruExperienceMode.values) {
          expect(
              mode
                  .transitionFrom(from: from, user: user, creatorApproved: true)
                  .type,
              TruModeTransitionType.blocked);
        }
        final direct = permissions(mode, user);
        expectBlocked(direct);
        final creator = User.fromJson({'id': 'adult', 'age': 25});
        expectBlocked(TruExperienceModePolicy.effectivePermissions(
          active: direct,
          passive: [permissions(TruExperienceMode.creator, creator)],
        ));
      });
    }
    test('$mode retains eligible adult access at age 18', () {
      final user = User.fromJson({'id': 'adult', 'age': 18})
          .copyWith(verificationLevel: TruVerificationLevel.level3);
      expect(
          mode
              .lockStatus(
                  user: user,
                  creatorOnboardingComplete: true,
                  creatorApproved: true,
                  hasAdvancedVerification: true,
                  hasLuxeInvite: true,
                  hasLuxeSubscription: true)
              .locked,
          isFalse);
      expect(
          permissions(mode, user).matching, isNot(TruPermissionLevel.blocked));
    });
  }
  test('Teen social access does not inherit the adult-only restriction', () {
    final user = User.fromJson({'id': 'teen', 'age': 17});
    expect(permissions(TruExperienceMode.social, user).messaging,
        isNot(TruPermissionLevel.blocked));
  });
}
