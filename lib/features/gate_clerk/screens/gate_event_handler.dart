import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/worker_model.dart';
import '../../../core/models/worker_assignment_model.dart';
import '../../../core/models/gate_event_model.dart';
import '../../../providers/auth_provider.dart';

class GateEventHandler {
  static Future<void> process({
    required WidgetRef ref,
    required WorkerModel worker,
    required WorkerAssignmentModel? assignment,
    required String eventType,
    required String? overrideReason,
    required String processedBy,
  }) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final now = DateTime.now();

    final event = GateEventModel(
      id: '',
      workerId: worker.id,
      employerId: assignment?.employerId ?? '',
      eventType: eventType,
      method: 'qrScan',
      processedBy: processedBy,
      processedAt: now,
      warningFlags: overrideReason != null ? ['override_applied'] : [],
      overrideApplied: overrideReason != null,
      overrideReason: overrideReason,
      syncStatus: 'synced',
      isAutoExit: false,
    );

    await firestoreService.createGateEvent(event);

    await firestoreService.setPresence(worker.id, {
      'current_status': eventType == 'entry' ? 'inside' : 'outside',
      'last_event_type': eventType,
      'last_event_time': Timestamp.fromDate(now),
      'last_processed_by': processedBy,
      'updated_at': Timestamp.fromDate(now),
    });
  }
}
