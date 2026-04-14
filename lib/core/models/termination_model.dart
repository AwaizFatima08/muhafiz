import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class TerminationModel {
  final String id;
  final String employeeId;
  final String initiatedBy;
  final DateTime initiatedAt;
  final String reason;
  final TerminationReasonCategory reasonCategory;
  final bool flaggedForBlacklist;
  final String? flagJustification;
  final DateTime? suspendedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final ManagerDecision managerDecision;
  final String? managerNotes;
  final TerminationOutcome? outcome;
  final DateTime createdAt;

  TerminationModel({
    required this.id,
    required this.employeeId,
    required this.initiatedBy,
    required this.initiatedAt,
    required this.reason,
    required this.reasonCategory,
    required this.flaggedForBlacklist,
    this.flagJustification,
    this.suspendedAt,
    this.reviewedBy,
    this.reviewedAt,
    required this.managerDecision,
    this.managerNotes,
    this.outcome,
    required this.createdAt,
  });

  factory TerminationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TerminationModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      initiatedBy: data['initiatedBy'] ?? '',
      initiatedAt: (data['initiatedAt'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      reasonCategory: TerminationReasonCategory.values.firstWhere(
        (e) => e.name == data['reasonCategory'],
        orElse: () => TerminationReasonCategory.other,
      ),
      flaggedForBlacklist: data['flaggedForBlacklist'] ?? false,
      flagJustification: data['flagJustification'],
      suspendedAt: data['suspendedAt'] != null
          ? (data['suspendedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      managerDecision: ManagerDecision.values.firstWhere(
        (e) => e.name == data['managerDecision'],
        orElse: () => ManagerDecision.pendingReview,
      ),
      managerNotes: data['managerNotes'],
      outcome: data['outcome'] != null
          ? TerminationOutcome.values.firstWhere(
              (e) => e.name == data['outcome'],
              orElse: () => TerminationOutcome.cleanTermination,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'initiatedBy': initiatedBy,
      'initiatedAt': Timestamp.fromDate(initiatedAt),
      'reason': reason,
      'reasonCategory': reasonCategory.name,
      'flaggedForBlacklist': flaggedForBlacklist,
      'flagJustification': flagJustification,
      'suspendedAt': suspendedAt != null
          ? Timestamp.fromDate(suspendedAt!)
          : null,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null
          ? Timestamp.fromDate(reviewedAt!)
          : null,
      'managerDecision': managerDecision.name,
      'managerNotes': managerNotes,
      'outcome': outcome?.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
