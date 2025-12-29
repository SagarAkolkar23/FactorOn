import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static Function(RemoteMessage)? onNotificationReceived;

  static Future<String?> getToken() async {
    try {
      await _messaging.requestPermission();

      final token = await _messaging.getToken();
      debugPrint("FCM_TOKEN: $token");

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📬 Foreground notification: ${message.notification?.title}");
        if (onNotificationReceived != null) {
          onNotificationReceived!(message);
        }
      });

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("📬 Background notification opened: ${message.notification?.title}");
        if (onNotificationReceived != null) {
          onNotificationReceived!(message);
        }
      });

      return token;
    } catch (e) {
      debugPrint("FCM ERROR: $e");
      return null;
    }
  }

  static Future<void> initialize() async {
    await getToken();
  }
}
