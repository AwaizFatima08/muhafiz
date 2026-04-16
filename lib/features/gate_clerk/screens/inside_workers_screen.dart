import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../core/models/presence_model.dart';
import '../../../core/models/worker_model.dart';
import '../../../providers/auth_provider.dart';

class InsideWorkersScreen extends ConsumerWidget {
  const InsideWorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers Inside'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PresenceModel>>(
        stream: firestoreService.watchWorkersInside(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final inside = snapshot.data ?? [];
          if (inside.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No workers inside',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: inside.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final presence = inside[index];
              return FutureBuilder<WorkerModel?>(
                future: firestoreService.getWorker(presence.workerId),
                builder: (context, workerSnap) {
                  final worker = workerSnap.data;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.green.withValues(alpha: 0.15),
                      child: const Icon(Icons.person,
                          color: Colors.green, size: 20),
                    ),
                    title: Text(worker?.workerName ?? presence.workerId,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(worker?.cardNumber ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Inside',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                        if (presence.lastEventTime != null)
                          Text(
                            'Since ${presence.lastEventTime!.hour.toString().padLeft(2, '0')}:${presence.lastEventTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
