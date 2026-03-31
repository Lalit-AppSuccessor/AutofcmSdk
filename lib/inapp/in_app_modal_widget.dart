import 'package:flutter/material.dart';
import 'in_app_notification_data.dart';

// ── Configuration ──────────────────────────────────────────────────────────────

/// Fully customisable appearance for the in-app modal.
///
/// Pass a custom InAppModalConfig to AutofcmSdk.registerInAppScreen to
/// match your app's brand — colours, corner radius, etc.
class InAppModalConfig {
  /// Card background colour.
  final Color backgroundColor;

  /// Scrim (barrier) colour behind the modal.
  final Color barrierColor;

  /// CTA button fill colour.
  final Color ctaButtonColor;

  /// CTA button label colour.
  final Color ctaTextColor;

  /// Title text colour.
  final Color titleColor;

  /// Body text colour.
  final Color bodyColor;

  /// Close icon colour.
  final Color closeIconColor;

  /// Corner radius of the card.
  final double borderRadius;

  /// Horizontal padding added around the dialog relative to screen edges.
  final EdgeInsets insetPadding;

  const InAppModalConfig({
    this.backgroundColor = Colors.white,
    this.barrierColor = const Color(0x00FFFFFF),
    this.ctaButtonColor = const Color(0xFFC5D6D0),
    this.ctaTextColor = Colors.black,
    this.titleColor = Colors.black,
    this.bodyColor = const Color(0x80000000),
    this.closeIconColor = const Color(0xFF6C7086),
    this.borderRadius = 32.0,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
  });
}

// ── Widget ─────────────────────────────────────────────────────────────────────

/// The in-app notification modal.

class InAppModal extends StatelessWidget {
  final InAppNotificationData data;
  final InAppModalConfig config;

  /// Called when the modal should close (close icon, barrier tap, or CTA).
  final VoidCallback onDismiss;

  /// Called with the CTA URL when the CTA button is pressed.

  final void Function(String url)? onCtaPressed;

  const InAppModal({
    super.key,
    required this.data,
    required this.onDismiss,
    this.config = const InAppModalConfig(),
    this.onCtaPressed,
  });

  // ── Static helper ──────────────────────────────────────────────────────────

  /// Displays the modal as a dialog and waits for it to be dismissed.
  static Future<void> show({
    required BuildContext context,
    required InAppNotificationData data,
    required VoidCallback onDismiss,
    InAppModalConfig config = const InAppModalConfig(),
    void Function(String url)? onCtaPressed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: config.barrierColor,
      builder: (_) => InAppModal(
        data: data,
        config: config,
        onDismiss: onDismiss,
        onCtaPressed: onCtaPressed,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: config.insetPadding,
      child: Container(
        decoration: BoxDecoration(
          color: config.backgroundColor, // e.g. Colors.white
          borderRadius: BorderRadius.circular(config.borderRadius), // e.g. 24
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Title ────────────────────────────────────────────
              if (_hasTitle) ...[
                Text(
                  data.title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: config.titleColor, // e.g. Color(0xFF1A1A1A)
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Body ─────────────────────────────────────────────
              if (_hasBody) ...[
                Text(
                  data.body!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: config.bodyColor, // e.g. Color(0xFF7A7A7A)
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── Banner Image ──────────────────────────────────────
              if (_hasImage) ...[
                _BannerImage(imageUrl: data.imageUrl!),
                const SizedBox(height: 10),
              ],

              // ── CTA Button ────────────────────────────────────────
              if (_hasCta)
                _CtaButton(
                  label: data.ctaText!,
                  bgColor: config.ctaButtonColor, // e.g. Color(0xFFBDD5C8)
                  textColor: config.ctaTextColor, // e.g. Color(0xFF1A1A1A)
                  borderRadius: 14, // pill shape
                  onPressed: () {
                    onDismiss();
                    if (data.ctaUrl != null && data.ctaUrl!.isNotEmpty) {
                      onCtaPressed?.call(data.ctaUrl!);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

// ── Helpers ─────────────────────────────────────────────────────────────────

  bool get _hasImage =>
      data.imageUrl != null && data.imageUrl!.trim().isNotEmpty;
  bool get _hasTitle => data.title != null && data.title!.trim().isNotEmpty;
  bool get _hasBody => data.body != null && data.body!.trim().isNotEmpty;
  bool get _hasCta => data.ctaText != null && data.ctaText!.trim().isNotEmpty;
}
// ── Private sub-widgets ────────────────────────────────────────────────────────

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _BannerImage extends StatelessWidget {
  final String imageUrl;

  const _BannerImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.65, // ← renders at 65% of the dialog width
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1 / 1,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high, // ← crisp rendering
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFFF5F5F5),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFBDD5C8)),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double borderRadius;
  final VoidCallback onPressed;

  const _CtaButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderRadius,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.3),
          overlayColor: Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 56),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.clamp(6, 50)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
