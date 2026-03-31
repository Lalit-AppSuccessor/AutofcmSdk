import 'package:flutter/widgets.dart';
import '../src/logger.dart';
import '../src/api_client.dart';
import '../src/providers/af_provider.dart';
import 'in_app_notification_data.dart';
import 'in_app_notification_storage.dart';
import 'in_app_modal_widget.dart';

/// Central controller for the in-app notification modal.

class InAppNotificationManager {
  InAppNotificationManager._();
  static final instance = InAppNotificationManager._();

  String? _appId;

  /// Set to true whenever the app resumes or a new in-app notification arrives. Reset to false once we have attempted to show a modal.
  bool _pendingShowAttempt = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  void init(String appId) {
    _appId = appId;
    Logger.log('InAppNotificationManager initialised for appId=$appId');
  }

  // ── Called by NotificationListener ───────────────────────────────────────

  Future<void> onInAppReceived(Map<String, dynamic> data) async {
    if (_appId == null) return;

    try {
      final notification = InAppNotificationData.fromFcmData(data);
      // Always overwrite — latest notification wins, never stack.
      await InAppNotificationStorage.savePending(_appId!, notification);
      _pendingShowAttempt = true;
      Logger.log('InApp saved → id=${notification.id}');
    } catch (e) {
      Logger.log('InApp parse error: $e');
    }
  }

  // ── Called by SdkManager lifecycle ────────────────────────────────────────

  /// Called every time the app comes back to the foreground.
  void onAppResumed() {
    _pendingShowAttempt = true;
    Logger.log('InApp: pending show armed (app resumed)');
  }

  // ── Called by the designated screen ──────────────────────────────────────

  /// Returns true if a modal was shown, false otherwise.
  Future<bool> checkAndShowIfPending(
    BuildContext context, {
    InAppModalConfig config = const InAppModalConfig(),
    void Function(String url)? onCtaPressed,
    bool coldStart = false, // ← new param
  }) async {
    if (_appId == null) return false;
    if (!coldStart && !_pendingShowAttempt) return false;

    // Consume the flag immediately so repeated calls are no-ops.
    _pendingShowAttempt = false;

    final notification = await InAppNotificationStorage.getPendingIfNotShown(
      _appId!,
    );
    if (notification == null) {
      Logger.log('InApp: no pending notification or already shown');
      return false;
    }

    // Guard against unmounted widgets.
    if (!context.mounted) return false;

    Logger.log('InApp: showing modal → id=${notification.id}');

    _fireImpressionEvent(notification);

    await InAppModal.show(
      context: context,
      data: notification,
      config: config,
      onCtaPressed: onCtaPressed,
      onDismiss: () {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      },
    );

    await InAppNotificationStorage.markShown(_appId!, notification.id);
    Logger.log('InApp: marked shown → id=${notification.id}');

    Logger.log('InApp: modal dismissed → id=${notification.id}');

    return true;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Fires the notification-clicked (impression) API event when the modal is

  void _fireImpressionEvent(InAppNotificationData notification) {
    if (_appId == null) return;
    final appId = _appId!;

    Future(() async {
      try {
        final afId = await AfProvider.getAfId();
        if (afId == null) {
          Logger.log('InApp impression: afId not available, skipping API call');
          return;
        }
        Logger.log(
          'InApp impression: calling notification-clicked → id=${notification.id}, afId=$afId',
        );
        await ApiClient(appId).callNotificationClicked(
          notificationId: notification.id,
          userAfId: afId,
          isOpen: true,
        );
        Logger.log('InApp impression: API call succeeded');
      } catch (e) {
        Logger.log('InApp impression: API call failed → $e');
      }
    });
  }
}
