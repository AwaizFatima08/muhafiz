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

    // ── Shift enforcement check ───────────────────────────────────────────
    bool shiftViolated = false;
    if (assignment != null &&
        assignment.shiftEnforcement &&
        eventType == 'entry' &&
        assignment.shiftStart != null &&
        assignment.shiftEnd != null) {
      final nowStr =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final start = assignment.shiftStart!.replaceAll(':', '');
      final end   = assignment.shiftEnd!.replaceAll(':', '');
      shiftViolated = nowStr.compareTo(start) < 0 ||
          nowStr.compareTo(end) > 0;
    }

    // ── Create gate event ──────────────────────────────────────────────────
    final event = GateEventModel(
      id: '',
      workerId: worker.id,
      residentId: assignment?.residentId ?? '',
      eventType: eventType,
      method: 'qrScan',
      processedBy: processedBy,
      processedAt: now,
      warningFlags: {
        if (overrideReason != null) 'override_applied': true,
        if (shiftViolated) 'shift_violation': true,
      },
      shiftViolated: shiftViolated,
      overrideApplied: overrideReason != null,
      overrideReason: overrideReason,
      syncStatus: 'synced',
      isAutoExit: false,
    );

    await firestoreService.createGateEvent(event);

    // ── Update presence ────────────────────────────────────────────────────
    await firestoreService.setPresence(worker.id, {
      'current_status': eventType == 'entry' ? 'inside' : 'outside',
      'last_event_type': eventType,
      'last_event_time': Timestamp.fromDate(now),
      'last_processed_by': processedBy,
      'worker_name': worker.workerName,
      'card_number': worker.cardNumber,
      'resident_id': assignment?.residentId ?? '',
      'updated_at': Timestamp.fromDate(now),
    });

    // ── FCM notification triggered by Cloud Function automatically ─────────
    // The Cloud Function watches gate_events collection.
    // No direct FCM call needed here — the function handles it server-side.
    // worker_name and employer_id are included in the event so the
    // Cloud Function can look up the employer's FCM token and send.
  }
}

