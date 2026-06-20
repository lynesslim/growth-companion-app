import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/growth_drop.dart';
import '../domain/models/user.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/home/home_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/focus/weekly_focus_screen.dart';
import '../features/books/book_flip_screen.dart';
import '../features/books/congrats_screen.dart';
import '../features/books/streak_complete_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/social/friend_profile_screen.dart';
import '../features/social/social_screen.dart';
import '../features/onboarding/invite_landing_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(userProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userState = ref.read(userProvider);
      
      if (authState.isLoading || userState.isLoading) return null;
      
      final isAuthenticated = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';
      
      if (!isAuthenticated && !isLoginRoute && state.matchedLocation != '/invite') return '/login';
      
      if (isAuthenticated) {
        final user = userState.valueOrNull;
        final needsOnboarding = user == null || user.onboardingProfile.isEmpty;
        final onboardingRoutes = [
          '/onboarding',
          '/weekly-focus',
        ];
        final isCurrentlyOnboarding = onboardingRoutes.contains(state.matchedLocation) ||
            state.matchedLocation == '/congrats' ||
            state.matchedLocation == '/book' ||
            state.matchedLocation == '/streak';
        
        if (needsOnboarding && !isCurrentlyOnboarding) {
          return '/onboarding';
        }

        final strictOnboardingRoutes = [
          '/onboarding',
        ];
        
        if (!needsOnboarding && strictOnboardingRoutes.contains(state.matchedLocation)) {
          return '/';
        }
        
        if (!needsOnboarding && isLoginRoute) {
          return '/';
        }
        
        if (isLoginRoute) {
          return '/';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/invite',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => InviteLandingScreen(
          senderId: state.uri.queryParameters['sender'] ?? '',
        ),
      ),
      // Phase 2 flow: Onboarding -> Weekly Focus -> Books -> Congrats -> Home
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/weekly-focus',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeeklyFocusScreen(),
      ),
      GoRoute(
        path: '/book',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          GrowthDrop? book;
          if (extra is GrowthDrop) book = extra;
          else if (extra is Map) book = GrowthDrop.fromJson(Map<String, dynamic>.from(extra));
          return BookFlipScreen(book: book);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/streak',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          GrowthDrop? book;
          if (extra is GrowthDrop) book = extra;
          else if (extra is Map) book = GrowthDrop.fromJson(Map<String, dynamic>.from(extra));
          return StreakCompleteScreen(book: book);
        },
      ),
      GoRoute(
        path: '/friend-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FriendProfileScreen(profile: state.extra as User),
      ),
      GoRoute(
        path: '/congrats',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CongratsScreen(),
      ),
      // Dashboard shell with bottom nav (landing after onboarding)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
