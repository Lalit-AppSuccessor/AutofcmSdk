import 'dart:convert';
import 'package:http/http.dart' as http;
import 'network_manager.dart';
import 'logger.dart';

class ApiClient {
  final String appId;
  ApiClient(this.appId);

  static const baseUrl = "https://pingautobe.boostproductivity.online";

  // Common safe POST method
  Future<void> _safePost({
    required String url,
    required Map<String, dynamic> body,
  }) async {
    // 🚫 Skip if offline
    if (!NetworkManager().isOnline) {
      Logger.log("❌ No internet → Skipping API: $url");
      return;
    }

    try {
      await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
    } catch (e) {
      // ❌ Do NOT throw
      Logger.log("API Error ($url): $e");
    }
  }

  Future<void> callAppInstall({
    required String afId,
    required String fcmToken,
  }) async {
    await _safePost(
      url: "$baseUrl/webhook/app-install?app_id=$appId",
      body: {"afId": afId, "fcmToken": fcmToken},
    );
  }

  Future<void> callRegisterDevice({
    required String afId,
    required String uid,
    required String fcmToken,
  }) async {
    await _safePost(
      url: "$baseUrl/webhook/register-device?app_id=$appId",
      body: {"afId": afId, "userId": uid, "fcmToken": fcmToken},
    );
  }

  Future<void> callNotificationClicked({
    required String notificationId,
    required String userAfId,
    required bool isOpen,
  }) async {
    await _safePost(
      url: "$baseUrl/datatrack/notification-clicked?app_id=$appId",
      body: {
        "notification_id": notificationId,
        "user_afid": userAfId,
        "is_open": isOpen,
      },
    );
  }
}
