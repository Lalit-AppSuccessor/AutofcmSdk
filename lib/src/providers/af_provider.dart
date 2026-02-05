class AfProvider {
  static String? _afId;

  /// Called by the APP
  static void setAfId(String afId) {
    _afId = afId;
  }

  /// Used internally by SDK
  static Future<String?> getAfId() async {
    return _afId;
  }

  static void clear() {
    _afId = null;
  }
}
