import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class PetModel {
  final String id;
  final String residentId;
  final String requestedBy;
  final PetType petType;
  final String? petName;
  final String? breed;
  final bool vaccinationStatus;
  final String? vaccinationDocUrl;
  final String? photoUrl;
  final PetStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime requestInitiatedAt;

  PetModel({
    required this.id,
    required this.residentId,
    required this.requestedBy,
    required this.petType,
    this.petName,
    this.breed,
    required this.vaccinationStatus,
    this.vaccinationDocUrl,
    this.photoUrl,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.requestInitiatedAt,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PetModel(
      id:           doc.id,
      residentId:   d['resident_id'] ?? '',
      requestedBy:  d['requested_by'] ?? '',
      petType: PetType.values.firstWhere(
        (e) => e.name == d['pet_type'],
        orElse: () => PetType.other,
      ),
      petName:             d['pet_name'],
      breed:               d['breed'],
      vaccinationStatus:   d['vaccination_status'] ?? false,
      vaccinationDocUrl:   d['vaccination_doc_url'],
      photoUrl:            d['photo_url'],
      status: PetStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PetStatus.pending,
      ),
      approvedBy:  d['approved_by'],
      approvedAt:  d['approved_at'] != null
          ? (d['approved_at'] as Timestamp).toDate() : null,
      requestInitiatedAt: d['request_initiated_at'] != null
          ? (d['request_initiated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'resident_id':          residentId,
    'requested_by':         requestedBy,
    'pet_type':             petType.name,
    'pet_name':             petName,
    'breed':                breed,
    'vaccination_status':   vaccinationStatus,
    'vaccination_doc_url':  vaccinationDocUrl,
    'photo_url':            photoUrl,
    'status':               status.name,
    'approved_by':          approvedBy,
    'approved_at': approvedAt != null
        ? Timestamp.fromDate(approvedAt!) : null,
    'request_initiated_at': Timestamp.fromDate(requestInitiatedAt),
  };

  PetModel copyWith({PetStatus? status, String? approvedBy, DateTime? approvedAt}) {
    return PetModel(
      id:                  id,
      residentId:          residentId,
      requestedBy:         requestedBy,
      petType:             petType,
      petName:             petName,
      breed:               breed,
      vaccinationStatus:   vaccinationStatus,
      vaccinationDocUrl:   vaccinationDocUrl,
      photoUrl:            photoUrl,
      status:              status ?? this.status,
      approvedBy:          approvedBy ?? this.approvedBy,
      approvedAt:          approvedAt ?? this.approvedAt,
      requestInitiatedAt:  requestInitiatedAt,
    );
  }
}
