import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class GuestVisitModel {
  final String id;
  final String visitorName;
  final String visitorCnic;       // stored as string, int in Firestore handled
  final String visitingResidentId;
  final String residentName;
  final String? residentEmployeeNumber;
  final String houseNumber;
  final String purpose;
  final String? vehicleRegistrationNumber;
  final DateTime entryTime;
  final DateTime expiresAt;       // entryTime + 24h
  final DateTime? exitTime;
  final String slipQrValue;
  final GuestVisitStatus status;
  final String? gateClerkId;

  GuestVisitModel({
    required this.id,
    required this.visitorName,
    required this.visitorCnic,
    required this.visitingResidentId,
    required this.residentName,
    this.residentEmployeeNumber,
    required this.houseNumber,
    required this.purpose,
    this.vehicleRegistrationNumber,
    required this.entryTime,
    required this.expiresAt,
    this.exitTime,
    required this.slipQrValue,
    required this.status,
    this.gateClerkId,
  });

  factory GuestVisitModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GuestVisitModel(
      id:                        doc.id,
      visitorName:               d['visitor_name'] ?? '',
      visitorCnic:               d['visitor_cnic']?.toString() ?? '',
      visitingResidentId:        d['visiting_resident_id'] ?? '',
      residentName:              d['resident_name'] ?? '',
      residentEmployeeNumber:    d['resident_employee_number'],
      houseNumber:               d['house_number'] ?? '',
      purpose:                   d['purpose'] ?? '',
      vehicleRegistrationNumber: d['vehicle_registration_number'],
      entryTime: d['entry_time'] != null
          ? (d['entry_time'] as Timestamp).toDate() : DateTime.now(),
      expiresAt: d['espires_at'] != null      // note: Firestore has typo espires_at
          ? (d['espires_at'] as Timestamp).toDate()
          : d['expires_at'] != null
              ? (d['expires_at'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(hours: 24)),
      exitTime: d['exit_time'] != null
          ? (d['exit_time'] as Timestamp).toDate() : null,
      slipQrValue: d['slip_qr_value'] ?? '',
      status: GuestVisitStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => GuestVisitStatus.inside,
      ),
      gateClerkId: d['gate_clerk_id'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'visitor_name':                visitorName,
    'visitor_cnic':                visitorCnic,
    'visiting_resident_id':        visitingResidentId,
    'resident_name':               residentName,
    'resident_employee_number':    residentEmployeeNumber,
    'house_number':                houseNumber,
    'purpose':                     purpose,
    'vehicle_registration_number': vehicleRegistrationNumber,
    'entry_time':                  Timestamp.fromDate(entryTime),
    'espires_at':                  Timestamp.fromDate(expiresAt),
    'exit_time': exitTime != null ? Timestamp.fromDate(exitTime!) : null,
    'slip_qr_value':               slipQrValue,
    'status':                      status.name,
    'gate_clerk_id':               gateClerkId,
  };

  GuestVisitModel copyWith({
    DateTime? exitTime,
    GuestVisitStatus? status,
  }) {
    return GuestVisitModel(
      id:                        id,
      visitorName:               visitorName,
      visitorCnic:               visitorCnic,
      visitingResidentId:        visitingResidentId,
      residentName:              residentName,
      residentEmployeeNumber:    residentEmployeeNumber,
      houseNumber:               houseNumber,
      purpose:                   purpose,
      vehicleRegistrationNumber: vehicleRegistrationNumber,
      entryTime:                 entryTime,
      expiresAt:                 expiresAt,
      exitTime:                  exitTime ?? this.exitTime,
      slipQrValue:               slipQrValue,
      status:                    status ?? this.status,
      gateClerkId:               gateClerkId,
    );
  }
}
