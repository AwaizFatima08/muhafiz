import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => context.push('/register-worker'),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Register New Worker'),
        ),
      ),
    );
  }
}
