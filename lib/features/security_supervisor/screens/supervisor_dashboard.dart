import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/registration_request_model.dart';
import '../../../core/models/resident_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../providers/auth_provider.dart';

class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supervisor'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Workers'),
              Tab(text: 'Residents'),
              Tab(text: 'Vehicles'),
              Tab(text: 'Pets'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/register-worker'),
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.person_add_outlined, color: Colors.white),
          label: const Text('Register Worker',
              style: TextStyle(color: Colors.white)),
        ),
        body: TabBarView(
          children: [
            _WorkerValidations(ref: ref),
            _ResidentValidations(ref: ref),
            _VehicleValidations(ref: ref),
            _PetValidations(ref: ref),
          ],
        ),
      ),
    );
  }
}

// ── Worker registration requests — supervisor validates ──────────────────────
class _WorkerValidations extends StatelessWidget {
  final WidgetRef ref;
  const _WorkerValidations({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<RegistrationRequestModel>>(
      stream: fs.watchPendingRequests(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('No pending worker requests'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final r    = requests[i];
            final name = r.employeeData['worker_name'] ??
                r.employeeData['name'] ?? 'Unknown';
            // A1 FIX: extract fields to named variables before building
            // the subtitle string — prevents raw-literal bugs if fields
            // are absent and makes null-fallbacks explicit.
            final cnic = r.employeeData['cnic'] as String? ?? '---';
            final type = r.employeeData['worker_type'] as String? ?? '---';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child:
                      const Icon(Icons.person_outline, color: Colors.orange),
                ),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('$cnic · $type'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Validate — send to manager',
                    onPressed: () => fs.updateRegistrationRequest(r.id, {
                      'status': RegistrationRequestStatus.underReview.name,
                      'validated_by':
                          ref.read(authStateProvider).valueOrNull?.uid,
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Reject',
                    onPressed: () => fs.updateRegistrationRequest(r.id, {
                      'status': RegistrationRequestStatus.rejected.name,
                    }),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Resident approvals — supervisor validates ────────────────────────────────
class _ResidentValidations extends StatelessWidget {
  final WidgetRef ref;
  const _ResidentValidations({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<ResidentModel>>(
      stream: fs.watchPendingResidents(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final residents = snap.data ?? [];
        if (residents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('No pending resident requests'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: residents.length,
          itemBuilder: (_, i) {
            final r = residents[i];
            // A1 FIX: build subtitle from named parts so interpolation
            // is clean and null-safe.
            final subtitleParts = [
              'House: ${r.houseNumber}',
              if (r.phoneMobile.isNotEmpty) r.phoneMobile,
            ];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  child: Text(
                    r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(r.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(subtitleParts.join(' · ')),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Validate — send to manager',
                    onPressed: () => fs.updateResident(r.id, {
                      'status': ResidentStatus.underReview.name,
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Reject',
                    onPressed: () => fs.updateResident(r.id, {
                      'status': ResidentStatus.suspended.name,
                      'is_active': false,
                    }),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Vehicle approvals — supervisor validates ─────────────────────────────────
class _VehicleValidations extends StatelessWidget {
  final WidgetRef ref;
  const _VehicleValidations({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<VehicleModel>>(
      stream: fs.watchPendingVehicles(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final vehicles = snap.data ?? [];
        if (vehicles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('No pending vehicle requests'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (_, i) {
            final v = vehicles[i];
            // A1 FIX: build subtitle from a List to avoid null-interpolation
            // producing literal "null" strings in the UI.
            final subtitleParts = [
              v.vehicleType.name,
              if (v.make != null) v.make!,
              if (v.colour != null) v.colour!,
            ];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.directions_car_outlined,
                      color: Colors.blue),
                ),
                title: Text(v.vehicleRegistrationNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, letterSpacing: 1)),
                subtitle: Text(subtitleParts.join(' · ')),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Validate — send to manager',
                    onPressed: () =>
                        fs.updateVehicle(v.id, {'status': 'underReview'}),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Reject',
                    onPressed: () =>
                        fs.updateVehicle(v.id, {'status': 'rejected'}),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Pet approvals — supervisor validates ────────────────────────────────────
class _PetValidations extends StatelessWidget {
  final WidgetRef ref;
  const _PetValidations({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<PetModel>>(
      stream: fs.watchPendingPetRequests(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final pets = snap.data ?? [];
        if (pets.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('No pending pet requests'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pets.length,
          itemBuilder: (_, i) {
            final p = pets[i];
            // A1 FIX: build title and subtitle from named parts.
            final title = p.petName ??
                '${p.petType.name[0].toUpperCase()}${p.petType.name.substring(1)}';
            final subtitleParts = [
              p.petType.name,
              if (p.breed != null) p.breed!,
              if (p.vaccinationStatus) 'Vaccinated',
            ];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.pets, color: Colors.green),
                ),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(subtitleParts.join(' · ')),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Validate — send to manager',
                    onPressed: () =>
                        fs.updatePet(p.id, {'status': 'underReview'}),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Reject',
                    onPressed: () => fs.updatePet(p.id, {
                      'status': PetStatus.rejected.name,
                    }),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
