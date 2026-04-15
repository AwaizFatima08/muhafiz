import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/security_manager/screens/manager_dashboard.dart';
import '../features/security_supervisor/screens/supervisor_dashboard.dart';
import '../features/gate_clerk/screens/clerk_dashboard.dart';
import '../features/employer/screens/employer_dashboard.dart';
import '../features/security_supervisor/screens/worker_registration_screen.dart';
import '../core/enums/app_enums.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userModelAsync = ref.watch(currentUserModelProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoadingAuth = authState.isLoading;
      final isLoadingUser = userModelAsync.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      // Wait for both streams to settle
      if (isLoadingAuth || (isLoggedIn && isLoadingUser)) return null;

      // Not logged in — always go to login
      if (!isLoggedIn) return isLoginRoute ? null : '/login';

      // Logged in but on login screen — send to correct dashboard
      if (isLoginRoute) {
        final user = userModelAsync.valueOrNull;
        if (user == null) return null; // user doc missing, stay put
        switch (user.role) {
          case UserRole.securityManager:
          case UserRole.superAdmin:
            return '/manager';
          case UserRole.securitySupervisor:
            return '/supervisor';
          case UserRole.gateClerk:
            return '/clerk';
          case UserRole.employer:
            return '/employer';
          case UserRole.worker:
            return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboard(),
      ),
      GoRoute(
        path: '/supervisor',
        builder: (context, state) => const SupervisorDashboard(),
      ),
      GoRoute(
        path: '/clerk',
        builder: (context, state) => const ClerkDashboard(),
      ),
      GoRoute(
        path: '/employer',
        builder: (context, state) => const EmployerDashboard(),
      ),
      GoRoute(
        path: '/register-worker',
        builder: (context, state) => const WorkerRegistrationScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: \${state.matchedLocation}'),
      ),
    ),
  );
});
