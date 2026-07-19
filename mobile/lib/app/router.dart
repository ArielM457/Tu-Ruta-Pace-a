import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_providers.dart';
import '../modules/auth/presentation/screens/login_screen.dart';
import '../modules/auth/presentation/screens/register_screen.dart';
import '../modules/auth/presentation/screens/welcome_screen.dart';
import '../modules/profile/presentation/screens/preferences_onboarding_screen.dart';
import '../modules/profile/presentation/screens/profile_screen.dart';
import '../modules/routing/presentation/screens/home_map_screen.dart';
import '../modules/routing/presentation/screens/route_detail_screen.dart';
import '../modules/emergency/presentation/screens/emergency_screen.dart';
import '../modules/assistant/presentation/screens/chat_screen.dart';
import '../modules/community/presentation/screens/community_screen.dart';
import '../modules/community/presentation/screens/pending_questions_screen.dart';
import '../modules/government/presentation/screens/government_screen.dart';
import '../modules/routing/presentation/screens/route_options_screen.dart';

abstract final class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String preferencesOnboarding = '/onboarding/preferences';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String routeOptions = '/route-options';
  static const String routeDetail = '/route-detail';
  static const String emergency = '/emergency';
  static const String assistant = '/assistant';
  static const String community = '/community';
  static const String pendingQuestions = '/community/pending';
  static const String government = '/government';
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
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
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
        path: AppRoutes.emergency,
        builder: (context, state) => const EmergencyScreen(),
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
        path: AppRoutes.government,
        builder: (context, state) => const GovernmentScreen(),
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
