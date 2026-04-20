import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../core/models/user_model.dart';

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserModelProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    yield null;
    return;
  }
  final userModel =
      await ref.read(authServiceProvider).getUserModel(user.uid);
  if (userModel != null && !kIsWeb) {
    final notifService     = ref.read(notificationServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    // B2: FCM token save (already guarded by kIsWeb inside service)
    await notifService.saveTokenForUser(
      userId: user.uid,
      firestoreService: firestoreService,
    );
    // C9 FIX: subscribe to the correct FCM topics for this role so
    // announcements reach the right audience.
    await notifService.subscribeToTopics(userModel.role.name);
  }
  yield userModel;
});
