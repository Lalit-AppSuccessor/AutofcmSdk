import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../src/logger.dart';
import 'notification_click_handler.dart';

class NotificationListener {
  static bool _initialized = false;
  static late String _appId;

  static Future<void> init(String appId) async {
    Logger.log("notify entered stage 0");
    if (_initialized) return;
    _initialized = true;
    _appId = appId;

    Logger.log("notify entered stage 1");

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    Logger.log("notify permission given");
    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationClickHandler.handle(
        payload: message.data,
        appId: _appId,
        isOpen: false,
      );
    });
    Logger.log("notify message openhandled stage 2");

    // Killed click
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      Logger.log("notify killed stage");
      if (initialMessage != null) {
        NotificationClickHandler.handle(
          payload: initialMessage.data,
          appId: _appId,
          isOpen: false,
        );
      }
      Logger.log("All done");
    } catch (e) {
      Logger.log("Error in notification listener init: $e");
    }
  }

  // Foreground click (local notification)
  static void handleForegroundClick(String payload) {
    Logger.log("notifiy foreground stage 1");
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        NotificationClickHandler.handle(
          payload: decoded,
          appId: _appId,
          isOpen: true,
        );
      }
    } catch (_) {}
  }
}
