import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/experience/experience_mode.dart';

void main() {
  for (final age in [0, 17, 18, 25]) {
    for (final invited in [false, true]) {
      for (final paid in [false, true]) {
        for (final verified in [false, true]) {
          test('Luxe age=$age invite=$invited paid=$paid verified=$verified',
              () {
            final user = User.fromJson({
              'id': 'member',
              'age': age,
            }).copyWith(
                verificationLevel: verified
                    ? TruVerificationLevel.level2
                    : TruVerificationLevel.level0);
            final lock = TruExperienceMode.luxe.lockStatus(
              user: user,
              creatorOnboardingComplete: false,
              creatorApproved: false,
              hasAdvancedVerification: verified,
              hasLuxeInvite: invited,
              hasLuxeSubscription: paid,
            );
            expect(lock.locked, !(age >= 18 && (invited || paid) && verified));
          });
        }
      }
    }
  }
  test('Missing account cannot qualify for Luxe', () {
    final lock = TruExperienceMode.luxe.lockStatus(
      user: null,
      creatorOnboardingComplete: false,
      creatorApproved: false,
      hasAdvancedVerification: true,
      hasLuxeInvite: true,
      hasLuxeSubscription: true,
    );
    expect(lock.locked, isTrue);
  });
  test('Luxe safety restriction applies to either entry route', () {
    final user = User.fromJson({'id': 'member', 'age': 25}).copyWith(
      verificationLevel: TruVerificationLevel.level2,
      riskLevel: TruRiskLevel.high,
    );
    final lock = TruExperienceMode.luxe.lockStatus(
      user: user,
      creatorOnboardingComplete: false,
      creatorApproved: false,
      hasAdvancedVerification: true,
      hasLuxeInvite: true,
      hasLuxeSubscription: true,
    );
    expect(lock.locked, isTrue);
  });
}
