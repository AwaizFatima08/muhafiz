import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class TerminationModel {
  final String id;
  final String workerId;
  final String residentId;
  final String initiatedByRole;
  final String terminatedBy;
  final DateTime terminatedAt;
  final String notes;
  final TerminationReasonCategory reasonCategory;
  final TerminationOutcome? outcome;
  final String? approvedBy;

  TerminationModel({
    required this.id,
    required this.workerId,
    required this.residentId,
    required this.initiatedByRole,
    required this.terminatedBy,
    required this.terminatedAt,
    required this.notes,
    required this.reasonCategory,
    this.outcome,
    this.approvedBy,
  });

  factory TerminationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TerminationModel(
      id: doc.id,
      workerId: data['worker_id'] ?? '',
      residentId: data['resident_id'] ?? '',
      initiatedByRole: data['initiated_by_role'] ?? '',
      terminatedBy: data['terminated_by'] ?? '',
      terminatedAt: data['terminated_at'] != null
          ? (data['terminated_at'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'] ?? '',
      reasonCategory: TerminationReasonCategory.values.firstWhere(
        (e) => e.name == data['reason_category'],
        orElse: () => TerminationReasonCategory.other,
      ),
      outcome: data['outcome'] != null
          ? TerminationOutcome.values.firstWhere(
              (e) => e.name == data['outcome'],
              orElse: () => TerminationOutcome.cleanTermination,
            )
          : null,
      approvedBy: data['approved_by'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'worker_id': workerId,
      'resident_id': residentId,
      'initiated_by_role': initiatedByRole,
      'terminated_by': terminatedBy,
      'terminated_at': Timestamp.fromDate(terminatedAt),
      'notes': notes,
      'reason_category': reasonCategory.name,
      'outcome': outcome?.name,
      'approved_by': approvedBy,
    };
  }
}
