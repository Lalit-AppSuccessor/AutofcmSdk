import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_click_handler.dart';
import '../inapp/in_app_notification_manager.dart';
import '../src/logger.dart';

class FcmNotificationListener {
  static bool _initialized = false;
  static late String _appId;

  static Future<void> init(String appId) async {
    if (_initialized) return;
    _initialized = true;
    _appId = appId;

    // ── Background click ─────────────────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _maybeHandleInApp(message.data);

      Logger.log("Background Notification Clicked");
      NotificationClickHandler.handle(
        payload: message.data,
        appId: _appId,
        isOpen: false,
      );
    });

    // ── Killed-state click ───────────────────────────────────────
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _maybeHandleInApp(initialMessage.data);

      Logger.log("Killed State Notification Clicked");
      NotificationClickHandler.handle(
        payload: initialMessage.data,
        appId: _appId,
        isOpen: false,
      );
    }

    // ── New: Foreground FCM messages (in-app type only) ────────────────────
    // In-app messages are data-only FCM messages with type == "in_app".

    FirebaseMessaging.onMessage.listen((message) {
      if (_isInApp(message.data)) {
        InAppNotificationManager.instance.onInAppReceived(message.data);
      }
    });
  }

  // ── Foreground click (local notification) ───────────────────────
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

  // ── Private helpers ────────────────────────────────────────────────────────

  static bool _isInApp(Map<String, dynamic> data) => data['type'] == 'in_app';

  static void _maybeHandleInApp(Map<String, dynamic> data) {
    if (_isInApp(data)) {
      InAppNotificationManager.instance.onInAppReceived(data);
    }
  }
}
