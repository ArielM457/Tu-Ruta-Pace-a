import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_providers.dart';
import '../modules/assistant/presentation/screens/chat_screen.dart';
import '../modules/auth/presentation/screens/login_screen.dart';
import '../modules/auth/presentation/screens/register_screen.dart';
import '../modules/auth/presentation/screens/welcome_screen.dart';
import '../modules/community/presentation/screens/community_screen.dart';
import '../modules/community/presentation/screens/pending_questions_screen.dart';
import '../modules/complaints/presentation/screens/complaints_screen.dart';
import '../modules/complaints/presentation/screens/new_complaint_screen.dart';
import '../modules/emergency/presentation/screens/emergency_screen.dart';
import '../modules/family/presentation/screens/family_screen.dart';
import '../modules/home/presentation/screens/home_dashboard_screen.dart';
import '../modules/notifications/presentation/screens/notifications_screen.dart';
import '../modules/profile/presentation/screens/personal_info_screen.dart';
import '../modules/profile/presentation/screens/points_history_screen.dart';
import '../modules/profile/presentation/screens/preferences_onboarding_screen.dart';
import '../modules/profile/presentation/screens/preferences_screen.dart';
import '../modules/profile/presentation/screens/profile_screen.dart';
import '../modules/routing/presentation/screens/map_screen.dart';
import '../modules/routing/presentation/screens/route_detail_screen.dart';
import '../modules/routing/presentation/screens/route_options_screen.dart';
import '../modules/routing/presentation/screens/routes_planner_screen.dart';
import 'chasqui_shell.dart';

abstract final class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String preferencesOnboarding = '/onboarding/preferences';
  static const String home = '/home';
  static const String routes = '/routes';
  static const String emergency = '/emergency';
  static const String complaints = '/complaints';
  static const String newComplaint = '/complaints/new';
  static const String profile = '/profile';
  static const String personalInfo = '/profile/personal-info';
  static const String preferences = '/profile/preferences';
  static const String pointsHistory = '/profile/points-history';
  static const String map = '/map';
  static const String routeOptions = '/route-options';
  static const String routeDetail = '/route-detail';
  static const String assistant = '/assistant';
  static const String community = '/community';
  static const String pendingQuestions = '/community/pending';
  static const String family = '/family';
  static const String notifications = '/notifications';
}

const Set<String> _routesWithoutSession = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.register,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final supabaseAuth = ref.watch(supabaseClientProvider).auth;
  final sessionRefreshNotifier =
      _StreamChangeNotifier(supabaseAuth.onAuthStateChange);
  ref.onDispose(sessionRefreshNotifier.dispose);
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: sessionRefreshNotifier,
    redirect: (context, state) {
      final hasSession = supabaseAuth.currentSession != null;
      final isPublicRoute =
          _routesWithoutSession.contains(state.matchedLocation);
      if (!hasSession) {
        return isPublicRoute ? null : AppRoutes.welcome;
      }
      return isPublicRoute ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.preferencesOnboarding,
        builder: (context, state) => const PreferencesOnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ChasquiShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.routes,
                builder: (context, state) => const RoutesPlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.emergency,
                builder: (context, state) => const EmergencyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.complaints,
                builder: (context, state) => const ComplaintsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newComplaint,
        builder: (context, state) => const NewComplaintScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.preferences,
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.pointsHistory,
        builder: (context, state) => const PointsHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: AppRoutes.routeOptions,
        builder: (context, state) => const RouteOptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.routeDetail,
        builder: (context, state) => const RouteDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.assistant,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.community,
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingQuestions,
        builder: (context, state) => const PendingQuestionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.family,
        builder: (context, state) => const FamilyScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

class _StreamChangeNotifier extends ChangeNotifier {
  _StreamChangeNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
