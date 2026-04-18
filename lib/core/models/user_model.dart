import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? grade;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.grade,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      grade: data['grade'],
      role: () {
        const legacyMap = {
          'supervisor': 'securitySupervisor',
          'manager': 'securityManager',
          'clerk': 'gateClerk',
          'employer': 'resident',
          'admin': 'superAdmin',
        };
        final s = (data['role'] ?? '').toString();
        final n = legacyMap[s] ?? s;
        return UserRole.values.firstWhere(
          (e) => e.name == n,
          orElse: () => UserRole.resident,
        );
      }(),
      isActive: data['is_active'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastLogin: data['last_login'] != null
          ? (data['last_login'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'grade': grade,
      'role': role.name,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? grade,
    UserRole? role,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      grade: grade ?? this.grade,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
