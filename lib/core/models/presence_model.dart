import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class PresenceModel {
  final String employeeId;
  final PresenceStatus currentStatus;
  final GateEventType lastEventType;
  final DateTime lastEventTime;
  final String lastProcessedBy;
  final DateTime updatedAt;

  PresenceModel({
    required this.employeeId,
    required this.currentStatus,
    required this.lastEventType,
    required this.lastEventTime,
    required this.lastProcessedBy,
    required this.updatedAt,
  });

  factory PresenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PresenceModel(
      employeeId: doc.id,
      currentStatus: PresenceStatus.values.firstWhere(
        (e) => e.name == data['currentStatus'],
        orElse: () => PresenceStatus.outside,
      ),
      lastEventType: GateEventType.values.firstWhere(
        (e) => e.name == data['lastEventType'],
        orElse: () => GateEventType.exit,
      ),
      lastEventTime: (data['lastEventTime'] as Timestamp).toDate(),
      lastProcessedBy: data['lastProcessedBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'currentStatus': currentStatus.name,
      'lastEventType': lastEventType.name,
      'lastEventTime': Timestamp.fromDate(lastEventTime),
      'lastProcessedBy': lastProcessedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
