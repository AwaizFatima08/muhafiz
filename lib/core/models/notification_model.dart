import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class NotificationModel {
  final String id;
  final String recipientUserId;
  final String recipientResidentId;
  final String? workerId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String channel;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.recipientResidentId,
    this.workerId,
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
      recipientUserId: data['recipient_user_id'] ?? data['recipientUserId'] ?? '',
      recipientResidentId: data['recipient_resident_id'] ?? data['recipientEmployerId'] ?? '',
      workerId: data['workerId'] ?? data['worker_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.entry,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['is_read'] ?? data['isRead'] ?? false,
      channel: data['channel'] ?? 'inApp',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipient_user_id': recipientUserId,
      'recipient_resident_id': recipientResidentId,
      'workerId': workerId,
      'type': type.name,
      'title': title,
      'body': body,
      'is_read': isRead,
      'channel': channel,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      recipientUserId: recipientUserId,
      recipientResidentId: recipientResidentId,
      workerId: workerId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      channel: channel,
      createdAt: createdAt,
    );
  }
}
