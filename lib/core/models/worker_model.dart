import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class WorkerModel {
  final String id;
  final String cardNumber;
  final String workerName;
  final String cnic;
  final DateTime? cnicExpiry;
  final DateTime? dob;
  final String? photoUrl;
  final WorkerType workerType;
  final NatureOfService natureOfService;
  final bool policeVerified;
  final DateTime? policeVerifDate;
  final String? policeVerifRefNumber;
  final DateTime? policeVerifExpiry;
  final String? cnicPhotoUrlFront;
  final String? cnicPhotoUrlBack;
  final String? policeVerificationPhotoUrl;
  final DateTime? cardExpiryDate;
  final String? cardExpiryNotified;
  final String? registeredByUid;
  final String? registeredByRole;
  final DateTime? approvedAt;
  final String? approvedBy;
  final WorkerStatus status;
  final String? blacklistReason;
  final String? blacklistedBy;
  final DateTime? blacklistedAt;
  final String qrCodeValue;
  final bool qrInvalidated;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkerModel({
    required this.id,
    required this.cardNumber,
    required this.workerName,
    required this.cnic,
    this.cnicExpiry,
    this.dob,
    this.photoUrl,
    required this.workerType,
    required this.natureOfService,
    required this.policeVerified,
    this.policeVerifDate,
    this.policeVerifRefNumber,
    this.policeVerifExpiry,
    this.cnicPhotoUrlFront,
    this.cnicPhotoUrlBack,
    this.policeVerificationPhotoUrl,
    this.cardExpiryDate,
    this.cardExpiryNotified,
    this.registeredByUid,
    this.registeredByRole,
    this.approvedAt,
    this.approvedBy,
    required this.status,
    this.blacklistReason,
    this.blacklistedBy,
    this.blacklistedAt,
    required this.qrCodeValue,
    required this.qrInvalidated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerModel(
      id: doc.id,
      cardNumber: data['card_number'] ?? '',
      workerName: data['worker_name'] ?? data['name'] ?? '',
      cnic: data['cnic'] ?? '',
      cnicExpiry: data['cnic_expiry'] != null
          ? (data['cnic_expiry'] as Timestamp).toDate() : null,
      dob: data['dob'] != null
          ? (data['dob'] as Timestamp).toDate() : null,
      photoUrl: data['photo_url'],
      workerType: WorkerType.values.firstWhere(
        (e) => e.name == data['worker_type'],
        orElse: () => WorkerType.other,
      ),
      natureOfService: NatureOfService.values.firstWhere(
        (e) => e.name == data['nature_of_service'],
        orElse: () => NatureOfService.dayCare,
      ),
      policeVerified: data['police_verified'] ?? false,
      policeVerifDate: data['police_verification_date'] != null
          ? (data['police_verification_date'] as Timestamp).toDate() : null,
      policeVerifRefNumber: data['police_verification_ref_number'],
      policeVerifExpiry: data['police_verif_expiry'] != null
          ? (data['police_verif_expiry'] as Timestamp).toDate() : null,
      cnicPhotoUrlFront: data['cnic_photo_url_front'],
      cnicPhotoUrlBack: data['cnic_photo_url_back'],
      policeVerificationPhotoUrl: data['police_verification_photo_url'],
      cardExpiryDate: data['card_expiry_date'] != null
          ? (data['card_expiry_date'] as Timestamp).toDate() : null,
      cardExpiryNotified: data['card_expiry_notified'],
      registeredByUid: data['registered_by_uid'],
      registeredByRole: data['registered_by_role'],
      approvedAt: data['approved_at'] != null
          ? (data['approved_at'] as Timestamp).toDate() : null,
      approvedBy: data['approved_by'],
      status: WorkerStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WorkerStatus.pendingApproval,
      ),
      blacklistReason: data['blacklist_reason'],
      blacklistedBy: data['blacklisted_by'],
      blacklistedAt: data['blacklisted_at'] != null
          ? (data['blacklisted_at'] as Timestamp).toDate() : null,
      qrCodeValue: data['qr_code_value'] ?? '',
      qrInvalidated: data['qr_code_invalidated'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'card_number': cardNumber,
      'worker_name': workerName,
      'cnic': cnic,
      'cnic_expiry': cnicExpiry != null
          ? Timestamp.fromDate(cnicExpiry!) : null,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'photo_url': photoUrl,
      'worker_type': workerType.name,
      'nature_of_service': natureOfService.name,
      'police_verified': policeVerified,
      'police_verification_date': policeVerifDate != null
          ? Timestamp.fromDate(policeVerifDate!) : null,
      'police_verification_ref_number': policeVerifRefNumber,
      'police_verif_expiry': policeVerifExpiry != null
          ? Timestamp.fromDate(policeVerifExpiry!) : null,
      'cnic_photo_url_front': cnicPhotoUrlFront,
      'cnic_photo_url_back': cnicPhotoUrlBack,
      'police_verification_photo_url': policeVerificationPhotoUrl,
      'card_expiry_date': cardExpiryDate != null
          ? Timestamp.fromDate(cardExpiryDate!) : null,
      'card_expiry_notified': cardExpiryNotified,
      'registered_by_uid': registeredByUid,
      'registered_by_role': registeredByRole,
      'approved_at': approvedAt != null
          ? Timestamp.fromDate(approvedAt!) : null,
      'approved_by': approvedBy,
      'status': status.name,
      'blacklist_reason': blacklistReason,
      'blacklisted_by': blacklistedBy,
      'blacklisted_at': blacklistedAt != null
          ? Timestamp.fromDate(blacklistedAt!) : null,
      'qr_code_value': qrCodeValue,
      'qr_code_invalidated': qrInvalidated,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  WorkerModel copyWith({
    String? workerName,
    String? photoUrl,
    bool? policeVerified,
    DateTime? policeVerifDate,
    String? policeVerifRefNumber,
    DateTime? policeVerifExpiry,
    WorkerStatus? status,
    String? blacklistReason,
    String? blacklistedBy,
    DateTime? blacklistedAt,
    bool? qrInvalidated,
    DateTime? updatedAt,
  }) {
    return WorkerModel(
      id: id,
      cardNumber: cardNumber,
      workerName: workerName ?? this.workerName,
      cnic: cnic,
      cnicExpiry: cnicExpiry,
      dob: dob,
      photoUrl: photoUrl ?? this.photoUrl,
      workerType: workerType,
      natureOfService: natureOfService,
      policeVerified: policeVerified ?? this.policeVerified,
      policeVerifDate: policeVerifDate ?? this.policeVerifDate,
      policeVerifRefNumber: policeVerifRefNumber ?? this.policeVerifRefNumber,
      policeVerifExpiry: policeVerifExpiry ?? this.policeVerifExpiry,
      status: status ?? this.status,
      blacklistReason: blacklistReason ?? this.blacklistReason,
      blacklistedBy: blacklistedBy ?? this.blacklistedBy,
      blacklistedAt: blacklistedAt ?? this.blacklistedAt,
      qrCodeValue: qrCodeValue,
      qrInvalidated: qrInvalidated ?? this.qrInvalidated,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
