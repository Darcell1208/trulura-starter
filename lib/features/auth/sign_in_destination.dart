import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/models/vibe_read.dart';

/// Where sign-in sends a user.
///
/// Signup keeps asking for a Vibe (Product Owner ruling, 2026-09-10). Email
/// confirmation is required on this project, so a new account has no session
/// at signup and sign-in is the first real entry point.
///
/// Only a vibe that was READ and is empty asks, with Home as the return address
/// so the vibe screen offers Skip. Unknown -- a failed query, or no profiles
/// row -- goes Home unasked. Nothing is stored: "once" is the condition itself,
/// so a user who skips is asked again next sign-in, on any device.
String signInDestination(VibeRead vibe) => switch (vibe) {
      VibeRead.empty => Uri(
          path: AppRoutes.onboardingVibe,
          queryParameters: {'returnTo': AppRoutes.home},
        ).toString(),
      VibeRead.present || VibeRead.unknown => AppRoutes.home,
    };
