import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../models/employer_model.dart';
import '../models/worker_assignment_model.dart';
import '../models/gate_event_model.dart';
import '../models/presence_model.dart';
import '../models/termination_model.dart';
import '../models/notification_model.dart';
import '../models/registration_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ─── Collection References ───────────────────────────────────────────────

  CollectionReference get _workers => _db.collection('workers');
  CollectionReference get _employers => _db.collection('employers');
  CollectionReference get _assignments => _db.collection('worker_assignments');
  CollectionReference get _gateEvents => _db.collection('gate_events');
  CollectionReference get _presence => _db.collection('presence_tracker');
  CollectionReference get _terminations => _db.collection('termination_records');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _requests => _db.collection('registration_requests');

  // ─── Workers ─────────────────────────────────────────────────────────────

  Future<WorkerModel?> getWorker(String workerId) async {
    try {
      final doc = await _workers.doc(workerId).get();
      if (!doc.exists) return null;
      return WorkerModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<String> createWorker(WorkerModel worker) async {
    final ref = await _workers.add(worker.toFirestore());
    return ref.id;
  }

  Future<void> updateWorker(String workerId, Map<String, dynamic> data) async {
    await _workers.doc(workerId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<WorkerModel>> watchActiveWorkers() {
    return _workers
        .where('status', whereIn: ['active', 'suspended', 'pendingApproval'])
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WorkerModel.fromFirestore(doc))
            .toList());
  }

  Future<WorkerModel?> getWorkerByCnic(String cnic) async {
    try {
      final snap = await _workers.where('cnic', isEqualTo: cnic).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return WorkerModel.fromFirestore(snap.docs.first);
    } catch (e) {
      return null;
    }
  }

  Future<WorkerModel?> getWorkerByQr(String qrValue) async {
    try {
      final snap = await _workers
          .where('qr_code_value', isEqualTo: qrValue)
          .where('qr_code_invalidated', isEqualTo: false)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return WorkerModel.fromFirestore(snap.docs.first);
    } catch (e) {
      return null;
    }
  }

  // ─── Employers ───────────────────────────────────────────────────────────

  Future<EmployerModel?> getEmployer(String employerId) async {
    try {
      final doc = await _employers.doc(employerId).get();
      if (!doc.exists) return null;
      return EmployerModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateEmployerFcmToken(String employerId, String token) async {
    await _employers.doc(employerId).update({'fcm_token': token});
  }

  Stream<List<EmployerModel>> watchActiveEmployers() {
    return _employers
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EmployerModel.fromFirestore(doc))
            .toList());
  }

  // ─── Worker Assignments ──────────────────────────────────────────────────

  Future<WorkerAssignmentModel?> getAssignment(String assignmentId) async {
    try {
      final doc = await _assignments.doc(assignmentId).get();
      if (!doc.exists) return null;
      return WorkerAssignmentModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<List<WorkerAssignmentModel>> getAssignmentsForEmployer(
      String employerId) async {
    try {
      final snap = await _assignments
          .where('employerId', isEqualTo: employerId)
          .where('status', isEqualTo: 'active')
          .get();
      return snap.docs
          .map((doc) => WorkerAssignmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<WorkerAssignmentModel?> getActiveAssignmentForWorker(
      String workerId) async {
    try {
      final snap = await _assignments
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return WorkerAssignmentModel.fromFirestore(snap.docs.first);
    } catch (e) {
      return null;
    }
  }

  Future<String> createAssignment(WorkerAssignmentModel assignment) async {
    final ref = await _assignments.add(assignment.toFirestore());
    return ref.id;
  }

  Future<void> updateAssignment(
      String assignmentId, Map<String, dynamic> data) async {
    await _assignments.doc(assignmentId).update(data);
  }

  // ─── Gate Events ─────────────────────────────────────────────────────────

  Future<String> createGateEvent(GateEventModel event) async {
    final ref = await _gateEvents.add(event.toFirestore());
    return ref.id;
  }

  Stream<List<GateEventModel>> watchTodayGateEvents() {
    final startOfDay = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0);
    return _gateEvents
        .where('processed_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('processed_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GateEventModel.fromFirestore(doc))
            .toList());
  }

  Future<List<GateEventModel>> getGateEventsForWorker(
      String workerId, {int limit = 20}) async {
    try {
      final snap = await _gateEvents
          .where('workerId', isEqualTo: workerId)
          .orderBy('processed_at', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => GateEventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Presence Tracker ────────────────────────────────────────────────────

  Future<PresenceModel?> getPresence(String workerId) async {
    try {
      final doc = await _presence.doc(workerId).get();
      if (!doc.exists) return null;
      return PresenceModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> setPresence(String workerId, Map<String, dynamic> data) async {
    await _presence.doc(workerId).set({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<PresenceModel>> watchWorkersInside() {
    return _presence
        .where('current_status', isEqualTo: 'inside')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PresenceModel.fromFirestore(doc))
            .toList());
  }

  Stream<PresenceModel?> watchWorkerPresence(String workerId) {
    return _presence.doc(workerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PresenceModel.fromFirestore(doc);
    });
  }

  // ─── Termination Records ─────────────────────────────────────────────────

  Future<String> createTermination(TerminationModel termination) async {
    final ref = await _terminations.add(termination.toFirestore());
    return ref.id;
  }

  Future<void> updateTermination(
      String terminationId, Map<String, dynamic> data) async {
    await _terminations.doc(terminationId).update(data);
  }

  Stream<List<TerminationModel>> watchPendingTerminations() {
    return _terminations
        .where('manager_decision', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TerminationModel.fromFirestore(doc))
            .toList());
  }

  // ─── Notifications ───────────────────────────────────────────────────────

  Future<void> createNotification(NotificationModel notification) async {
    await _notifications.add(notification.toFirestore());
  }

  Stream<List<NotificationModel>> watchUnreadNotifications(
      String recipientUserId) {
    return _notifications
        .where('recipient_user_id', isEqualTo: recipientUserId)
        .where('is_read', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'is_read': true});
  }

  // ─── Registration Requests ───────────────────────────────────────────────

  Future<String> createRegistrationRequest(
      RegistrationRequestModel request) async {
    final ref = await _requests.add(request.toFirestore());
    return ref.id;
  }

  Future<void> updateRegistrationRequest(
      String requestId, Map<String, dynamic> data) async {
    await _requests.doc(requestId).update(data);
  }

  Stream<List<RegistrationRequestModel>> watchPendingRequests() {
    return _requests
        .where('status', isEqualTo: 'pending')
        .orderBy('submitted_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RegistrationRequestModel.fromFirestore(doc))
            .toList());
  }

  // ─── Midnight Auto-Exit ──────────────────────────────────────────────────

  Future<void> autoExitAllInside(String processedBy) async {
    final insideSnap = await _presence
        .where('current_status', isEqualTo: 'inside')
        .get();

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    for (final doc in insideSnap.docs) {
      final workerId = doc.id;

      // Update presence
      batch.update(_presence.doc(workerId), {
        'current_status': 'outside',
        'last_event_type': 'exit',
        'last_event_time': now,
        'last_processed_by': processedBy,
        'updated_at': now,
      });

      // Create auto-exit gate event
      final eventRef = _gateEvents.doc();
      batch.set(eventRef, {
        'workerId': workerId,
        'employerId': (doc.data() as Map<String, dynamic>?)?['last_processed_by'] ?? '',
        'event_type': 'exit',
        'method': 'auto',
        'processed_by': processedBy,
        'processed_at': now,
        'warning_flags': [],
        'override_applied': false,
        'override_reason': null,
        'sync_status': 'synced',
        'is_auto_exit': true,
      });
    }

    await batch.commit();
  }
}
