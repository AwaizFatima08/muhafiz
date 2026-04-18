import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String sentBy;      // security manager uid
  final DateTime? sentAt;
  final String audience;    // all | residents | security
  final bool fcmSent;
  final DateTime? fcmSentAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.sentBy,
    this.sentAt,
    required this.audience,
    this.fcmSent = false,
    this.fcmSentAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id:       doc.id,
      title:    d['title'] ?? '',
      body:     d['body'] ?? '',
      sentBy:   d['sent_by'] ?? '',
      sentAt:   d['sent_at'] != null
          ? (d['sent_at'] as Timestamp).toDate() : null,
      audience: d['audience'] ?? 'all',
      fcmSent:  d['fcm_sent'] ?? false,
      fcmSentAt: d['fcm_sent_at'] != null
          ? (d['fcm_sent_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':       title,
    'body':        body,
    'sent_by':     sentBy,
    'sent_at':     sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    'audience':    audience,
    'fcm_sent':    fcmSent,
    'fcm_sent_at': fcmSentAt != null ? Timestamp.fromDate(fcmSentAt!) : null,
  };
}
