// fcm_provider.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../logger.dart';

class FcmProvider {
  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      Logger.log("FCM error: $e");
      return null;
    }
  }
}
