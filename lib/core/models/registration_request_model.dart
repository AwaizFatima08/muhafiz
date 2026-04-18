import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class RegistrationRequestModel {
  final String id;
  final RegistrationRequestType requestType;
  final String residentId;
  final String? workerId;
  final String submittedBy;
  final String? initiatedBy;
  final DateTime submittedAt;
  final Map<String, dynamic> employeeData;
  final String? existingEmployeeId;
  final RegistrationRequestStatus status;
  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  RegistrationRequestModel({
    required this.id,
    required this.requestType,
    required this.residentId,
    this.workerId,
    required this.submittedBy,
    this.initiatedBy,
    required this.submittedAt,
    required this.employeeData,
    this.existingEmployeeId,
    required this.status,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory RegistrationRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistrationRequestModel(
      id: doc.id,
      requestType: RegistrationRequestType.values.firstWhere(
        (e) => e.name == (data['request_type'] ?? data['requestType']),
        orElse: () => RegistrationRequestType.newWorker,
      ),
      residentId: data['resident_id'] ?? '',
      workerId: data['worker_id'],
      submittedBy: data['submitted_by'] ?? data['submittedBy'] ?? '',
      initiatedBy: data['initiated_by'],
      submittedAt: data['submitted_at'] != null
          ? (data['submitted_at'] as Timestamp).toDate()
          : (data['submittedAt'] as Timestamp).toDate(),
      employeeData: Map<String, dynamic>.from(data['employeeData'] ?? {}),
      existingEmployeeId: data['existing_worker_id'] ?? data['existingEmployeeId'],
      status: RegistrationRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RegistrationRequestStatus.pending,
      ),
      adminNotes: data['admin_notes'] ?? data['adminNotes'],
      reviewedBy: data['reviewed_by'] ?? data['reviewedBy'],
      reviewedAt: data['reviewed_at'] != null
          ? (data['reviewed_at'] as Timestamp).toDate()
          : data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'request_type': requestType.name,
      'resident_id': residentId,
      'worker_id': workerId,
      'submitted_by': submittedBy,
      'initiated_by': initiatedBy,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'existing_worker_id': existingEmployeeId,
      'status': status.name,
      'admin_notes': adminNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt != null
          ? Timestamp.fromDate(reviewedAt!)
          : null,
    };
  }
}
