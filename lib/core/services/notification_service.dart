import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

// ─── Background message handler (must be top-level function) ─────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by this point.
  // Flutter Local Notifications handles display automatically on Android
  // when the app is in the background — no extra code needed here.
}

// ─── Notification Service ─────────────────────────────────────────────────────

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'muhafiz_gate_events';
  static const _channelName = 'Gate Events';
  static const _channelDesc =
      'Notifications for worker entry and exit events';

  // ─── Initialize ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Foreground notification presentation (iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }

  // ─── Foreground message handler ────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── FCM Token ─────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> saveTokenForUser({
    required String userId,
    required FirestoreService firestoreService,
  }) async {
    final token = await getToken();
    if (token == null) return;

    await firestoreService.updateFcmToken(
      userId: userId,
      token: token,
    );

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      await firestoreService.updateFcmToken(
        userId: userId,
        token: newToken,
      );
    });
  }
}

