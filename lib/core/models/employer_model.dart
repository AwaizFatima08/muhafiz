import 'package:cloud_firestore/cloud_firestore.dart';

class EmployerModel {
  final String id;
  final String userId;
  final String name;
  final String department;
  final String unit;
  final String grade;
  final String houseNumber;
  final String blockSector;
  final String phoneMobile;
  final String phoneExtension;
  final String emergencyContact;
  final String? fcmToken;
  final bool isActive;
  final DateTime createdAt;

  EmployerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.department,
    required this.unit,
    required this.grade,
    required this.houseNumber,
    required this.blockSector,
    required this.phoneMobile,
    required this.phoneExtension,
    required this.emergencyContact,
    this.fcmToken,
    required this.isActive,
    required this.createdAt,
  });

  factory EmployerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmployerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['employer_name'] ?? data['name'] ?? '',
      department: data['department'] ?? '',
      unit: data['unit'] ?? '',
      grade: data['grade'] ?? '',
      houseNumber: data['house_number'] ?? data['houseNumber'] ?? '',
      blockSector: data['blockSector'] ?? '',
      phoneMobile: data['phone_mobile'] ?? data['phoneMobile'] ?? '',
      phoneExtension: data['phone_extension'] ?? data['phoneExtension'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      fcmToken: data['fcmToken'],
      isActive: data['is_active'] ?? data['isActive'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'department': department,
      'unit': unit,
      'grade': grade,
      'houseNumber': houseNumber,
      'blockSector': blockSector,
      'phoneMobile': phoneMobile,
      'phoneExtension': phoneExtension,
      'emergencyContact': emergencyContact,
      'fcmToken': fcmToken,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
