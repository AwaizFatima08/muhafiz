import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class VehicleEventModel {
  final String id;
  final String vehicleId;
  final String residentId;
  final String vehicleRegistrationNumber;
  final VehicleEventMethod method;
  final String eventType; // entry | exit
  final String? rfidRead;     // future
  final String? barrierId;    // future
  final String processedBy;
  final DateTime processedAt;

  VehicleEventModel({
    required this.id,
    required this.vehicleId,
    required this.residentId,
    required this.vehicleRegistrationNumber,
    required this.method,
    required this.eventType,
    this.rfidRead,
    this.barrierId,
    required this.processedBy,
    required this.processedAt,
  });

  factory VehicleEventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VehicleEventModel(
      id:                        doc.id,
      vehicleId:                 d['vehicle_id'] ?? '',
      residentId:                d['resident_id'] ?? '',
      vehicleRegistrationNumber: d['vehicle_registration_number'] ?? '',
      method: VehicleEventMethod.values.firstWhere(
        (e) => e.name == d['method'],
        orElse: () => VehicleEventMethod.manual,
      ),
      eventType:   d['event_type'] ?? 'entry',
      rfidRead:    d['rfid_read'],
      barrierId:   d['barrier_id'],
      processedBy: d['processed_by'] ?? '',
      processedAt: d['processed_at'] != null
          ? (d['processed_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vehicle_id':                  vehicleId,
    'resident_id':                 residentId,
    'vehicle_registration_number': vehicleRegistrationNumber,
    'method':                      method.name,
    'event_type':                  eventType,
    'rfid_read':                   rfidRead,
    'barrier_id':                  barrierId,
    'processed_by':                processedBy,
    'processed_at':                Timestamp.fromDate(processedAt),
  };
}
