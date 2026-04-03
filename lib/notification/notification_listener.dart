import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../src/logger.dart';
import 'notification_click_handler.dart';

class NotificationListener {
  static bool _initialized = false;
  static late String _appId;

  static Future<void> init(String appId) async {
    Logger.log("NotificationListener entered");
    if (_initialized) return;
    _initialized = true;
    _appId = appId;

    Logger.log("NotificationListener initializing");

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    Logger.log("NotificationListener permission given");
    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationClickHandler.handle(
        payload: message.data,
        appId: _appId,
        isOpen: false,
      );
    });
    Logger.log("NotificationListener message open handled");

    // Killed click
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              Logger.log("getInitialMessage timeout");
              return null;
            },
          );
      Logger.log("getInitialMessage killed handled");
      if (initialMessage != null) {
        NotificationClickHandler.handle(
          payload: initialMessage.data,
          appId: _appId,
          isOpen: false,
        );
      }
      Logger.log("getInitialMessage completed");
    } catch (e) {
      Logger.log("Error in notification listener getInitialMessage: $e");
    }
  }

  // Foreground click (local notification)
  static void handleForegroundClick(String payload) {
    Logger.log("Handle foreground started");
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
