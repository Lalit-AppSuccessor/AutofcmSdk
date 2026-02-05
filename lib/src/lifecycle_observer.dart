import 'package:flutter/widgets.dart';
import 'sdk_manager.dart';

class LifecycleObserver extends WidgetsBindingObserver {
  static late SdkManager _manager;

  static void attach(SdkManager manager) {
    _manager = manager;
    WidgetsBinding.instance.addObserver(LifecycleObserver());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _manager.onAppResumed();
    } else {
      _manager.onAppPaused();
    }
  }
}
