import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../services/analytics_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final analyticsObserver = ref.watch(analyticsObserverProvider);

  return GoRouter(
    initialLocation: '/splash',
    observers: [analyticsObserver],
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
  );
});
