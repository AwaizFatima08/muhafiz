import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class VehicleModel {
  final String id;
  final String residentId;
  final String vehicleRegistrationNumber;
  final String? make;
  final String? model;
  final String? colour;
  final VehicleType vehicleType;
  final String? vehicleRegistrationCardPhotoUrl;
  final String? rfidTagId;       // future — populated when RFID issued
  final bool isActive;
  final String? registeredBy;
  final DateTime registeredAt;

  VehicleModel({
    required this.id,
    required this.residentId,
    required this.vehicleRegistrationNumber,
    this.make,
    this.model,
    this.colour,
    required this.vehicleType,
    this.vehicleRegistrationCardPhotoUrl,
    this.rfidTagId,
    required this.isActive,
    this.registeredBy,
    required this.registeredAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id:                               doc.id,
      residentId:                       d['resident_id'] ?? '',
      vehicleRegistrationNumber:        d['vehicle_registration_number'] ?? '',
      make:                             d['make'],
      model:                            d['model'],
      colour:                           d['colour'],
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == d['vehicle_type'],
        orElse: () => VehicleType.car,
      ),
      vehicleRegistrationCardPhotoUrl:  d['vehicle_registration_card_photo_url'],
      rfidTagId:                        d['rfid_tag_id'],
      isActive:                         d['is_active'] ?? true,
      registeredBy:                     d['registered_by'],
      registeredAt: d['registered_at'] != null
          ? (d['registered_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'resident_id':                        residentId,
    'vehicle_registration_number':        vehicleRegistrationNumber,
    'make':                               make,
    'model':                              model,
    'colour':                             colour,
    'vehicle_type':                       vehicleType.name,
    'vehicle_registration_card_photo_url': vehicleRegistrationCardPhotoUrl,
    'rfid_tag_id':                        rfidTagId,
    'is_active':                          isActive,
    'registered_by':                      registeredBy,
    'registered_at':                      Timestamp.fromDate(registeredAt),
  };
}
