import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/screens/splash_screen.dart';
import 'package:trulura/features/auth/sign_in_screen.dart';
import 'package:trulura/features/auth/sign_up_screen.dart';
import 'package:trulura/features/onboarding/onboarding_intent_screen.dart';
import 'package:trulura/features/onboarding/onboarding_identity_setup_screen.dart';
import 'package:trulura/features/onboarding/onboarding_vibe_screen.dart';
import 'package:trulura/features/onboarding/onboarding_interests_screen.dart';
import 'package:trulura/features/onboarding/profile_setup_screen.dart';
import 'package:trulura/screens/quiz/micro_quiz_screen.dart';
import 'package:trulura/screens/main_shell.dart';
import 'package:trulura/screens/chat/chat_list_screen.dart';
import 'package:trulura/screens/chat/chat_thread_screen.dart';
import 'package:trulura/screens/home/home_hub_screen.dart';
import 'package:trulura/screens/settings/settings_screen.dart';
import 'package:trulura/screens/settings/privacy_settings_screen.dart';
import 'package:trulura/screens/settings/identity_core_screen.dart';
import 'package:trulura/screens/settings/safety_verification_screen.dart';
import 'package:trulura/screens/settings/safety_center_screen.dart';
import 'package:trulura/screens/settings/blocked_users_screen.dart';
import 'package:trulura/screens/settings/report_screen.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/screens/settings/experience_modes_screen.dart';
import 'package:trulura/screens/settings/feed_personalization_screen.dart';
import 'package:trulura/screens/vent/vent_screen.dart';
import 'package:trulura/screens/post/create_post_screen.dart';
import 'package:trulura/screens/accessibility/accessibility_screen.dart';
import 'package:trulura/screens/live/live_hub_screen.dart';
import 'package:trulura/screens/pre_auth/soft_mode_gate_screen.dart';
import 'package:trulura/screens/placeholder/placeholder_screen.dart';
import 'package:trulura/screens/trustudio/trustudio_screen.dart';
import 'package:trulura/screens/profile/profile_screen.dart' as profile;
import 'package:trulura/screens/ai/ai_companion_screen.dart';
import 'package:trulura/screens/notifications/notifications_screen.dart';
import 'package:trulura/screens/sync/matchroom_screen.dart';
import 'package:trulura/services/user_service.dart';

class AppRouter {
  static GoRouter createRouter({required AppProvider appProvider}) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: appProvider,
      redirect: (context, state) async {
        final location = state.uri.toString();

        // If we have no in-memory user yet, attempt to hydrate from storage.
        // (This supports deep links immediately after launch.)
        if (appProvider.currentUser == null && appProvider.initialized) {
          try {
            final u = await UserService().getCurrentUser();
            if (u != null) appProvider.setCurrentUser(u);
          } catch (e) {
            debugPrint('Router auth hydrate failed: $e');
          }
        }

        final isAuthed = appProvider.currentUser != null;

        bool isAuthFlow(String loc) =>
            loc.startsWith('/auth') ||
            loc == AppRoutes.login ||
            loc == AppRoutes.signup;
        bool isOnboardingFlow(String loc) => loc.startsWith('/onboarding');
        bool isPublic(String loc) =>
            loc == AppRoutes.splash ||
            loc == AppRoutes.softMode ||
            isAuthFlow(loc) ||
            isOnboardingFlow(loc);

        // Legacy aliases (keep existing code working).
        if (location == AppRoutes.chat) return AppRoutes.messages;
        if (location.startsWith('${AppRoutes.chat}/')) {
          return location.replaceFirst(AppRoutes.chat, AppRoutes.messages);
        }
        if (location == AppRoutes.post) return AppRoutes.createPost;
        if (location == AppRoutes.aiCompanion) return AppRoutes.aiCompanionHub;

        // Auth guard.
        if (!isAuthed && !isPublic(location)) return AppRoutes.signIn;

        // Once authed, keep users out of auth pages.
        if (isAuthed && isAuthFlow(location)) return AppRoutes.home;

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          pageBuilder: (context, state) =>
              _page(context, state, const SplashScreen(), name: 'splash'),
        ),
        GoRoute(
          path: AppRoutes.softMode,
          name: 'soft-mode',
          pageBuilder: (context, state) => _page(
              context, state, const SoftModeGateScreen(),
              name: 'soft-mode'),
        ),

        // Auth
        GoRoute(
          path: AppRoutes.signIn,
          name: 'sign-in',
          pageBuilder: (context, state) =>
              _page(context, state, const SignInScreen(), name: 'sign-in'),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          name: 'sign-up',
          pageBuilder: (context, state) =>
              _page(context, state, const SignUpScreen(), name: 'sign-up'),
        ),

        // Legacy auth aliases
        GoRoute(
          path: AppRoutes.login,
          redirect: (_, __) => AppRoutes.signIn,
        ),
        GoRoute(
          path: AppRoutes.signup,
          redirect: (_, __) => AppRoutes.signUp,
        ),

        // Onboarding
        GoRoute(
          path: AppRoutes.onboardingIntent,
          name: 'onboarding-intent',
          pageBuilder: (context, state) => _page(
              context, state, const OnboardingIntentScreen(),
              name: 'onboarding-intent'),
        ),
        GoRoute(
          path: AppRoutes.onboardingIdentity,
          name: 'onboarding-identity',
          pageBuilder: (context, state) => _page(
              context, state, const OnboardingIdentitySetupScreen(),
              name: 'onboarding-identity'),
        ),
        GoRoute(
          path: AppRoutes.onboardingVibe,
          name: 'onboarding-vibe',
          pageBuilder: (context, state) => _page(
              context, state, const OnboardingVibeScreen(),
              name: 'onboarding-vibe'),
        ),
        GoRoute(
          path: AppRoutes.onboardingInterests,
          name: 'onboarding-interests',
          pageBuilder: (context, state) => _page(
              context, state, const OnboardingInterestsScreen(),
              name: 'onboarding-interests'),
        ),
        GoRoute(
          path: AppRoutes.microQuiz,
          name: 'micro-quiz',
          pageBuilder: (context, state) => _page(
              context, state, const MicroQuizScreen(),
              name: 'micro-quiz'),
        ),
        GoRoute(
          path: AppRoutes.onboardingProfileSetup,
          name: 'onboarding-profile-setup',
          pageBuilder: (context, state) => _page(
              context, state, const ProfileSetupScreen(),
              name: 'onboarding-profile-setup'),
        ),

        // Main app shell (bottom nav)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: 'home',
                  pageBuilder: (context, state) {
                    final tab = state.uri.queryParameters['tab'] ?? 'aura';
                    return _page(context, state, HomeHubScreen(initialTab: tab),
                        name: 'home');
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.messages,
                  name: 'messages',
                  pageBuilder: (context, state) => _page(
                      context, state, const ChatListScreen(),
                      name: 'messages'),
                  routes: [
                    GoRoute(
                      path: 'thread/:id',
                      name: 'chat-thread',
                      pageBuilder: (context, state) => _page(context, state,
                          ChatThreadScreen(chatId: state.pathParameters['id']!),
                          name: 'chat-thread'),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.notifications,
                  name: 'notifications',
                  pageBuilder: (context, state) => _page(
                      context, state, const NotificationsScreen(),
                      name: 'notifications'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: 'profile',
                  pageBuilder: (context, state) => _page(
                      context, state, const profile.ProfileScreen(),
                      name: 'profile'),
                ),
              ],
            ),
          ],
        ),

        // Legacy main-shell aliases
        GoRoute(path: AppRoutes.chat, redirect: (_, __) => AppRoutes.messages),

        // Global / non-tab routes
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) =>
              _page(context, state, const SettingsScreen(), name: 'settings'),
        ),
        GoRoute(
          path: AppRoutes.experienceModes,
          name: 'experience-modes',
          pageBuilder: (context, state) => _page(
              context, state, const ExperienceModesScreen(),
              name: 'experience-modes'),
        ),
        GoRoute(
          path: AppRoutes.privacy,
          name: 'privacy',
          pageBuilder: (context, state) => _page(
              context, state, const PrivacySettingsScreen(),
              name: 'privacy'),
        ),
        GoRoute(
          path: AppRoutes.identityCore,
          name: 'identity-core',
          pageBuilder: (context, state) => _page(
              context, state, const IdentityCoreScreen(),
              name: 'identity-core'),
        ),
        GoRoute(
          path: AppRoutes.safetyVerification,
          name: 'safety-verification',
          pageBuilder: (context, state) => _page(
              context, state, const SafetyVerificationScreen(),
              name: 'safety-verification'),
        ),
        GoRoute(
          path: AppRoutes.safetyCenter,
          name: 'safety-center',
          pageBuilder: (context, state) => _page(
              context, state, const SafetyCenterScreen(),
              name: 'safety-center'),
        ),
        GoRoute(
          path: '/safety-center',
          redirect: (_, __) => AppRoutes.safetyCenter,
        ),
        GoRoute(
          path: AppRoutes.blockedUsers,
          name: 'blocked-users',
          pageBuilder: (context, state) => _page(
              context, state, const BlockedUsersScreen(),
              name: 'blocked-users'),
        ),
        GoRoute(
          path: AppRoutes.report,
          name: 'report',
          pageBuilder: (context, state) {
            final typeRaw = state.uri.queryParameters['type'];
            final id = state.uri.queryParameters['id'] ?? '';
            final type = TruSafetyTargetTypeX.tryParse(typeRaw);
            return _page(
                context, state, ReportScreen(targetType: type, targetId: id),
                name: 'report');
          },
        ),
        GoRoute(
          path: AppRoutes.feedPersonalization,
          name: 'feed-personalization',
          pageBuilder: (context, state) => _page(
              context, state, const FeedPersonalizationScreen(),
              name: 'feed-personalization'),
        ),
        GoRoute(
          path: AppRoutes.vent,
          name: 'vent',
          pageBuilder: (context, state) =>
              _page(context, state, const VentScreen(), name: 'vent'),
        ),
        GoRoute(
          path: AppRoutes.accessibility,
          name: 'accessibility',
          pageBuilder: (context, state) => _page(
              context, state, const AccessibilityScreen(),
              name: 'accessibility'),
        ),
        GoRoute(
          path: AppRoutes.live,
          name: 'live',
          pageBuilder: (context, state) =>
              _page(context, state, const LiveHubScreen(), name: 'live'),
        ),
        GoRoute(
          path: AppRoutes.truStudio,
          name: 'trustudio',
          pageBuilder: (context, state) =>
              _page(context, state, const TruStudioScreen(), name: 'trustudio'),
        ),
        GoRoute(
          path: AppRoutes.createPost,
          name: 'create-post',
          pageBuilder: (context, state) => _page(
              context, state, const CreatePostScreen(),
              name: 'create-post'),
        ),
        GoRoute(
            path: AppRoutes.post, redirect: (_, __) => AppRoutes.createPost),
        GoRoute(
          path: AppRoutes.aiCompanionHub,
          name: 'tru-companion',
          pageBuilder: (context, state) => _page(
              context, state, const TruCompanionScreen(),
              name: 'tru-companion'),
        ),
        GoRoute(
            path: AppRoutes.aiCompanion,
            redirect: (_, __) => AppRoutes.aiCompanionHub),
        GoRoute(
          path: AppRoutes.placeholder,
          name: 'placeholder',
          pageBuilder: (context, state) {
            final title = state.uri.queryParameters['title'] ?? 'TruLura';
            final subtitle = state.uri.queryParameters['subtitle'];
            return _page(context, state,
                PlaceholderScreen(title: title, subtitle: subtitle),
                name: 'placeholder');
          },
        ),

        GoRoute(
          path: AppRoutes.matchroom,
          name: 'matchroom',
          pageBuilder: (context, state) => _page(context, state,
              MatchroomScreen(matchId: state.pathParameters['matchId']!),
              name: 'matchroom'),
        ),
      ],
    );
  }
}

Page<void> _page(BuildContext context, GoRouterState state, Widget child,
    {required String name}) {
  final app = context.read<AppProvider>();
  final softMode = app.softModeEnabled;
  final presence = app.emotionalPresenceState;
  return CustomTransitionPage(
    key: state.pageKey,
    name: name,
    child: child,
    transitionDuration: Duration(
      milliseconds: softMode
          ? 420
          : (340 * presence.silenceSpacing).clamp(280, 520).round(),
    ),
    reverseTransitionDuration: Duration(
      milliseconds: softMode
          ? 380
          : (300 * presence.silenceSpacing).clamp(240, 480).round(),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final pull = name == 'sync' || name == 'matchroom';
      final dim = name == 'vent';
      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          final blur = (1 - t) * (dim ? 16 : 10);
          final dy = (1 - t) *
              (pull
                  ? 18
                  : dim
                      ? 8
                      : 12);
          final scale = 0.985 + t * 0.015;
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: FadeTransition(
              opacity: curved,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(scale: scale, child: child),
              ),
            ),
          );
        },
      );
    },
  );
}

class AppRoutes {
  static const String splash = '/';
  static const String softMode = '/soft-mode';
  // Auth (new)
  static const String auth = '/auth';
  static const String signIn = '/auth/sign_in';
  static const String signUp = '/auth/sign_up';

  // Auth (legacy)
  static const String login = '/login';
  static const String signup = '/signup';

  static const String onboardingIntent = '/onboarding/intent';
  static const String onboardingIdentity = '/onboarding/identity';
  static const String onboardingVibe = '/onboarding/vibe';
  static const String onboardingInterests = '/onboarding/interests';
  static const String onboardingProfileSetup = '/onboarding/profile_setup';
  static const String microQuiz = '/quiz/micro';

  // Main tabs
  static const String home = '/home';
  // Top tabs (inside Home). Kept as real routes for deep-linking.
  static const String aura = '/home/aura';
  static const String sync = '/home/sync';
  static const String explore = '/home/explore';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Legacy messages
  static const String chat = '/chat';

  static const String settings = '/settings';
  static const String experienceModes = '/settings/experience_modes';
  static const String privacy = '/settings/privacy';
  static const String identityCore = '/settings/identity';
  static const String safetyVerification = '/settings/safety';
  static const String safetyCenter = '/settings/safety_center';
  static const String blockedUsers = '/settings/blocked_users';
  static const String report = '/settings/report';
  static const String feedPersonalization = '/settings/feed_personalization';
  static const String vent = '/vent';
  static const String accessibility = '/accessibility';
  static const String live = '/live';
  static const String truStudio = '/trustudio';
  static const String createPost = '/create_post';
  static const String post = '/post';
  static const String aiCompanionHub = '/ai_companion';
  static const String aiCompanion = '/ai';
  static const String placeholder = '/p';

  static const String matchroom = '/matchroom/:matchId';

  static String homeTab(String tab) => '$home?tab=$tab';
}
