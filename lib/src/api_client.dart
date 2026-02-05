import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String appId;
  ApiClient(this.appId);

  static const baseUrl = "https://pingautobe.boostproductivity.online";

  Future<void> callAppInstall({
    required String afId,
    required String fcmToken,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/webhook/app-install?app_id=$appId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"afId": afId, "fcmToken": fcmToken}),
    );
  }

  Future<void> callRegisterDevice({
    required String afId,
    required String uid,
    required String fcmToken,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/webhook/register-device?app_id=$appId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"afId": afId, "userId": uid, "fcmToken": fcmToken}),
    );
  }

  Future<void> callNotificationClicked({
    required String notificationId,
    required String userAfId,
    required bool isOpen,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/datatrack/notification-clicked?app_id=$appId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "notification_id": notificationId,
        "user_afid": userAfId,
        "is_open": isOpen,
      }),
    );
  }
}
