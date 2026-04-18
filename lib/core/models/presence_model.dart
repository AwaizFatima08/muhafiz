import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceModel {
  final String workerId;
  final String currentStatus;
  final String lastEventType;
  final DateTime? lastEventTime;
  final String lastProcessedBy;
  final String workerName;
  final String cardNumber;
  final DateTime? updatedAt;

  PresenceModel({
    required this.workerId,
    required this.currentStatus,
    required this.lastEventType,
    this.lastEventTime,
    required this.lastProcessedBy,
    this.workerName = '',
    this.cardNumber = '',
    this.updatedAt,
  });

  factory PresenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PresenceModel(
      workerId: doc.id,
      currentStatus: data['current_status'] ?? data['currentStatus'] ?? 'outside',
      lastEventType: data['last_event_type'] ?? data['lastEventType'] ?? 'exit',
      lastEventTime: data['last_event_time'] != null
          ? (data['last_event_time'] as Timestamp).toDate()
          : data['lastEventTime'] != null
              ? (data['lastEventTime'] as Timestamp).toDate()
              : null,
      lastProcessedBy: data['last_processed_by'] ?? data['lastProcessedBy'] ?? '',
      workerName:      data['worker_name'] ?? '',
      cardNumber:      data['card_number'] ?? '',
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'current_status': currentStatus,
      'last_event_type': lastEventType,
      'last_event_time': lastEventTime != null ? Timestamp.fromDate(lastEventTime!) : null,
      'last_processed_by': lastProcessedBy,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
