import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../core/models/worker_assignment_model.dart';
import '../../../core/models/presence_model.dart';
import '../../../providers/auth_provider.dart';

class ResidentDashboard extends ConsumerWidget {
  const ResidentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.valueOrNull;
    final firestoreService = ref.read(firestoreServiceProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Staff'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<WorkerAssignmentModel>>(
        future: firestoreService.getAssignmentsForResident(currentUser.uid),
        builder: (context, assignSnap) {
          if (assignSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignments = assignSnap.data ?? [];

          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No staff assigned yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Contact security office to register staff',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(authStateProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    _SummaryChip(
                      label: 'Total Staff',
                      count: assignments.length,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _InsideCountChip(
                      workerIds:
                          assignments.map((a) => a.workerId).toList(),
                      firestoreService: firestoreService,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Staff Status',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...assignments.map((assignment) => _StaffCard(
                      assignment: assignment,
                      firestoreService: firestoreService,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _InsideCountChip extends StatelessWidget {
  final List<String> workerIds;
  final dynamic firestoreService;

  const _InsideCountChip({
    required this.workerIds,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PresenceModel>>(
      stream: firestoreService.watchWorkersInside(),
      builder: (context, snapshot) {
        final insideCount = (snapshot.data ?? [])
            .where((p) => workerIds.contains(p.workerId))
            .length;
        return _SummaryChip(
          label: 'Inside Now',
          count: insideCount,
          color: Colors.green,
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  final WorkerAssignmentModel assignment;
  final dynamic firestoreService;

  const _StaffCard({
    required this.assignment,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<PresenceModel?>(
          stream: firestoreService.watchWorkerPresence(assignment.workerId),
          builder: (context, presSnap) {
            final isInside =
                presSnap.data?.currentStatus == 'inside';
            return Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a3a5c).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF1a3a5c), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.workerId,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'House: ${assignment.houseNumber} • ${assignment.arrivalWindow}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isInside
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isInside
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isInside ? 'Inside' : 'Outside',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isInside
                          ? Colors.green
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
