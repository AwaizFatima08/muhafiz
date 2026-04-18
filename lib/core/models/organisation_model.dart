import 'package:cloud_firestore/cloud_firestore.dart';

class OrganisationModel {
  final String id;
  final String name;
  final String type; // township | contractor | company
  final String? contactPerson;
  final String? contactNumber;
  final bool isActive;
  final List<String> grades;
  final List<String> departments;
  final String? createdBy;
  final DateTime createdAt;

  OrganisationModel({
    required this.id,
    required this.name,
    required this.type,
    this.contactPerson,
    this.contactNumber,
    required this.isActive,
    this.grades = const [],
    this.departments = const [],
    this.createdBy,
    required this.createdAt,
  });

  factory OrganisationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrganisationModel(
      id:            doc.id,
      name:          d['name'] ?? '',
      type:          d['type'] ?? '',
      contactPerson: d['contact_person'],
      contactNumber: d['contact_number'],
      isActive:      d['is_active'] ?? true,
      grades:        List<String>.from(d['grades'] ?? []),
      departments:   List<String>.from(d['departments'] ?? []),
      createdBy:     d['created_by'],
      createdAt: d['created_at'] != null
          ? (d['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':           name,
    'type':           type,
    'contact_person': contactPerson,
    'contact_number': contactNumber,
    'is_active':      isActive,
    'grades':         grades,
    'departments':    departments,
    'created_by':     createdBy,
    'created_at':     Timestamp.fromDate(createdAt),
  };

  OrganisationModel copyWith({
    String? name,
    String? type,
    String? contactPerson,
    String? contactNumber,
    bool? isActive,
  }) {
    return OrganisationModel(
      id:            id,
      name:          name ?? this.name,
      type:          type ?? this.type,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      isActive:      isActive ?? this.isActive,
      createdBy:     createdBy,
      createdAt:     createdAt,
    );
  }
}
