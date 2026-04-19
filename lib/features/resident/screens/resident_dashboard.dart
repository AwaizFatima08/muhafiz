import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'tabs/my_staff_tab.dart';
import 'tabs/my_family_tab.dart';
import 'tabs/my_vehicles_tab.dart';
import 'tabs/my_pets_tab.dart';
import 'tabs/notification_prefs_tab.dart';

class ResidentDashboard extends ConsumerStatefulWidget {
  const ResidentDashboard({super.key});

  @override
  ConsumerState<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends ConsumerState<ResidentDashboard> {
  int _selectedIndex = 0;

  static const List<_TabItem> _tabs = [
    _TabItem(icon: Icons.people_outline,      label: 'My Staff'),
    _TabItem(icon: Icons.family_restroom,      label: 'Family'),
    _TabItem(icon: Icons.directions_car_outlined, label: 'Vehicles'),
    _TabItem(icon: Icons.pets,                 label: 'Pets'),
    _TabItem(icon: Icons.notifications_outlined, label: 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    final authState   = ref.watch(authStateProvider);
    final currentUser = authState.valueOrNull;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      MyStaffTab(residentId: currentUser.uid),
      MyFamilyTab(residentId: currentUser.uid),
      MyVehiclesTab(residentId: currentUser.uid),
      MyPetsTab(residentId: currentUser.uid),
      NotificationPrefsTab(residentId: currentUser.uid),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_tabs[_selectedIndex].label),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/resident/edit-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
