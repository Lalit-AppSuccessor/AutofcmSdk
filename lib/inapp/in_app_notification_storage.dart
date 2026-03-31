import 'package:shared_preferences/shared_preferences.dart';
import 'in_app_notification_data.dart';

/// Persists the latest pending in-app notification and tracks whether it has already been shown.

class InAppNotificationStorage {
  InAppNotificationStorage._();

  // ── Keys ────────────────────────────────────────────────────────────────
  static String _pendingKey(String appId) => 'autofcm_inapp_pending_$appId';
  static String _shownKey(String notifId) => 'autofcm_inapp_shown_$notifId';

  // ── Shared prefs ─────────────────────────────────────────────────────────

  /// Loads SharedPreferences and reloads from disk.

  static const int _bgRetries = 3;
  static const Duration _bgRetryDelay = Duration(milliseconds: 120);

  static Future<SharedPreferences> _prefs({
    bool retryForBgWrite = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (retryForBgWrite) {
      for (int i = 0; i < _bgRetries; i++) {
        final keys = prefs.getKeys();
        if (keys.any((k) => k.startsWith('autofcm_inapp_pending_'))) break;
        await Future.delayed(_bgRetryDelay);
        await prefs.reload();
      }
    }

    return prefs;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<void> savePending(
    String appId,
    InAppNotificationData data,
  ) async {
    final prefs = await _prefs();
    await prefs.setString(_pendingKey(appId), data.toJson());
  }

  /// Returns the pending InAppNotificationData if one exists AND it has not been shown yet. Returns null otherwise.
  static Future<InAppNotificationData?> getPendingIfNotShown(
    String appId,
  ) async {
    final prefs = await _prefs(retryForBgWrite: true);
    final json = prefs.getString(_pendingKey(appId));
    if (json == null) return null;

    try {
      final data = InAppNotificationData.fromJson(json);
      final alreadyShown = prefs.getBool(_shownKey(data.id)) ?? false;
      if (alreadyShown) return null;
      return data;
    } catch (_) {
      await prefs.remove(_pendingKey(appId));
      return null;
    }
  }

  /// Marks notificationId as permanently shown and removes the pending entry so nothing is ever shown twice.
  static Future<void> markShown(String appId, String notificationId) async {
    final prefs = await _prefs();
    await prefs.setBool(_shownKey(notificationId), true);
    await prefs.remove(_pendingKey(appId));
  }

  /// Clears the pending notification without marking it shown. Useful for testing.
  static Future<void> clearPending(String appId) async {
    final prefs = await _prefs();
    await prefs.remove(_pendingKey(appId));
  }
}
