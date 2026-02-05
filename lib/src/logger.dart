class Logger {
  static bool enabled = false;

  static void log(String msg) {
    if (enabled) {
      print("[AutofcmSdk] $msg");
    }
  }
}
