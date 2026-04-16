import 'package:cloud_firestore/cloud_firestore.dart';

class GateEventModel {
  final String id;
  final String workerId;
  final String employerId;
  final String eventType;
  final String method;
  final String processedBy;
  final DateTime processedAt;
  final List<String> warningFlags;
  final bool overrideApplied;
  final String? overrideReason;
  final String syncStatus;
  final bool isAutoExit;

  GateEventModel({
    required this.id,
    required this.workerId,
    required this.employerId,
    required this.eventType,
    required this.method,
    required this.processedBy,
    required this.processedAt,
    required this.warningFlags,
    required this.overrideApplied,
    this.overrideReason,
    required this.syncStatus,
    required this.isAutoExit,
  });

  factory GateEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GateEventModel(
      id: doc.id,
      workerId: data['workerId'] ?? '',
      employerId: data['employerId'] ?? '',
      eventType: data['event_type'] ?? data['eventType'] ?? 'entry',
      method: data['method'] ?? 'manualClerk',
      processedBy: data['processed_by'] ?? data['processedBy'] ?? '',
      processedAt: data['processed_at'] != null
          ? (data['processed_at'] as Timestamp).toDate()
          : data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
      warningFlags: List<String>.from(data['warning_flags'] ?? data['warningFlags'] ?? []),
      overrideApplied: data['override_applied'] ?? data['overrideApplied'] ?? false,
      overrideReason: data['override_reason'] ?? data['overrideReason'],
      syncStatus: data['sync_status'] ?? data['syncStatus'] ?? 'synced',
      isAutoExit: data['is_auto_exit'] ?? data['isAutoExit'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workerId': workerId,
      'employerId': employerId,
      'event_type': eventType,
      'method': method,
      'processed_by': processedBy,
      'processed_at': Timestamp.fromDate(processedAt),
      'warning_flags': warningFlags,
      'override_applied': overrideApplied,
      'override_reason': overrideReason,
      'sync_status': syncStatus,
      'is_auto_exit': isAutoExit,
    };
  }
}
