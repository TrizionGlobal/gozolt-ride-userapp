import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import '../providers/dio_provider.dart';
import '../providers/storage_provider.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Ref _ref;

  NotificationService(this._ref);

  Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title}');
        // You could show a local notification here if needed
      }
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Handle navigation here if message contains data
    });

    // Get and save token
    await updateToken();
  }

  Future<void> updateToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          debugPrint("APNS token not available yet. Waiting 2 seconds...");
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _fcm.getAPNSToken();
        }
        if (apnsToken == null) {
          debugPrint("Skipping FCM token retrieval: APNS token is null (likely on iOS Simulator).");
          return;
        }
      }
      
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Don't try to save to backend if user is not logged in
      final storage = _ref.read(secureStorageProvider);
      if (!(await storage.hasTokens())) {
        debugPrint("Skipping FCM token save: User is not logged in.");
        return;
      }

      final dio = _ref.read(dioProvider);
      await dio.patch(
        '/users/me/fcm-token',
        data: {'token': token},
      );
      debugPrint("FCM Token saved to backend successfully");
    } catch (e) {
      debugPrint("Error saving FCM token to backend: $e");
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

// Top-level background handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
