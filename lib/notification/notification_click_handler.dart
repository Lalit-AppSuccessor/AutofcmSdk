import '../src/api_client.dart';
import '../src/logger.dart';
import 'notification_deduper.dart';

class NotificationClickHandler {
  static Future<void> handle({
    required Map<String, dynamic> payload,
    required String appId,
    required bool isOpen,
  }) async {
    final notificationId = payload["notification_id"];
    final userAfId = payload["user_afid"];

    if (notificationId == null || userAfId == null) {
      Logger.log("Notification click ignored → missing fields");
      return;
    }

    if (!NotificationDeduper.shouldProcess(notificationId)) {
      Logger.log("Duplicate notification click ignored");
      return;
    }

    Logger.log("Firing API-C (notification-clicked) | is_open=$isOpen");

    final api = ApiClient(appId); // ✅ FIXED
    await api.callNotificationClicked(
      notificationId: notificationId,
      userAfId: userAfId,
      isOpen: isOpen,
    );
  }
}
