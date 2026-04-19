import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/security_manager/screens/security_manager_dashboard.dart';
import '../features/security_supervisor/screens/supervisor_dashboard.dart';
import '../features/gate_clerk/screens/clerk_dashboard.dart';
import '../features/resident/screens/resident_dashboard.dart';
import '../features/resident/screens/resident_registration_screen.dart';
import '../features/resident/screens/resident_worker_request_screen.dart';
import '../features/resident/screens/edit_profile_screen.dart';
import '../features/gate_clerk/screens/guest_entry_screen.dart';
import '../features/gate_clerk/screens/guest_exit_screen.dart';
import '../features/gate_clerk/screens/vehicle_log_screen.dart';
import '../features/security_supervisor/screens/worker_registration_screen.dart';
import '../features/gate_clerk/screens/qr_scan_screen.dart';
import '../features/gate_clerk/screens/manual_search_screen.dart';
import '../features/gate_clerk/screens/inside_workers_screen.dart';
import '../features/gate_clerk/screens/gate_log_screen.dart';
import '../features/security_manager/screens/reports_screen.dart';
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

      // Not logged in — allow public routes
      final isRegisterRoute = state.matchedLocation == '/register';
      if (!isLoggedIn) {
        if (isLoginRoute || isRegisterRoute) return null;
        return '/login';
      }

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
          case UserRole.resident:
            return '/resident';
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

      // ── Security Manager ───────────────────────────────────────────────
      // SecurityManagerDashboard is a home screen with 4 tabs:
      // Overview / Approvals / Terminations / Blacklist
      GoRoute(
        path: '/manager',
        builder: (context, state) => const SecurityManagerDashboard(),
      ),

      // ── Security Supervisor ────────────────────────────────────────────
      GoRoute(
        path: '/supervisor',
        builder: (context, state) => const SupervisorDashboard(),
      ),
      GoRoute(
        path: '/register-worker',
        builder: (context, state) => const WorkerRegistrationScreen(),
      ),

      // ── Gate Clerk ─────────────────────────────────────────────────────
      GoRoute(
        path: '/clerk',
        builder: (context, state) => const ClerkDashboard(),
      ),
      GoRoute(
        path: '/clerk/scan',
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/clerk/manual-search',
        builder: (context, state) => const ManualSearchScreen(),
      ),
      GoRoute(
        path: '/clerk/inside-list',
        builder: (context, state) => const InsideWorkersScreen(),
      ),
      GoRoute(
        path: '/clerk/gate-log',
        builder: (context, state) => const GateLogScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/clerk/guest-entry',
        builder: (context, state) => const GuestEntryScreen(),
      ),
      GoRoute(
        path: '/clerk/guest-exit',
        builder: (context, state) => const GuestExitScreen(),
      ),
      GoRoute(
        path: '/clerk/vehicle-log',
        builder: (context, state) => const VehicleLogScreen(),
      ),
      // ── Resident ───────────────────────────────────────────────────────
      GoRoute(
        path: '/resident',
        builder: (context, state) => const ResidentDashboard(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const ResidentRegistrationScreen(),
      ),
      GoRoute(
        path: '/resident/register-worker',
        builder: (context, state) =>
            const ResidentWorkerRequestScreen(),
      ),
      GoRoute(
        path: '/resident/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
