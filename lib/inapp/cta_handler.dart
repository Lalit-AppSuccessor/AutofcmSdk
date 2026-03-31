import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/logger.dart';

/// Handles CTA URL routing for in-app notification modals.
///
/// Decision logic:
///   1. `http://` or `https://`  → opens in the system browser via url_launcher.
///                                   Falls back to home if the launch fails.
///   2. Any other scheme (deep link) → pushes a named route onto the Flutter
///                                     Navigator using the URI path, e.g.:
///                                     `myapp://profile/42` → pushNamed('/profile/42')
///                                     Falls back to home if the route is not
///                                     registered or navigation throws.
///   3. Empty / malformed URL        → navigates home.
///
/// The app can bypass this entirely by supplying its own onCtaPressed
/// callback to AutofcmInAppScope. CtaHandler.handle is only invoked when
/// that callback is null.

class CtaHandler {
  CtaHandler._();

  static Future<void> handle(String url, BuildContext context) async {
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      Logger.log('CtaHandler: empty URL → navigating home');
      _goHome(context);
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      Logger.log('CtaHandler: malformed URL "$trimmed" → navigating home');
      _goHome(context);
      return;
    }

    if (_isWebUrl(uri)) {
      await _openBrowser(uri, context);
    } else {
      await _navigateDeepLink(uri, trimmed, context);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static bool _isWebUrl(Uri uri) =>
      uri.scheme == 'http' || uri.scheme == 'https';

  /// Opens a web URL in the system browser. Falls back to home if the URL cannot be launched for any reason.
  static Future<void> _openBrowser(Uri uri, BuildContext context) async {
    Logger.log('CtaHandler: opening browser → $uri');
    try {
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) {
        Logger.log('CtaHandler: canLaunchUrl=false for $uri → navigating home');
        _goHome(context);
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Logger.log('CtaHandler: launchUrl returned false → navigating home');
        _goHome(context);
      } else {
        Logger.log('CtaHandler: browser launched successfully');
      }
    } catch (e) {
      Logger.log('CtaHandler: browser launch threw → $e → navigating home');
      _goHome(context);
    }
  }

  /// Falls back to home if the route is not registered or navigation throws.
  static Future<void> _navigateDeepLink(
    Uri uri,
    String rawUrl,
    BuildContext context,
  ) async {
    Logger.log('CtaHandler: deep link → $rawUrl');

    if (!context.mounted) {
      Logger.log('CtaHandler: context unmounted, skipping navigation');
      return;
    }

    // Normalise the path — always start with '/'.
    final path = uri.path.isNotEmpty
        ? (uri.path.startsWith('/') ? uri.path : '/${uri.path}')
        : '/';

    final args = uri.hasQuery ? uri.queryParameters : null;
    Logger.log(
      'CtaHandler: navigating to route "$path"'
      '${args != null ? " args=$args" : ""}',
    );

    try {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(path, arguments: args);
      Logger.log('CtaHandler: deep link navigation succeeded');
    } catch (e) {
      Logger.log(
        'CtaHandler: deep link navigation failed → $e → navigating home',
      );
      _goHome(context);
    }
  }

  /// Navigates to the root route `/`, clearing the entire stack so the user lands cleanly on the home screen.
  static void _goHome(BuildContext context) {
    if (!context.mounted) return;
    Logger.log('CtaHandler: navigating to home (/)');
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/', (_) => false);
  }
}
