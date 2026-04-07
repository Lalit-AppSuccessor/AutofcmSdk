library autofcm_sdk;

import 'package:flutter/widgets.dart';
import 'notification/notification_listener.dart';
import 'src/sdk_manager.dart';
import 'src/providers/af_provider.dart';
import 'inapp/in_app_notification_manager.dart';
import 'inapp/in_app_modal_widget.dart';
import 'inapp/in_app_notification_storage.dart';
import 'inapp/in_app_notification_data.dart';

// ── Public re-exports ──────────────────────────────────────────────────────
export 'inapp/in_app_modal_widget.dart' show InAppModalConfig;
export 'inapp/in_app_scope_widget.dart' show AutofcmInAppScope;
export 'inapp/in_app_modal_widget.dart' show ModalLayoutTemplate;

class AutofcmSdk {
  static Future<void> init({required String appId, bool debug = false}) async {
    await SdkManager.instance.initialize(appId: appId, debug: debug);
  }

  static void setAfId(String afId) {
    AfProvider.setAfId(afId);
    SdkManager.instance.onUserUpdated();
  }

  static void notifyUserUpdated() {
    SdkManager.instance.onUserUpdated();
  }

  static void handleNotificationClick(String payload) {
    FcmNotificationListener.handleForegroundClick(payload);
  }

  static Future<void> saveInAppForLater({
    required String appId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notification = InAppNotificationData.fromFcmData(data);
      await InAppNotificationStorage.savePending(appId, notification);
    } catch (_) {}
  }

  // ── In-App Modal ──────────────────────────────────────────────────────────
  static Future<bool> registerInAppScreen(
    BuildContext context, {
    InAppModalConfig config = const InAppModalConfig(),
    void Function(String url)? onCtaPressed,
  }) {
    return InAppNotificationManager.instance.checkAndShowIfPending(
      context,
      config: config,
      onCtaPressed: onCtaPressed,
    );
  }
}
