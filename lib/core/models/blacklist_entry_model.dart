import 'package:cloud_firestore/cloud_firestore.dart';

class BlacklistEntryModel {
  final String id;
  final String workerId;
  final String workerName;
  final String cardNumber;
  final String reason;
  final String blacklistedBy;
  final String blacklistedByRole;
  final bool isActive;
  final String? overrideBy;
  final DateTime createdAt;

  BlacklistEntryModel({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.cardNumber,
    required this.reason,
    required this.blacklistedBy,
    required this.blacklistedByRole,
    required this.isActive,
    this.overrideBy,
    required this.createdAt,
  });

  factory BlacklistEntryModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return BlacklistEntryModel(
      id: doc.id,
      workerId: map['worker_id'] ?? '',
      workerName: map['worker_name'] ?? '',
      cardNumber: map['card_number'] ?? '',
      reason: map['reason'] ?? '',
      blacklistedBy: map['blacklisted_by'] ?? '',
      blacklistedByRole: map['blacklisted_by_role'] ?? '',
      isActive: map['is_active'] ?? true,
      overrideBy: map['override_by'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'worker_id': workerId,
        'worker_name': workerName,
        'card_number': cardNumber,
        'reason': reason,
        'blacklisted_by': blacklistedBy,
        'blacklisted_by_role': blacklistedByRole,
        'is_active': isActive,
        'override_by': overrideBy,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

