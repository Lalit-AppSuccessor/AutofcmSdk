library journalit_sdk;

import 'notification/notification_listener.dart';
import 'src/sdk_manager.dart';
import 'src/providers/af_provider.dart';

class AutofcmSdk {
  static Future<void> init({required String appId, bool debug = false}) async {
    await SdkManager.instance.initialize(appId: appId, debug: debug);
  }

  static void setAfId(String afId) {
    AfProvider.setAfId(afId);

    // Re-evaluate state in case SDK was waiting for afId
    SdkManager.instance.onUserUpdated();
  }

  static void notifyUserUpdated() {
    SdkManager.instance.onUserUpdated();
  }

  static void handleNotificationClick(String payload) {
    NotificationListener.handleForegroundClick(payload);
  }
}
