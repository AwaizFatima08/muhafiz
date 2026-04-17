import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';
import '../core/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final userModel =
          await ref.read(authServiceProvider).getUserModel(user.uid);

      // Save FCM token whenever user logs in or token refreshes
      if (userModel != null) {
        final notifService = ref.read(notificationServiceProvider);
        final firestoreService = ref.read(firestoreServiceProvider);
        await notifService.saveTokenForUser(
          userId: user.uid,
          firestoreService: firestoreService,
        );
      }

      return userModel;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
