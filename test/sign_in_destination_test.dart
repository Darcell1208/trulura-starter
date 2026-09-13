import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/features/auth/sign_in_destination.dart';
import 'package:trulura/models/vibe_read.dart';

void main() {
  test('a vibe read as empty asks, with Skip available', () {
    final uri = Uri.parse(signInDestination(VibeRead.empty));
    expect(uri.path, AppRoutes.onboardingVibe);
    expect(uri.queryParameters['returnTo'], AppRoutes.home);
  });

  test('a saved vibe goes Home', () {
    expect(signInDestination(VibeRead.present), AppRoutes.home);
  });

  test('a failed or missing read does not look like an empty vibe', () {
    expect(signInDestination(VibeRead.unknown), AppRoutes.home);
  });
}
