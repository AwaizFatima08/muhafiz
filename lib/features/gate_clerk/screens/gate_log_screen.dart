import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../core/models/gate_event_model.dart';
import '../../../core/models/worker_model.dart';
import '../../../providers/auth_provider.dart';

class GateLogScreen extends ConsumerWidget {
  const GateLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Gate Log"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<GateEventModel>>(
        stream: firestoreService.watchTodayGateEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No events today',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              final isEntry = event.eventType == 'entry';
              return FutureBuilder<WorkerModel?>(
                future: firestoreService.getWorker(event.workerId),
                builder: (context, workerSnap) {
                  final worker = workerSnap.data;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isEntry
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      child: Icon(
                        isEntry
                            ? Icons.login_outlined
                            : Icons.logout_outlined,
                        color: isEntry ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      worker?.workerName ?? event.workerId,
                      style:
                          const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      worker?.cardNumber ?? '',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isEntry
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEntry ? 'Entry' : 'Exit',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isEntry ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event.processedAt.hour.toString().padLeft(2, '0')}:${event.processedAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500),
                        ),
                        if (event.overrideApplied)
                          const Text('Override',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.orange)),
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
