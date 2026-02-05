import 'dart:async';
import 'api_client.dart';
import 'storage.dart';
import 'providers/fcm_provider.dart';
import 'providers/af_provider.dart';
import 'logger.dart';

class RegisterLoop {
  static Timer? _timer;
  static bool _running = false;

  static Future<void> start({
    required ApiClient api,
    required String appId,
  }) async {
    if (_running) {
      Logger.log("API-B loop already running");
      return;
    }

    final uid = Storage.getUid(appId);
    if (uid == null) {
      Logger.log("No UID → loop not started");
      return;
    }

    final afId = await AfProvider.getAfId();
    final fcmToken = await FcmProvider.getToken();
    if (afId == null || fcmToken == null) return;

    Logger.log("Immediate API-B fired");

    // 🔥 Immediate fire
    unawaited(api.callRegisterDevice(afId: afId, uid: uid, fcmToken: fcmToken));

    _running = true;

    // 🔁 Start loop
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final currentUid = Storage.getUid(appId);
      if (currentUid == null) {
        stop();
        return;
      }

      final af = await AfProvider.getAfId();
      final fcm = await FcmProvider.getToken();
      if (af == null || fcm == null) return;

      Logger.log("API-B loop tick");

      await api.callRegisterDevice(afId: af, uid: currentUid, fcmToken: fcm);
    });
  }

  static void stop() {
    Logger.log("Stopping API-B loop");
    _timer?.cancel();
    _timer = null;
    _running = false;
  }
}
