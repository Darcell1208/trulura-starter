import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';

class TruNavigation {
  static const String menuLayerValue = 'side';
  static const String menuLayerParam = 'menuLayer';
  static const String menuReturnToParam = 'menuReturnTo';
  static const String openMenuParam = 'openMenu';
  static const String restoreAuraParam = 'restoreAura';

  static const Set<String> sidebarPrimaryDestinations = <String>{
    AppRoutes.home,
    AppRoutes.messages,
    AppRoutes.notifications,
    AppRoutes.profile,
  };

  static const Set<String> sidebarExtensionDestinations = <String>{
    AppRoutes.vent,
    AppRoutes.live,
    AppRoutes.truStudio,
    AppRoutes.aiCompanionHub,
    AppRoutes.aiCompanion,
    AppRoutes.placeholder,
  };

  static const Set<String> sidebarPersonalDestinations = <String>{
    AppRoutes.settings,
    AppRoutes.experienceModes,
    AppRoutes.privacy,
    AppRoutes.identityCore,
    AppRoutes.safetyVerification,
    AppRoutes.safetyCenter,
    AppRoutes.blockedUsers,
    AppRoutes.feedPersonalization,
    AppRoutes.helpSupport,
    AppRoutes.aboutTruLura,
    AppRoutes.accessibility,
  };

  static String currentRoute(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }

  static String normalizeRoute(String route) {
    return Uri.tryParse(route)?.path ?? route.split('?').first;
  }

  static String cleanMenuRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return route;
    final query = Map<String, String>.from(uri.queryParameters)
      ..remove(menuLayerParam)
      ..remove(menuReturnToParam)
      ..remove(openMenuParam)
      ..remove('returnTo')
      ..remove('menuPulse');
    return uri.replace(queryParameters: query).toString();
  }

  static String auraHomeRoute({bool openMenu = false}) {
    final uri = Uri.parse(AppRoutes.homeTab('aura'));
    final query = Map<String, String>.from(uri.queryParameters)
      ..[restoreAuraParam] = '1'
      ..['auraPulse'] = DateTime.now().microsecondsSinceEpoch.toString();
    if (openMenu) {
      query[openMenuParam] = '1';
      query['menuPulse'] = DateTime.now().microsecondsSinceEpoch.toString();
    }
    return uri.replace(queryParameters: query).toString();
  }

  static void restoreAuraAtmosphere(BuildContext context) {
    try {
      context.read<AppState>().setTab('aura');
    } catch (_) {}
    try {
      context.read<TruLuraModeController>().setMode(TruLuraMode.aura);
    } catch (_) {}
  }

  static void goHome(BuildContext context) {
    restoreAuraAtmosphere(context);
    context.go(auraHomeRoute());
  }

  static String? resolveReturnTo(BuildContext context) {
    final state = GoRouterState.of(context);
    final extra = state.extra;
    if (extra is Map) {
      final value = extra['returnTo'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    final route = state.uri.queryParameters['returnTo'];
    if (route != null && route.trim().isNotEmpty) {
      return route;
    }
    return null;
  }

  static bool isMenuLayer(BuildContext context) {
    final state = GoRouterState.of(context);
    final extra = state.extra;
    if (extra is Map && extra[menuLayerParam] == menuLayerValue) {
      return true;
    }
    return state.uri.queryParameters[menuLayerParam] == menuLayerValue;
  }

  static bool isMenuLayerRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return false;
    return uri.queryParameters[menuLayerParam] == menuLayerValue;
  }

  static String? resolveMenuReturnTo(BuildContext context) {
    final state = GoRouterState.of(context);
    final extra = state.extra;
    if (extra is Map) {
      final value = extra[menuReturnToParam];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    final route = state.uri.queryParameters[menuReturnToParam];
    if (route != null && route.trim().isNotEmpty) {
      return route;
    }
    return null;
  }

  static String inheritedReturnToOrCurrent(BuildContext context) {
    return resolveReturnTo(context) ?? currentRoute(context);
  }

  static Object withReturnTo(
    BuildContext context, {
    Map<String, dynamic>? extra,
  }) {
    final out = <String, dynamic>{
      ...?extra,
      'returnTo': cleanMenuRoute(currentRoute(context))
    };
    if (isMenuLayer(context)) {
      out[menuLayerParam] = menuLayerValue;
      out[menuReturnToParam] =
          resolveMenuReturnTo(context) ?? resolveReturnTo(context);
    }
    return out;
  }

  static String routeWithReturnTo(
    BuildContext context,
    String route, {
    bool inheritExisting = false,
  }) {
    final returnTo = cleanMenuRoute(inheritExisting
        ? inheritedReturnToOrCurrent(context)
        : currentRoute(context));
    final uri = Uri.parse(route);
    final query = Map<String, String>.from(uri.queryParameters);
    query.putIfAbsent('returnTo', () => returnTo);
    if (isMenuLayer(context)) {
      query[menuLayerParam] = menuLayerValue;
      final menuReturn =
          resolveMenuReturnTo(context) ?? resolveReturnTo(context);
      if (menuReturn != null && menuReturn.trim().isNotEmpty) {
        query[menuReturnToParam] = menuReturn;
      }
    }
    return uri.replace(queryParameters: query).toString();
  }

  static void pushWithReturnTo(
    BuildContext context,
    String route, {
    Map<String, dynamic>? extra,
  }) {
    context.push(
      routeWithReturnTo(context, route),
      extra: withReturnTo(context, extra: extra),
    );
  }

  static Object withMenuLayer(
    BuildContext context, {
    String? origin,
    Map<String, dynamic>? extra,
  }) {
    final resolvedOrigin = cleanMenuRoute(origin ?? currentRoute(context));
    return <String, dynamic>{
      ...?extra,
      'returnTo': resolvedOrigin,
      menuLayerParam: menuLayerValue,
      menuReturnToParam: resolvedOrigin,
    };
  }

  static String routeWithMenuLayer(
    BuildContext context,
    String route, {
    String? origin,
  }) {
    final resolvedOrigin = cleanMenuRoute(origin ?? currentRoute(context));
    final uri = Uri.parse(route);
    final query = Map<String, String>.from(uri.queryParameters);
    query.putIfAbsent('returnTo', () => resolvedOrigin);
    query[menuLayerParam] = menuLayerValue;
    query[menuReturnToParam] = resolvedOrigin;
    return uri.replace(queryParameters: query).toString();
  }

  static String menuReturnRoute(BuildContext context) {
    final destination = cleanMenuRoute(resolveMenuReturnTo(context) ??
        resolveReturnTo(context) ??
        auraHomeRoute());
    final uri = Uri.parse(destination);
    final restoresAura = uri.path == AppRoutes.home &&
        (uri.queryParameters['tab'] ?? 'aura') == 'aura';
    final query = Map<String, String>.from(uri.queryParameters)
      ..[openMenuParam] = '1'
      ..[restoreAuraParam] = restoresAura ? '1' : '0'
      ..['menuPulse'] = DateTime.now().microsecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query).toString();
  }

  static bool isAuraHomeRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return false;
    return uri.path == AppRoutes.home &&
        (uri.queryParameters['tab'] ?? 'aura') == 'aura';
  }

  static bool isSyncRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return false;
    return uri.path == AppRoutes.home && uri.queryParameters['tab'] == 'sync';
  }

  static bool isLuxeRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return false;
    final title = uri.queryParameters['title']?.toLowerCase() ?? '';
    return title.contains('luxe') || title.contains('truluxe');
  }

  static bool isTruTvRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return false;
    final title = uri.queryParameters['title']?.toLowerCase() ?? '';
    return title.contains('trutv') || title.contains('tru tv');
  }

  static bool isCreatorRoute(String route) {
    final normalized = normalizeRoute(route);
    if (normalized == AppRoutes.truStudio ||
        normalized == AppRoutes.createPost) {
      return true;
    }
    final uri = Uri.tryParse(route);
    final title = uri?.queryParameters['title']?.toLowerCase() ?? '';
    return title.contains('creator') || title.contains('studio');
  }

  static bool isOnboardingRoute(String route) {
    final normalized = normalizeRoute(route);
    return normalized.startsWith('/onboarding') ||
        normalized == AppRoutes.quiz ||
        normalized == AppRoutes.microQuiz ||
        normalized == AppRoutes.quizLibrary;
  }

  static bool isMessagingRoute(String route) {
    final normalized = normalizeRoute(route);
    return normalized == AppRoutes.messages ||
        normalized.startsWith('${AppRoutes.messages}/') ||
        normalized == AppRoutes.chat ||
        normalized.startsWith('${AppRoutes.chat}/');
  }

  static bool isImmersiveRoute(String route) {
    final normalized = normalizeRoute(route);
    return isSyncRoute(route) ||
        isLuxeRoute(route) ||
        isTruTvRoute(route) ||
        isMessagingRoute(route) ||
        isCreatorRoute(route) ||
        isOnboardingRoute(route) ||
        normalized == AppRoutes.live ||
        normalized == AppRoutes.matchroom ||
        normalized.startsWith('/matchroom');
  }

  static bool _preservesSecondaryExit(String route) {
    return isSyncRoute(route) || isLuxeRoute(route);
  }

  static String? _intentionalReturnTo(BuildContext context) {
    final returnTo = resolveReturnTo(context);
    if (returnTo == null || returnTo.trim().isEmpty) return null;
    if (isMenuLayerRoute(returnTo)) return returnTo;
    final clean = cleanMenuRoute(returnTo);
    return _preservesSecondaryExit(clean) ? clean : null;
  }

  static String emotionalDestinationFor(BuildContext context) {
    final current = currentRoute(context);
    final normalized = normalizeRoute(current);
    final returnTo = _intentionalReturnTo(context);

    if (normalized == AppRoutes.matchroom ||
        normalized.startsWith('/matchroom')) {
      return AppRoutes.homeTab('sync');
    }
    if (isMessagingRoute(current)) {
      return AppRoutes.messages;
    }
    if (normalized == AppRoutes.live) {
      return returnTo ?? auraHomeRoute();
    }
    if (isCreatorRoute(current)) {
      return returnTo != null && isCreatorRoute(returnTo)
          ? returnTo
          : auraHomeRoute();
    }
    if (isLuxeRoute(current)) {
      return returnTo != null && isLuxeRoute(returnTo) ? returnTo : current;
    }
    if (isTruTvRoute(current)) {
      return returnTo ?? auraHomeRoute();
    }
    if (isOnboardingRoute(current)) {
      return returnTo ?? auraHomeRoute();
    }
    if (isSyncRoute(current)) {
      return AppRoutes.homeTab('sync');
    }

    return auraHomeRoute();
  }

  static String contextualReturnOrAura(BuildContext context,
      {String? fallback}) {
    final current = currentRoute(context);
    final normalized = normalizeRoute(current);
    final returnTo = _intentionalReturnTo(context);
    if (returnTo != null && isMenuLayerRoute(returnTo)) {
      return returnTo;
    }
    if (returnTo != null &&
        isImmersiveRoute(current) &&
        _preservesSecondaryExit(returnTo)) {
      return returnTo;
    }
    if (returnTo != null &&
        normalized == AppRoutes.profile &&
        isLuxeRoute(returnTo)) {
      return returnTo;
    }
    if (fallback != null && isImmersiveRoute(fallback)) {
      return fallback;
    }
    return emotionalDestinationFor(context);
  }

  static Object withInheritedReturnTo(
    BuildContext context, {
    Map<String, dynamic>? extra,
  }) {
    return <String, dynamic>{
      ...?extra,
      'returnTo': inheritedReturnToOrCurrent(context),
    };
  }

  static void pushWithInheritedReturnTo(
    BuildContext context,
    String route, {
    Map<String, dynamic>? extra,
  }) {
    context.push(
      routeWithReturnTo(context, route, inheritExisting: true),
      extra: withInheritedReturnTo(context, extra: extra),
    );
  }

  static void goWithReturnTo(
    BuildContext context,
    String route, {
    Map<String, dynamic>? extra,
  }) {
    context.go(
      routeWithReturnTo(context, route),
      extra: withReturnTo(context, extra: extra),
    );
  }

  static String fallbackForRoute(String route) {
    final normalized = normalizeRoute(route);
    if (normalized == AppRoutes.messages ||
        normalized.startsWith('${AppRoutes.messages}/')) {
      return AppRoutes.messages;
    }
    if (normalized == AppRoutes.notifications) return auraHomeRoute();
    if (normalized == AppRoutes.profile) return auraHomeRoute();
    if (sidebarPersonalDestinations.contains(normalized)) {
      return auraHomeRoute();
    }
    if (normalized == AppRoutes.live ||
        normalized == AppRoutes.truStudio ||
        normalized == AppRoutes.createPost) {
      return route;
    }
    return auraHomeRoute();
  }

  static void pushSidebarDestination(
    BuildContext context,
    String route, {
    Map<String, dynamic>? extra,
    bool inheritExisting = false,
    bool menuLayer = false,
  }) {
    if (menuLayer) {
      final origin = inheritedReturnToOrCurrent(context);
      context.push(
        routeWithMenuLayer(context, route, origin: origin),
        extra: withMenuLayer(context, origin: origin, extra: extra),
      );
      return;
    }

    context.push(
      routeWithReturnTo(
        context,
        route,
        inheritExisting: inheritExisting,
      ),
      extra: inheritExisting
          ? withInheritedReturnTo(context, extra: extra)
          : withReturnTo(context, extra: extra),
    );
  }

  static void goBackOrReturn(
    BuildContext context, {
    String? fallback,
  }) {
    if (isMenuLayer(context)) {
      final destination = menuReturnRoute(context);
      if (isAuraHomeRoute(destination)) restoreAuraAtmosphere(context);
      context.go(destination);
      return;
    }

    final destination = contextualReturnOrAura(context, fallback: fallback);
    if (isAuraHomeRoute(destination)) restoreAuraAtmosphere(context);

    if (destination != currentRoute(context)) {
      context.go(destination);
      return;
    }

    if (context.canPop() && isImmersiveRoute(currentRoute(context))) {
      context.pop();
      return;
    }

    if (isAuraHomeRoute(destination)) {
      context.go(destination);
      return;
    }

    context.go(auraHomeRoute());
  }

  static void closeModule(
    BuildContext context, {
    String? fallback,
  }) {
    if (isMenuLayer(context)) {
      final destination = cleanMenuRoute(resolveMenuReturnTo(context) ??
          resolveReturnTo(context) ??
          auraHomeRoute());
      if (isAuraHomeRoute(destination)) restoreAuraAtmosphere(context);
      context.go(destination);
      return;
    }

    final returnTo = resolveReturnTo(context);
    if (returnTo != null && isMenuLayerRoute(returnTo)) {
      final destination = auraHomeRoute();
      restoreAuraAtmosphere(context);
      context.go(destination);
      return;
    }

    final destination = contextualReturnOrAura(context, fallback: fallback);
    if (isAuraHomeRoute(destination)) restoreAuraAtmosphere(context);
    context.go(destination);
  }
}
