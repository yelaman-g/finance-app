import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_database_page.dart';
import '../../features/goals/presentation/pages/goal_detail_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/household/presentation/pages/family_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import 'router_refresh.dart';
import 'routes.dart';
import 'transitions.dart';

/// Root GoRouter.
///
/// Auth-aware: listens to [authControllerProvider] via [RouterRefreshNotifier]
/// and redirects between auth and app shells based on session state.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh =
      RouterRefreshNotifier<AuthState>(ref, authControllerProvider);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboard.path,
    refreshListenable: refresh,
    redirect: (ctx, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth');
      final isBootstrap =
          loc == AppRoutes.splash.path || loc == AppRoutes.onboarding.path;
      return switch (auth) {
        AuthUnknown() => null,
        AuthAuthenticated() =>
          (isAuthRoute || isBootstrap) ? AppRoutes.dashboard.path : null,
        AuthUnauthenticated() =>
          (isAuthRoute || isBootstrap) ? null : AppRoutes.login.path,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash.path,
        name: AppRoutes.splash.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Splash'),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding.path,
        name: AppRoutes.onboarding.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Onboarding'),
        ),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        name: AppRoutes.login.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register.path,
        name: AppRoutes.register.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard.path,
        name: AppRoutes.dashboard.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const DashboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactions.path,
        name: AppRoutes.transactions.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const TransactionsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword.path,
        name: AppRoutes.forgotPassword.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Forgot Password'),
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail.path,
        name: AppRoutes.verifyEmail.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Verify Email'),
        ),
      ),
      GoRoute(
        path: AppRoutes.analytics.path,
        name: AppRoutes.analytics.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Analytics'),
        ),
      ),
      GoRoute(
        path: AppRoutes.ai.path,
        name: AppRoutes.ai.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'AI Assistant'),
        ),
      ),
      GoRoute(
        path: AppRoutes.moments.path,
        name: AppRoutes.moments.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Moments'),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile.path,
        name: AppRoutes.profile.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Profile'),
        ),
      ),
      GoRoute(
        path: AppRoutes.admin.path,
        name: AppRoutes.admin.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const AdminDatabasePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.goals.path,
        name: AppRoutes.goals.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const GoalsPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (ctx, state) => fadeThroughPage(
              key: state.pageKey,
              child: GoalDetailPage(goalId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.family.path,
        name: AppRoutes.family.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const FamilyPage(),
        ),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Unknown route')),
    ),
  );
});

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
    );
  }
}
