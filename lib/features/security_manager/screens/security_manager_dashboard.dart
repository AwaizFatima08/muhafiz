import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'overview_tab.dart';
import 'approvals_tab.dart';
import 'terminations_tab.dart';
import 'blacklist_tab.dart';

class SecurityManagerDashboard extends StatefulWidget {
  const SecurityManagerDashboard({super.key});

  @override
  State<SecurityManagerDashboard> createState() =>
      _SecurityManagerDashboardState();
}

class _SecurityManagerDashboardState extends State<SecurityManagerDashboard> {
  int _currentIndex = 0;

  static const String siteId = 'township_main';

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const OverviewTab(siteId: siteId),
      const ApprovalsTab(siteId: siteId),
      const TerminationsTab(siteId: siteId),
      const BlacklistTab(siteId: siteId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muhafiz — Security Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'Reports',
            onPressed: () => context.push('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(
              icon: Icon(Icons.approval), label: 'Approvals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.gavel), label: 'Terminations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.block), label: 'Blacklist'),
        ],
      ),
    );
  }
}

