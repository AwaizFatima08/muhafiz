import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../models/worker_assignment_model.dart';
import '../models/gate_event_model.dart';
import '../models/presence_model.dart';
import '../models/termination_model.dart';
import '../models/notification_model.dart';
import '../models/registration_request_model.dart';
import '../models/site_settings_model.dart';
import '../models/termination_request_model.dart';
import '../models/blacklist_entry_model.dart';
import '../models/resident_model.dart';
import '../models/organisation_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_event_model.dart';
import '../models/guest_visit_model.dart';
import '../models/announcement_model.dart';
import '../models/pet_model.dart';
import '../models/family_member_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ─── Collection References ───────────────────────────────────────────────

  CollectionReference get _workers => _db.collection('workers');
  CollectionReference get _residents => _db.collection('residents');
  CollectionReference get _assignments => _db.collection('worker_assignments');
  CollectionReference get _gateEvents => _db.collection('gate_events');
  CollectionReference get _presence => _db.collection('presence_tracker');
  CollectionReference get _terminations => _db.collection('termination_records');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _requests => _db.collection('registration_requests');
  CollectionReference get _siteSettings => _db.collection('site_settings');
  CollectionReference get _terminationRequests =>
      _db.collection('termination_requests');
  CollectionReference get _blacklist => _db.collection('blacklist');
  CollectionReference get _organisations => _db.collection('organisations');
  CollectionReference get _vehicles => _db.collection('vehicles');
  CollectionReference get _vehicleEvents => _db.collection('vehicle_events');
  CollectionReference get _guestVisits => _db.collection('guest_visits');
  CollectionReference get _announcements => _db.collection('announcements');
  CollectionReference get _pets => _db.collection('pets');
  CollectionReference get _familyDetails => _db.collection('resident_family_details');

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
        .map((snap) =>
            snap.docs.map((doc) => WorkerModel.fromFirestore(doc)).toList());
  }

  Future<WorkerModel?> getWorkerByCnic(String cnic) async {
    try {
      final snap =
          await _workers.where('cnic', isEqualTo: cnic).limit(1).get();
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

  Future<WorkerModel?> getWorkerByCardNumber(String cardNumber) async {
    try {
      final snap = await _workers
          .where('card_number', isEqualTo: cardNumber)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return WorkerModel.fromFirestore(snap.docs.first);
    } catch (e) {
      return null;
    }
  }

  // ─── Employers ───────────────────────────────────────────────────────────

  Future<ResidentModel?> getResident(String residentId) async {
    try {
      final doc = await _residents.doc(residentId).get();
      if (!doc.exists) return null;
      return ResidentModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> createResident(ResidentModel resident) async {
    await _residents.doc(resident.id).set(resident.toFirestore());
  }

  Future<void> updateResident(String residentId, Map<String, dynamic> data) async {
    await _residents.doc(residentId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ResidentModel>> watchActiveResidents() {
    return _residents
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ResidentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ResidentModel>> watchPendingResidents() {
    return _residents
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ResidentModel.fromFirestore(doc))
            .toList());
  }

  /// Saves FCM token for any role.
  /// Wrapped in individual try/catch blocks — a permission error on one
  /// collection (e.g. gateClerk has no employers doc) does not block the other.
  Future<void> updateFcmToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _residents.doc(userId).set(
        {'fcm_token': token, 'updated_at': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {}
    try {
      await _db.collection('users').doc(userId).set(
        {'fcm_token': token},
        SetOptions(merge: true),
      );
    } catch (_) {}
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

  Future<List<WorkerAssignmentModel>> getAssignmentsForResident(
      String residentId) async {
    try {
      final snap = await _assignments
          .where('resident_id', isEqualTo: residentId)
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
          .where('worker_id', isEqualTo: workerId)
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
    final startOfDay = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _gateEvents
        .where('processed_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('processed_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GateEventModel.fromFirestore(doc))
            .toList());
  }

  Future<List<GateEventModel>> getGateEventsForWorker(String workerId,
      {int limit = 20}) async {
    try {
      final snap = await _gateEvents
          .where('worker_id', isEqualTo: workerId)
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

  // ─── Termination Records (original) ─────────────────────────────────────

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
        .where('outcome', isNull: true)
        .orderBy('terminated_at', descending: true)
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
    final insideSnap =
        await _presence.where('current_status', isEqualTo: 'inside').get();

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    for (final doc in insideSnap.docs) {
      final workerId = doc.id;

      batch.update(_presence.doc(workerId), {
        'current_status': 'outside',
        'last_event_type': 'exit',
        'last_event_time': now,
        'last_processed_by': processedBy,
        'updated_at': now,
      });

      final eventRef = _gateEvents.doc();
      batch.set(eventRef, {
        'worker_id': workerId,
        'resident_id': (doc.data() as Map<String, dynamic>?)?['resident_id'] ?? '',
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

  // ─── Site Settings ───────────────────────────────────────────────────────

  Future<SiteSettings?> getSiteSettings(String siteId) async {
    try {
      final doc = await _siteSettings.doc(siteId).get();
      if (!doc.exists) return null;
      return SiteSettings.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateOverstayThreshold(String siteId, int hours) async {
    await _siteSettings.doc(siteId).set(
      {'overstay_threshold_hours': hours},
      SetOptions(merge: true),
    );
  }

  // ─── Overstay ────────────────────────────────────────────────────────────

  /// Returns workers currently inside whose last_event_time exceeds threshold.
  /// siteId retained as parameter for future multi-site expansion — unused
  /// in queries since presence_tracker has no site_id field (single township).
  Stream<List<Map<String, dynamic>>> overstayWorkers(
      String siteId, int thresholdHours) {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(Duration(hours: thresholdHours)),
    );
    return _presence
        .where('current_status', isEqualTo: 'inside')
        .where('last_event_time', isLessThan: cutoff)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
            .toList());
  }

  // ─── Active Workers Count ────────────────────────────────────────────────

  /// Workers currently inside the township gate.
  Stream<int> activeWorkersInsideCount() {
    return _presence
        .where('current_status', isEqualTo: 'inside')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// All registered and approved workers (not terminated/blacklisted).
  Stream<int> totalActiveWorkersCount() {
    return _workers
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.size);
  }

  // ─── Termination Requests (Security Manager flow) ────────────────────────

  Stream<List<TerminationRequestModel>> watchTerminationRequests() {
    return _terminationRequests
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TerminationRequestModel.fromFirestore(d))
            .toList());
  }

  Future<void> submitTerminationRequest({
    required String workerId,
    required String workerName,
    required String cardNumber,
    required String reason,
    required String initiatedBy,
    required String initiatorRole,
  }) async {
    await _terminationRequests.add({
      'worker_id': workerId,
      'worker_name': workerName,
      'card_number': cardNumber,
      'reason': reason,
      'initiated_by': initiatedBy,
      'initiator_role': initiatorRole,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveTerminationRequest({
    required String requestId,
    required String workerId,
    required String decision, // 'approved' | 'rejected'
  }) async {
    final batch = _db.batch();

    batch.update(_terminationRequests.doc(requestId), {'status': decision});

    if (decision == 'approved') {
      batch.update(_workers.doc(workerId), {
        'status': 'terminated',
        'card_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// One-time fetch of all active workers for local cache.
  /// Called by ClerkDashboard on startup and on reconnect.
  Future<List<Map<String, dynamic>>> getActiveWorkersSnapshot() async {
    final snap = await _workers
        .where('status', whereIn: ['active', 'suspended'])
        .get();
    return snap.docs
        .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
        .toList();
  }

  // ─── Blacklist ───────────────────────────────────────────────────────────

  Stream<List<BlacklistEntryModel>> watchBlacklistEntries() {
    return _blacklist
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BlacklistEntryModel.fromFirestore(d))
            .toList());
  }

  Future<void> addToBlacklist({
    required String workerId,
    required String workerName,
    required String cardNumber,
    required String reason,
    required String blacklistedBy,
    required String blacklistedByRole,
  }) async {
    final batch = _db.batch();

    batch.set(_blacklist.doc(workerId), {
      'worker_id': workerId,
      'worker_name': workerName,
      'card_number': cardNumber,
      'reason': reason,
      'blacklisted_by': blacklistedBy,
      'blacklisted_by_role': blacklistedByRole,
      'is_active': true,
      'override_by': null,
      'created_at': FieldValue.serverTimestamp(),
    });

    batch.update(_workers.doc(workerId), {
      'card_active': false,
      'status': 'blacklisted',
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> overrideBlacklist({
    required String workerId,
    required String overrideByUid,
  }) async {
    final batch = _db.batch();

    batch.update(_blacklist.doc(workerId), {
      'is_active': false,
      'override_by': overrideByUid,
    });

    batch.update(_workers.doc(workerId), {
      'card_active': true,
      'status': 'active',
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ─── Organisations ────────────────────────────────────────────────────

  Future<List<OrganisationModel>> getOrganisations() async {
    try {
      final snap = await _organisations
          .where('is_active', isEqualTo: true)
          .orderBy('name')
          .get();
      return snap.docs
          .map((d) => OrganisationModel.fromFirestore(d))
          .toList();
    } catch (e) { return []; }
  }

  Future<String> createOrganisation(OrganisationModel org) async {
    final ref = await _organisations.add(org.toFirestore());
    return ref.id;
  }

  Future<void> updateOrganisation(String orgId, Map<String, dynamic> data) async {
    await _organisations.doc(orgId).update(data);
  }

  // ─── Vehicles ─────────────────────────────────────────────────────────

  Future<List<VehicleModel>> getVehiclesForResident(String residentId) async {
    try {
      final snap = await _vehicles
          .where('resident_id', isEqualTo: residentId)
          .where('is_active', isEqualTo: true)
          .get();
      return snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList();
    } catch (e) { return []; }
  }

  Future<VehicleModel?> getVehicleByPlate(String plate) async {
    try {
      final snap = await _vehicles
          .where('vehicle_registration_number', isEqualTo: plate)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return VehicleModel.fromFirestore(snap.docs.first);
    } catch (e) { return null; }
  }

  Future<String> createVehicle(VehicleModel vehicle) async {
    final ref = await _vehicles.add(vehicle.toFirestore());
    return ref.id;
  }

  Future<void> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    await _vehicles.doc(vehicleId).update(data);
  }

  // ─── Vehicle Events ───────────────────────────────────────────────────

  Future<String> createVehicleEvent(VehicleEventModel event) async {
    final ref = await _vehicleEvents.add(event.toFirestore());
    return ref.id;
  }

  Stream<List<VehicleEventModel>> watchTodayVehicleEvents() {
    final startOfDay = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _vehicleEvents
        .where('processed_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('processed_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => VehicleEventModel.fromFirestore(d))
            .toList());
  }

  // ─── Guest Visits ─────────────────────────────────────────────────────

  Future<String> createGuestVisit(GuestVisitModel visit) async {
    final ref = await _guestVisits.add(visit.toFirestore());
    return ref.id;
  }

  Future<void> updateGuestVisit(String visitId, Map<String, dynamic> data) async {
    await _guestVisits.doc(visitId).update(data);
  }

  Future<GuestVisitModel?> getGuestVisitByQr(String qrValue) async {
    try {
      final snap = await _guestVisits
          .where('slip_qr_value', isEqualTo: qrValue)
          .where('status', isEqualTo: 'inside')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return GuestVisitModel.fromFirestore(snap.docs.first);
    } catch (e) { return null; }
  }

  Stream<List<GuestVisitModel>> watchGuestsInsideToday() {
    final startOfDay = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _guestVisits
        .where('entry_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('entry_time', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GuestVisitModel.fromFirestore(d))
            .toList());
  }

  Future<List<GuestVisitModel>> getVisitorHistoryForResident(
      String residentId, {int limit = 50}) async {
    try {
      final snap = await _guestVisits
          .where('visiting_resident_id', isEqualTo: residentId)
          .orderBy('entry_time', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => GuestVisitModel.fromFirestore(d)).toList();
    } catch (e) { return []; }
  }

  // ─── Announcements ────────────────────────────────────────────────────

  Future<String> createAnnouncement(AnnouncementModel announcement) async {
    final ref = await _announcements.add(announcement.toFirestore());
    return ref.id;
  }

  Stream<List<AnnouncementModel>> watchRecentAnnouncements({int limit = 20}) {
    return _announcements
        .orderBy('sent_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AnnouncementModel.fromFirestore(d))
            .toList());
  }

  // ─── Pets ─────────────────────────────────────────────────────────────

  Future<String> createPetRequest(PetModel pet) async {
    final ref = await _pets.add(pet.toFirestore());
    return ref.id;
  }

  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    await _pets.doc(petId).update(data);
  }

  Stream<List<PetModel>> watchPendingPetRequests() {
    return _pets
        .where('status', isEqualTo: 'pending')
        .orderBy('request_initiated_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PetModel.fromFirestore(d))
            .toList());
  }

  Future<List<PetModel>> getPetsForResident(String residentId) async {
    try {
      final snap = await _pets
          .where('resident_id', isEqualTo: residentId)
          .orderBy('request_initiated_at', descending: true)
          .get();
      return snap.docs.map((d) => PetModel.fromFirestore(d)).toList();
    } catch (e) { return []; }
  }

  // ─── Family Details ───────────────────────────────────────────────────

  Future<List<FamilyMemberModel>> getFamilyMembers(String residentId) async {
    try {
      final doc = await _familyDetails.doc(residentId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      return data.entries
          .where((e) => e.value is Map)
          .map((e) => FamilyMemberModel.fromMap(
                e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList();
    } catch (e) { return []; }
  }

  Future<void> saveFamilyMember(
      String residentId, FamilyMemberModel member) async {
    await _familyDetails.doc(residentId).set(
      {member.memberId: member.toMap()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteFamilyMember(
      String residentId, String memberId) async {
    await _familyDetails.doc(residentId).update({
      memberId: FieldValue.delete(),
    });
  }

  // ─── Guest Visits Count ───────────────────────────────────────────────

  Stream<int> guestsInsideCount() {
    return _guestVisits
        .where('status', isEqualTo: 'inside')
        .snapshots()
        .map((snap) => snap.size);
  }
}
