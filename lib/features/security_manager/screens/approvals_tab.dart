import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/registration_request_model.dart';
import '../../../core/models/resident_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/enums/app_enums.dart';
import '../../../providers/auth_provider.dart';

class ApprovalsTab extends ConsumerWidget {
  final String siteId;
  const ApprovalsTab({super.key, required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Workers'),
              Tab(text: 'Residents'),
              Tab(text: 'Vehicles'),
              Tab(text: 'Pets'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _WorkerApprovals(ref: ref),
                _ResidentApprovals(ref: ref),
                _VehicleApprovals(ref: ref),
                _PetApprovals(ref: ref),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Worker registration requests ─────────────────────────────────────────────
class _WorkerApprovals extends StatelessWidget {
  final WidgetRef ref;
  const _WorkerApprovals({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<RegistrationRequestModel>>(
      stream: fs.watchUnderReviewRequests(),
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
                Text('No pending worker approvals'),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline, color: Colors.blue),
                ),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('CNIC: \$cnic · \$type\$initiatedBy'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green),
                      onPressed: () => fs.updateRegistrationRequest(
                          r.id, {'status': 'approved'}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => fs.updateRegistrationRequest(
                          r.id, {'status': 'rejected'}),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Resident approvals ───────────────────────────────────────────────────────
class _ResidentApprovals extends StatelessWidget {
  final WidgetRef ref;
  const _ResidentApprovals({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<ResidentModel>>(
      stream: fs.watchUnderReviewResidents(),
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
                Text('No pending resident approvals'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: residents.length,
          itemBuilder: (_, i) {
            final r = residents[i];
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
                subtitle: Text(
                  'House: \${r.houseNumber}'
                  '\${r.phoneMobile.isNotEmpty ? " · \${r.phoneMobile}" : ""}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green),
                      onPressed: () => fs.updateResident(r.id, {
                        'status': ResidentStatus.approved.name,
                        'is_active': true,
                        'approved_at': DateTime.now().toIso8601String(),
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => fs.updateResident(r.id, {
                        'status': ResidentStatus.suspended.name,
                        'is_active': false,
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Pet approvals ────────────────────────────────────────────────────────────
class _PetApprovals extends StatelessWidget {
  final WidgetRef ref;
  const _PetApprovals({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<PetModel>>(
      stream: fs.watchUnderReviewPetRequests(),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.pets, color: Colors.green),
                ),
                title: Text(
                  p.petName ??
                      '\${p.petType.name[0].toUpperCase()}'
                      '\${p.petType.name.substring(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '\${p.petType.name}'
                  '\${p.breed != null ? " · \${p.breed}" : ""}'
                  '\${p.vaccinationStatus ? " · Vaccinated" : ""}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green),
                      onPressed: () => fs.updatePet(p.id, {
                        'status': PetStatus.approved.name,
                        'approved_at': DateTime.now().toIso8601String(),
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => fs.updatePet(p.id, {
                        'status': PetStatus.rejected.name,
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VehicleApprovals extends StatelessWidget {
  final WidgetRef ref;
  const _VehicleApprovals({required this.ref});

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return StreamBuilder<List<VehicleModel>>(
      stream: fs.watchUnderReviewVehicles(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final vehicles = snap.data ?? [];
        if (vehicles.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              SizedBox(height: 12),
              Text('No vehicles pending approval'),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (_, i) {
            final v = vehicles[i];
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
                subtitle: Text(
                  [
                    v.vehicleType.name,
                    if (v.make != null) v.make!,
                    if (v.colour != null) v.colour!,
                  ].join(' · '),
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => fs.updateVehicle(v.id, {
                      'status': 'approved',
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => fs.updateVehicle(v.id, {
                      'status': 'rejected',
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
