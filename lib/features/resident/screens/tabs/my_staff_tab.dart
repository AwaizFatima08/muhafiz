import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/themes.dart';
import '../../../../core/models/worker_assignment_model.dart';
import '../../../../core/models/presence_model.dart';
import '../../../../providers/auth_provider.dart';

class MyStaffTab extends ConsumerWidget {
  final String residentId;
  const MyStaffTab({super.key, required this.residentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(firestoreServiceProvider);

    return FutureBuilder<List<WorkerAssignmentModel>>(
      future: fs.getAssignmentsForResident(residentId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assignments = snap.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Total',
                        count: assignments.length,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _InsideChip(
                        workerIds: assignments.map((a) => a.workerId).toList(),
                        fs: fs,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => context.push('/resident/register-worker'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Worker'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (assignments.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No staff assigned yet'),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _StaffCard(
                          assignment: assignments[i], fs: fs),
                      childCount: assignments.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }
}

class _InsideChip extends StatelessWidget {
  final List<String> workerIds;
  final dynamic fs;
  const _InsideChip({required this.workerIds, required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PresenceModel>>(
      stream: fs.watchWorkersInside(),
      builder: (ctx, snap) {
        final count = (snap.data ?? [])
            .where((p) => workerIds.contains(p.workerId))
            .length;
        return _StatChip(label: 'Inside', count: count, color: Colors.green);
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  final WorkerAssignmentModel assignment;
  final dynamic fs;
  const _StaffCard({required this.assignment, required this.fs});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<PresenceModel?>(
          stream: fs.watchWorkerPresence(assignment.workerId),
          builder: (ctx, pSnap) {
            final isInside = pSnap.data?.currentStatus == 'inside';
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assignment.workerId,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        'House: \${assignment.houseNumber}'
                        '\${assignment.arrivalWindow.isNotEmpty ? " • \${assignment.arrivalWindow}" : ""}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isInside ? Colors.green : Colors.grey.shade600,
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
