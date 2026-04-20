import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

// ─── Background message handler (must be top-level function) ─────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized at this point.
  // Flutter Local Notifications handles display automatically on Android.
}

// ─── Notification Service ─────────────────────────────────────────────────────

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'muhafiz_gate_events';
  static const _channelName = 'Gate Events';
  static const _channelDesc =
      'Notifications for worker entry and exit events';

  // C9 FIX: FCM topics for broadcast announcements.
  // All residents subscribe to 'residents', all security staff to 'security',
  // everyone subscribes to 'all'.
  static const _topicAll       = 'all';
  static const _topicResidents = 'residents';
  static const _topicSecurity  = 'security';

  // ─── Initialize ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // B2: skip on web — FCM token/permission APIs require VAPID key on web
    if (kIsWeb) return;

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

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }

  // ─── Topic Subscriptions ───────────────────────────────────────────────

  /// C9 FIX: subscribe device to the correct FCM topics based on role.
  /// Called after login so announcements reach the right audience.
  Future<void> subscribeToTopics(String role) async {
    if (kIsWeb) return;
    // Everyone gets 'all'
    await _fcm.subscribeToTopic(_topicAll);
    if (role == 'resident') {
      await _fcm.subscribeToTopic(_topicResidents);
    } else {
      // gateClerk, securitySupervisor, securityManager, superAdmin
      await _fcm.subscribeToTopic(_topicSecurity);
    }
  }

  /// Unsubscribe from all topics on sign-out.
  Future<void> unsubscribeFromTopics() async {
    if (kIsWeb) return;
    await _fcm.unsubscribeFromTopic(_topicAll);
    await _fcm.unsubscribeFromTopic(_topicResidents);
    await _fcm.unsubscribeFromTopic(_topicSecurity);
  }

  // ─── Foreground message handler ────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    if (kIsWeb) return;
    final notification = message.notification;
    final android      = message.notification?.android;
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
    if (kIsWeb) return null;
    return await _fcm.getToken();
  }

  Future<void> saveTokenForUser({
    required String userId,
    required FirestoreService firestoreService,
  }) async {
    if (kIsWeb) return;
    final token = await getToken();
    if (token == null) return;

    await firestoreService.updateFcmToken(
      userId: userId,
      token: token,
    );

    _fcm.onTokenRefresh.listen((newToken) async {
      await firestoreService.updateFcmToken(
        userId: userId,
        token: newToken,
      );
    });
  }
}
