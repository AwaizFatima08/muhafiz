import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/enums/app_enums.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/security_manager/screens/manager_dashboard.dart';
import '../features/security_supervisor/screens/supervisor_dashboard.dart';
import '../features/gate_clerk/screens/clerk_dashboard.dart';
import '../features/employer/screens/employer_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userModel = ref.watch(currentUserModelProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        return userModel.valueOrNull != null
            ? _roleRoute(userModel.valueOrNull!.role)
            : '/login';
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: \${state.matchedLocation}'),
      ),
    ),
  );
});

String _roleRoute(UserRole role) {
  switch (role) {
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
