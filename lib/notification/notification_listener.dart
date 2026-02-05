import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_click_handler.dart';

class NotificationListener {
  static bool _initialized = false;
  static late String _appId;

  static Future<void> init(String appId) async {
    if (_initialized) return;
    _initialized = true;
    _appId = appId;

    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationClickHandler.handle(
        payload: message.data,
        appId: _appId,
        isOpen: false,
      );
    });

    // Killed click
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      NotificationClickHandler.handle(
        payload: initialMessage.data,
        appId: _appId,
        isOpen: false,
      );
    }
  }

  // Foreground click (local notification)
  static void handleForegroundClick(String payload) {
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
