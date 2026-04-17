import 'package:cloud_firestore/cloud_firestore.dart';

class TerminationRequestModel {
  final String id;
  final String workerId;
  final String workerName;
  final String cardNumber;
  final String reason;
  final String initiatedBy;
  final String initiatorRole; // 'employer' | 'securityManager'
  final String status;        // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  TerminationRequestModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.cardNumber,
    required this.reason,
    required this.initiatedBy,
    required this.initiatorRole,
    required this.status,
    required this.createdAt,
  });

  factory TerminationRequestModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return TerminationRequestModel(
      id: doc.id,
      workerId: map['worker_id'] ?? '',
      workerName: map['worker_name'] ?? '',
      cardNumber: map['card_number'] ?? '',
      reason: map['reason'] ?? '',
      initiatedBy: map['initiated_by'] ?? '',
      initiatorRole: map['initiator_role'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'worker_id': workerId,
        'worker_name': workerName,
        'card_number': cardNumber,
        'reason': reason,
        'initiated_by': initiatedBy,
        'initiator_role': initiatorRole,
        'status': status,
        'created_at': Timestamp.fromDate(createdAt),
      };
}
