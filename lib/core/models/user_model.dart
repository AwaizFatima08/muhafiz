import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
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
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.employer,
      ),
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null
          ? Timestamp.fromDate(lastLogin!)
          : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
