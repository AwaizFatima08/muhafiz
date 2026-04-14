import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class NotificationModel {
  final String id;
  final String recipientUserId;
  final String recipientEmployerId;
  final String employeeId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String channel;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.recipientEmployerId,
    required this.employeeId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.channel,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientUserId: data['recipientUserId'] ?? '',
      recipientEmployerId: data['recipientEmployerId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.entry,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      channel: data['channel'] ?? 'inApp',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientUserId': recipientUserId,
      'recipientEmployerId': recipientEmployerId,
      'employeeId': employeeId,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': isRead,
      'channel': channel,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      recipientUserId: recipientUserId,
      recipientEmployerId: recipientEmployerId,
      employeeId: employeeId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      channel: channel,
      createdAt: createdAt,
    );
  }
}
