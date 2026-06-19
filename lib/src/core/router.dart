import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/home/home_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/companion_selection_screen.dart';
import '../features/focus/weekly_focus_screen.dart';
import '../features/onboarding/profile_created_screen.dart';
import '../features/books/action_plans_screen.dart';
import '../features/books/book_flip_screen.dart';
import '../features/books/congrats_screen.dart';
import '../features/growth/growth_drop_screen.dart';
import '../features/growth/quest_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userProvider, (_, __) => notifyListeners());
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
      
      if (!isAuthenticated && !isLoginRoute) return '/login';
      
      if (isAuthenticated) {
        final user = userState.valueOrNull;
        final needsOnboarding = user == null || user.onboardingProfile.isEmpty;
        final onboardingRoutes = [
          '/onboarding',
          '/companion-select',
          '/weekly-focus',
          '/profile-created',
        ];
        final isCurrentlyOnboarding = onboardingRoutes.contains(state.matchedLocation) ||
            state.matchedLocation == '/congrats' ||
            state.matchedLocation.startsWith('/book/');
        
        if (needsOnboarding && !isCurrentlyOnboarding) {
          return '/onboarding';
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
      // Phase 2 flow: Onboarding -> Companion -> Weekly Focus -> Books -> Congrats -> Home
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/companion-select',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CompanionSelectionScreen(),
      ),
      GoRoute(
        path: '/weekly-focus',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeeklyFocusScreen(),
      ),
      GoRoute(
        path: '/profile-created',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileCreatedScreen(),
      ),
      GoRoute(
        path: '/book/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return BookFlipScreen(bookIndex: id);
        },
      ),
      GoRoute(
        path: '/action-plans',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookIndex = int.tryParse(
                state.uri.queryParameters['bookIndex'] ?? '0',
              ) ??
              0;
          return ActionPlansScreen(bookIndex: bookIndex);
        },
      ),
      GoRoute(
        path: '/congrats',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CongratsScreen(),
      ),
      GoRoute(
        path: '/growth-drop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GrowthDropScreen(),
      ),
      GoRoute(
        path: '/quest/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return QuestDetailScreen(questId: id);
        },
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
