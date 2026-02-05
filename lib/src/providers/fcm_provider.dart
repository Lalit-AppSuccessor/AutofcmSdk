// fcm_provider.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmProvider {
  static Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }
}
