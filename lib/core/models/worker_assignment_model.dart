import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class SubEmployerEntry {
  final String subEmployerId;
  final String houseNumber;
  final String addedBy;
  final DateTime addedAt;
  final SubEmployerStatus status;

  SubEmployerEntry({
    required this.subEmployerId,
    required this.houseNumber,
    required this.addedBy,
    required this.addedAt,
    required this.status,
  });

  factory SubEmployerEntry.fromMap(Map<String, dynamic> map) {
    return SubEmployerEntry(
      subEmployerId: map['sub_employer_id'] ?? '',
      houseNumber: map['house_number'] ?? '',
      addedBy: map['added_by'] ?? '',
      addedAt: (map['added_at'] as Timestamp).toDate(),
      status: SubEmployerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubEmployerStatus.active,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sub_employer_id': subEmployerId,
      'house_number': houseNumber,
      'added_by': addedBy,
      'added_at': Timestamp.fromDate(addedAt),
      'status': status.name,
    };
  }
}

class WorkerAssignmentModel {
  final String id;
  final String workerId;
  final String employerId;
  final String houseNumber;
  final String arrivalWindow;
  final AssignmentStatus status;
  final String approvedBy;
  final DateTime approvedAt;
  final List<SubEmployerEntry> subEmployers;

  WorkerAssignmentModel({
    required this.id,
    required this.workerId,
    required this.employerId,
    required this.houseNumber,
    required this.arrivalWindow,
    required this.status,
    required this.approvedBy,
    required this.approvedAt,
    required this.subEmployers,
  });

  factory WorkerAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerAssignmentModel(
      id: doc.id,
      workerId: data['workerId'] ?? '',
      employerId: data['employerId'] ?? '',
      houseNumber: data['house_number'] ?? '',
      arrivalWindow: data['arrival_window'] ?? '',
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AssignmentStatus.active,
      ),
      approvedBy: data['approved_by'] ?? '',
      approvedAt: (data['approved_at'] as Timestamp).toDate(),
      subEmployers: (data['sub_employers'] as List<dynamic>? ?? [])
          .map((e) => SubEmployerEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workerId': workerId,
      'employerId': employerId,
      'house_number': houseNumber,
      'arrival_window': arrivalWindow,
      'status': status.name,
      'approved_by': approvedBy,
      'approved_at': Timestamp.fromDate(approvedAt),
      'sub_employers': subEmployers.map((e) => e.toMap()).toList(),
    };
  }
}
