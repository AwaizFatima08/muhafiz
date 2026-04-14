import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class GateEventModel {
  final String id;
  final String employeeId;
  final String primaryEmployerId;
  final GateEventType eventType;
  final GateEventMethod method;
  final String processedBy;
  final DateTime timestamp;
  final List<String> warningFlags;
  final bool overrideApplied;
  final String? overrideReason;
  final SyncStatus syncStatus;
  final bool isAutoExit;

  GateEventModel({
    required this.id,
    required this.employeeId,
    required this.primaryEmployerId,
    required this.eventType,
    required this.method,
    required this.processedBy,
    required this.timestamp,
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
      employeeId: data['employeeId'] ?? '',
      primaryEmployerId: data['primaryEmployerId'] ?? '',
      eventType: GateEventType.values.firstWhere(
        (e) => e.name == data['eventType'],
        orElse: () => GateEventType.entry,
      ),
      method: GateEventMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => GateEventMethod.manualClerk,
      ),
      processedBy: data['processedBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      warningFlags: List<String>.from(data['warningFlags'] ?? []),
      overrideApplied: data['overrideApplied'] ?? false,
      overrideReason: data['overrideReason'],
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => SyncStatus.pendingSync,
      ),
      isAutoExit: data['isAutoExit'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'primaryEmployerId': primaryEmployerId,
      'eventType': eventType.name,
      'method': method.name,
      'processedBy': processedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'warningFlags': warningFlags,
      'overrideApplied': overrideApplied,
      'overrideReason': overrideReason,
      'syncStatus': syncStatus.name,
      'isAutoExit': isAutoExit,
    };
  }
}
