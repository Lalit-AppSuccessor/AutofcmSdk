import 'package:flutter/widgets.dart';
import 'in_app_notification_manager.dart';
import 'in_app_modal_widget.dart';
import 'cta_handler.dart';

class AutofcmInAppScope extends StatefulWidget {
  final Widget child;

  final InAppModalConfig config;

  final void Function(String url)? onCtaPressed;

  const AutofcmInAppScope({
    super.key,
    required this.child,
    this.config = const InAppModalConfig(),
    this.onCtaPressed,
  });

  @override
  State<AutofcmInAppScope> createState() => _AutofcmInAppScopeState();
}

class _AutofcmInAppScopeState extends State<AutofcmInAppScope>
    with WidgetsBindingObserver {
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Case 1: screen just mounted (cold-start, first navigation here).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryShow(coldStart: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Case 2: app resumed while user is already on this screen.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 150), _tryShow);
    }
  }

  Future<void> _tryShow({bool coldStart = false}) async {
    if (!mounted) return;

    if (_isShowing) return;

    _isShowing = true;
    try {
      final ctaHandler =
          widget.onCtaPressed ??
          (String url) => CtaHandler.handle(url, context);

      await InAppNotificationManager.instance.checkAndShowIfPending(
        context,
        config: widget.config,
        onCtaPressed: ctaHandler,
        coldStart: coldStart,
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
