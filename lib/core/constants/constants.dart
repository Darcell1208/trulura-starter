/// Central export for app-wide constants.
///
/// Note: today most constants live in `theme.dart` and `nav.dart`.
/// This file is intentionally small so we can migrate incrementally
/// without breaking existing imports.
library;
export 'package:trulura/core/navigation/app_router.dart' show AppRoutes;
export 'package:trulura/trulura_mode.dart';