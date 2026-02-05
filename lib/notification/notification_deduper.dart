class NotificationDeduper {
  static String? _lastId;
  static DateTime? _lastTime;

  static bool shouldProcess(String id) {
    final now = DateTime.now();

    if (_lastId == id &&
        _lastTime != null &&
        now.difference(_lastTime!).inSeconds < 5) {
      return false;
    }

    _lastId = id;
    _lastTime = now;
    return true;
  }
}
