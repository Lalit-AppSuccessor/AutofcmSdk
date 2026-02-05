import '../notification/notification_listener.dart';
import 'storage.dart';
import 'api_client.dart';
import 'register_loop.dart';
import 'lifecycle_observer.dart';
import 'logger.dart';
import 'providers/fcm_provider.dart';
import 'providers/af_provider.dart';

class SdkManager {
  SdkManager._();
  static final instance = SdkManager._();

  bool _initialized = false;
  late String _appId;

  Future<void> initialize({required String appId, required bool debug}) async {
    if (_initialized) return;
    _initialized = true;
    _appId = appId;

    Logger.enabled = debug;
    Logger.log("SDK init started");

    await Storage.init();
    LifecycleObserver.attach(this);
    await NotificationListener.init(_appId);
    _evaluateState();
  }

  /// Central brain of the SDK
  Future<void> _evaluateState() async {
    final afId = await AfProvider.getAfId();
    final fcmToken = await FcmProvider.getToken();
    final uid = Storage.getUid(_appId);

    if (afId == null) {
      Logger.log("afId missing → waiting for app");
      return;
    }

    if (fcmToken == null) {
      Logger.log("FCM token missing → waiting");
      return;
    }

    final api = ApiClient(_appId);

    // 🔹 API-A: install (only once)
    if (uid == null && !Storage.installSent(_appId)) {
      Logger.log("Firing API-A (app-install)");
      Logger.log("afId=$afId | fcmToken=$fcmToken");

      await api.callAppInstall(afId: afId, fcmToken: fcmToken);

      await Storage.markInstallSent(_appId);
      // ❗ DO NOT return — allow API-B check
    }

    // 🔹 API-B: register-device
    if (uid != null) {
      Logger.log("Starting API-B loop");
      RegisterLoop.start(api: api, appId: _appId);
    }
  }

  /// Called when UID or afId changes
  void onUserUpdated() {
    Logger.log("User state updated → re-evaluating");
    _evaluateState();
  }

  /// Lifecycle hooks
  void onAppResumed() {
    Logger.log("App resumed");
    _evaluateState();
  }

  void onAppPaused() {
    Logger.log("App paused → stopping API-B loop");
    RegisterLoop.stop();
  }
}
