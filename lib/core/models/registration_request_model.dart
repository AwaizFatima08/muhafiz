import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class RegistrationRequestModel {
  final String id;
  final RegistrationRequestType requestType;
  final String submittedBy;
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
    required this.submittedBy,
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
        (e) => e.name == data['requestType'],
        orElse: () => RegistrationRequestType.newWorker,
      ),
      submittedBy: data['submittedBy'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      employeeData: Map<String, dynamic>.from(data['employeeData'] ?? {}),
      existingEmployeeId: data['existingEmployeeId'],
      status: RegistrationRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RegistrationRequestStatus.pending,
      ),
      adminNotes: data['adminNotes'],
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestType': requestType.name,
      'submittedBy': submittedBy,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'employeeData': employeeData,
      'existingEmployeeId': existingEmployeeId,
      'status': status.name,
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null
          ? Timestamp.fromDate(reviewedAt!)
          : null,
    };
  }
}
