import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class NotificationPrefs {
  final bool workerEntry;
  final bool workerExit;
  final bool guestArrival;
  final bool announcements;

  const NotificationPrefs({
    this.workerEntry = true,
    this.workerExit = true,
    this.guestArrival = true,
    this.announcements = true,
  });

  factory NotificationPrefs.fromMap(dynamic raw) {
    if (raw == null || raw is! Map) return const NotificationPrefs();
    final m = Map<String, dynamic>.from(raw);
    return NotificationPrefs(
      workerEntry:   m['worker_entry']   ?? m['notification_1'] ?? true,
      workerExit:    m['worker_exit']    ?? true,
      guestArrival:  m['guest_arrival']  ?? true,
      announcements: m['announcements']  ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'worker_entry':   workerEntry,
    'worker_exit':    workerExit,
    'guest_arrival':  guestArrival,
    'announcements':  announcements,
  };
}

class ResidentModel {
  final String id;
  final String name;
  final String? residentNumber;
  final String? employeeNumber;
  final String? organisationId;
  final String houseNumber;
  final String? block;
  final String? section;
  final String? sector;
  final String? unit;
  final String? department;
  final String? grade;
  final String phoneMobile;
  final String? phoneLandline;
  final String? cnic;
  // B3 FIX: dob field added — was missing from model entirely.
  // Stored as ISO-8601 string under 'date_of_birth' in Firestore,
  // matching the key used by registration/edit screens.
  final String? dob;
  final String? cnicPhotoUrl;
  final String? drivingLicenseNumber;
  final String? drivingLicensePhotoUrl;
  final String? drivingLicenseExpiryDate;
  final String? clinicPhotoUrl;
  final String? fcmToken;
  final NotificationPrefs notificationPrefs;
  final bool isActive;
  final ResidentStatus status;
  final String? registeredByUid;
  final String? registeredByRole;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime createdAt;

  ResidentModel({
    required this.id,
    required this.name,
    this.residentNumber,
    this.employeeNumber,
    this.organisationId,
    required this.houseNumber,
    this.block,
    this.section,
    this.sector,
    this.unit,
    this.department,
    this.grade,
    required this.phoneMobile,
    this.phoneLandline,
    this.cnic,
    this.dob,
    this.cnicPhotoUrl,
    this.drivingLicenseNumber,
    this.drivingLicensePhotoUrl,
    this.drivingLicenseExpiryDate,
    this.clinicPhotoUrl,
    this.fcmToken,
    this.notificationPrefs = const NotificationPrefs(),
    required this.isActive,
    required this.status,
    this.registeredByUid,
    this.registeredByRole,
    this.approvedAt,
    this.approvedBy,
    required this.createdAt,
  });

  factory ResidentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ResidentModel(
      id:                       doc.id,
      name:                     d['name'] ?? '',
      residentNumber:           d['resident_number'],
      employeeNumber:           d['employee_number'],
      organisationId:           d['organisation_id'],
      houseNumber:              d['house_number'] ?? '',
      block:                    d['block'],
      section:                  d['section'],
      sector:                   d['sector'],
      unit:                     d['unit'],
      department:               d['department'],
      grade:                    d['grade'],
      phoneMobile:              d['phone_mobile'] ?? '',
      phoneLandline:            d['phone_landline'],
      cnic:                     d['cnic']?.toString(),
      dob:                      d['date_of_birth'],
      cnicPhotoUrl:             d['cnic_photo_url'],
      drivingLicenseNumber:     d['driving_license_number'],
      drivingLicensePhotoUrl:   d['driving_license_photo_url'],
      drivingLicenseExpiryDate: d['driving_license_expiry_date'],
      clinicPhotoUrl:           d['clinic_photo_url'],
      fcmToken:                 d['fcm_token'],
      notificationPrefs: NotificationPrefs.fromMap(d['notification_pref']),
      isActive:          d['is_active'] ?? false,
      status: ResidentStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => ResidentStatus.pending,
      ),
      registeredByUid:  d['registered_by_uid'],
      registeredByRole: d['registered_by_role'],
      approvedAt: d['approved_at'] != null
          ? (d['approved_at'] as Timestamp).toDate() : null,
      approvedBy: d['approved_by'],
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':                        name,
    'resident_number':             residentNumber,
    'employee_number':             employeeNumber,
    'organisation_id':             organisationId,
    'house_number':                houseNumber,
    'block':                       block,
    'section':                     section,
    'sector':                      sector,
    'unit':                        unit,
    'department':                  department,
    'grade':                       grade,
    'phone_mobile':                phoneMobile,
    'phone_landline':              phoneLandline,
    'cnic':                        cnic,
    'date_of_birth':               dob,
    'cnic_photo_url':              cnicPhotoUrl,
    'driving_license_number':      drivingLicenseNumber,
    'driving_license_photo_url':   drivingLicensePhotoUrl,
    'driving_license_expiry_date': drivingLicenseExpiryDate,
    'clinic_photo_url':            clinicPhotoUrl,
    'fcm_token':                   fcmToken,
    'notification_pref':           notificationPrefs.toMap(),
    'is_active':                   isActive,
    'status':                      status.name,
    'registered_by_uid':           registeredByUid,
    'registered_by_role':          registeredByRole,
    'approved_at': approvedAt != null
        ? Timestamp.fromDate(approvedAt!) : null,
    'approved_by':                 approvedBy,
    'created_at':                  Timestamp.fromDate(createdAt),
  };

  ResidentModel copyWith({
    String? name,
    String? residentNumber,
    String? employeeNumber,
    String? organisationId,
    String? houseNumber,
    String? block,
    String? section,
    String? sector,
    String? unit,
    String? department,
    String? grade,
    String? phoneMobile,
    String? phoneLandline,
    String? dob,
    String? fcmToken,
    NotificationPrefs? notificationPrefs,
    bool? isActive,
    ResidentStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return ResidentModel(
      id:                       id,
      name:                     name ?? this.name,
      residentNumber:           residentNumber ?? this.residentNumber,
      employeeNumber:           employeeNumber ?? this.employeeNumber,
      organisationId:           organisationId ?? this.organisationId,
      houseNumber:              houseNumber ?? this.houseNumber,
      block:                    block ?? this.block,
      section:                  section ?? this.section,
      sector:                   sector ?? this.sector,
      unit:                     unit ?? this.unit,
      department:               department ?? this.department,
      grade:                    grade ?? this.grade,
      phoneMobile:              phoneMobile ?? this.phoneMobile,
      phoneLandline:            phoneLandline ?? this.phoneLandline,
      cnic:                     cnic,
      dob:                      dob ?? this.dob,
      cnicPhotoUrl:             cnicPhotoUrl,
      drivingLicenseNumber:     drivingLicenseNumber,
      drivingLicensePhotoUrl:   drivingLicensePhotoUrl,
      drivingLicenseExpiryDate: drivingLicenseExpiryDate,
      clinicPhotoUrl:           clinicPhotoUrl,
      fcmToken:                 fcmToken ?? this.fcmToken,
      notificationPrefs:        notificationPrefs ?? this.notificationPrefs,
      isActive:                 isActive ?? this.isActive,
      status:                   status ?? this.status,
      registeredByUid:          registeredByUid,
      registeredByRole:         registeredByRole,
      approvedAt:               approvedAt ?? this.approvedAt,
      approvedBy:               approvedBy ?? this.approvedBy,
      createdAt:                createdAt,
    );
  }
}
