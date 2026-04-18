import '../enums/app_enums.dart';

class FamilyMemberModel {
  final String memberId;
  final String name;
  final FamilyRelation relation;
  final String? dateOfBirth;
  final bool married;
  final bool permanentResident;
  final bool drivingLicenseHolder;
  final String? drivingLicenseNumber;
  final String? drivingLicenseUrl;
  final String? drivingLicenseExpiryDate;

  FamilyMemberModel({
    required this.memberId,
    required this.name,
    required this.relation,
    this.dateOfBirth,
    required this.married,
    required this.permanentResident,
    required this.drivingLicenseHolder,
    this.drivingLicenseNumber,
    this.drivingLicenseUrl,
    this.drivingLicenseExpiryDate,
  });

  factory FamilyMemberModel.fromMap(String id, Map<String, dynamic> m) {
    return FamilyMemberModel(
      memberId:   id,
      name:       m['name'] ?? '',
      relation: FamilyRelation.values.firstWhere(
        (e) => e.name == m['relation'],
        orElse: () => FamilyRelation.other,
      ),
      dateOfBirth:            m['date_of_birth'],
      married:                m['married'] ?? false,
      permanentResident:      m['permanent_resident'] ?? false,
      drivingLicenseHolder:   m['driving_license_holder'] ?? false,
      drivingLicenseNumber:   m['driving_license_number'],
      drivingLicenseUrl:      m['driving_license_url'],
      drivingLicenseExpiryDate: m['driving_license_expiry_date'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name':                       name,
    'relation':                   relation.name,
    'date_of_birth':              dateOfBirth,
    'married':                    married,
    'permanent_resident':         permanentResident,
    'driving_license_holder':     drivingLicenseHolder,
    'driving_license_number':     drivingLicenseNumber,
    'driving_license_url':        drivingLicenseUrl,
    'driving_license_expiry_date': drivingLicenseExpiryDate,
  };

  FamilyMemberModel copyWith({
    String? name,
    FamilyRelation? relation,
    bool? married,
    bool? permanentResident,
    bool? drivingLicenseHolder,
    String? drivingLicenseNumber,
    String? drivingLicenseUrl,
    String? drivingLicenseExpiryDate,
  }) {
    return FamilyMemberModel(
      memberId:               memberId,
      name:                   name ?? this.name,
      relation:               relation ?? this.relation,
      dateOfBirth:            dateOfBirth,
      married:                married ?? this.married,
      permanentResident:      permanentResident ?? this.permanentResident,
      drivingLicenseHolder:   drivingLicenseHolder ?? this.drivingLicenseHolder,
      drivingLicenseNumber:   drivingLicenseNumber ?? this.drivingLicenseNumber,
      drivingLicenseUrl:      drivingLicenseUrl ?? this.drivingLicenseUrl,
      drivingLicenseExpiryDate: drivingLicenseExpiryDate ?? this.drivingLicenseExpiryDate,
    );
  }
}
