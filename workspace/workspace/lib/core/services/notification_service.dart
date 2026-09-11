import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_service.dart';

class NotificationService {
  Future<void> registerToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      await FirebaseService.instance.ref('users/$uid/fcmTokens/$token').set(true);
    } catch (_) {}
  }
}
