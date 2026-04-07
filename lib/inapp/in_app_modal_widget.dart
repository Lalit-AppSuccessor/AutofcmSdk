import 'package:flutter/material.dart';
import 'in_app_notification_data.dart';

/// ─────────────────────────────────────────────────────────────
/// Modal Layout Types
/// ─────────────────────────────────────────────────────────────
enum ModalLayoutTemplate { simple, imageCard }

/// ─────────────────────────────────────────────────────────────
/// Config
/// ─────────────────────────────────────────────────────────────
class InAppModalConfig {
  final ModalLayoutTemplate template;
  final Color backgroundColor;
  final Color barrierColor;
  final Color ctaButtonColor;
  final Color ctaTextColor;
  final Color titleColor;
  final Color bodyColor;
  final Color closeIconColor;
  final double borderRadius;
  final EdgeInsets insetPadding;

  const InAppModalConfig({
    this.template = ModalLayoutTemplate.simple,
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

/// ─────────────────────────────────────────────────────────────
/// MAIN MODAL (Simple)
/// ─────────────────────────────────────────────────────────────
class InAppModal extends StatelessWidget {
  final InAppNotificationData data;
  final InAppModalConfig config;
  final VoidCallback onDismiss;
  final void Function(String url)? onCtaPressed;

  const InAppModal({
    super.key,
    required this.data,
    required this.onDismiss,
    this.config = const InAppModalConfig(),
    this.onCtaPressed,
  });

  /// ── Factory for template ──
  static Widget fromTemplate({
    required ModalLayoutTemplate template,
    required InAppNotificationData data,
    required VoidCallback onDismiss,
    InAppModalConfig config = const InAppModalConfig(),
    void Function(String url)? onCtaPressed,
  }) {
    switch (template) {
      case ModalLayoutTemplate.imageCard:
        return _ImageCardModal(
          data: data,
          onDismiss: onDismiss,
          config: config,
          onCtaPressed: onCtaPressed,
        );

      case ModalLayoutTemplate.simple:
      default:
        return InAppModal(
          data: data,
          onDismiss: onDismiss,
          config: config,
          onCtaPressed: onCtaPressed,
        );
    }
  }

  /// ── Show Dialog ──
  static Future<void> show({
    required BuildContext context,
    required InAppNotificationData data,
    required VoidCallback onDismiss,
    ModalLayoutTemplate template = ModalLayoutTemplate.simple,
    InAppModalConfig config = const InAppModalConfig(),
    void Function(String url)? onCtaPressed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: config.barrierColor,
      builder: (_) => InAppModal.fromTemplate(
        template: config.template,
        data: data,
        onDismiss: onDismiss,
        config: config,
        onCtaPressed: onCtaPressed,
      ),
    );
  }

  /// ── Simple Modal UI ──
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: config.insetPadding,
      child: Container(
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(config.borderRadius),
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
          padding: const EdgeInsets.all(24),
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
                    color: config.titleColor,
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

              if (_hasImage) ...[
                _BannerImage(imageUrl: data.imageUrl!),
                const SizedBox(height: 10),
              ],

              if (_hasCta)
                _CtaButton(
                  label: data.ctaText!,
                  bgColor: config.ctaButtonColor,
                  textColor: config.ctaTextColor,
                  borderRadius: 14,
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

  bool get _hasImage =>
      data.imageUrl != null && data.imageUrl!.trim().isNotEmpty;
  bool get _hasTitle => data.title != null && data.title!.trim().isNotEmpty;
  bool get _hasBody => data.body != null && data.body!.trim().isNotEmpty;
  bool get _hasCta => data.ctaText != null && data.ctaText!.trim().isNotEmpty;
}

/// ─────────────────────────────────────────────────────────────
/// IMAGE CARD MODAL (Soundscape Design)
/// ─────────────────────────────────────────────────────────────
class _ImageCardModal extends StatelessWidget {
  final InAppNotificationData data;
  final InAppModalConfig config;
  final VoidCallback onDismiss;
  final void Function(String url)? onCtaPressed;

  const _ImageCardModal({
    required this.data,
    required this.onDismiss,
    required this.config,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final keywords = ["unlock", "premium", "upgrade"];
    final isGolden = keywords.any(
      (k) => (data.ctaText ?? "").toLowerCase().contains(k),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
      ), // 👈 responsive margin

      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          /// ── MAIN CARD ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400, // 👈 controls modal width
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      /// Gradient Background
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF54568A), Colors.black],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      /// Top Image
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Image.asset(
                            'lib/assets/images/bgClouds.png',
                            package: 'autofcm_sdk',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      /// Content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          /// Close Button
                          Padding(
                            padding: const EdgeInsets.only(top: 20, right: 24),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: onDismiss,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 2),

                          /// Top Image (optional)
                          if (data.imageUrl != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: Image.asset(
                                  'lib/assets/images/headerLogo.png',
                                  package: 'autofcm_sdk',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          /// TITLE
                          if (data.title != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                data.title!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'WixMadeforDisplay',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          const SizedBox(height: 10),

                          /// BODY
                          if (data.body != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                data.body!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'WixMadeforDisplay',
                                  fontSize: 12,
                                  color: Colors.white,
                                  letterSpacing: 0.48,
                                  height: 1.5,
                                ),
                              ),
                            ),

                          const SizedBox(height: 2),

                          /// Bottom Image
                          if (data.imageUrl != null) ...[
                            _AssetImage(imageUrl: data.imageUrl!),
                            const SizedBox(height: 2),
                          ],

                          /// CTA BUTTON
                          if (data.ctaText != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(32, 2, 32, 32),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(
                                    colors: isGolden
                                        ? [Color(0xFFFFC082), Color(0xFFFFFAA8)]
                                        : [
                                            Color(0xFF7174C7),
                                            Color(0xFF373961),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    onDismiss();
                                    if (data.ctaUrl != null) {
                                      onCtaPressed?.call(data.ctaUrl!);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    data.ctaText!,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isGolden
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// COMMON COMPONENTS
/// ─────────────────────────────────────────────────────────────
class _BannerImage extends StatelessWidget {
  final String imageUrl;

  const _BannerImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.65,
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
            borderRadius: BorderRadius.circular(borderRadius),
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

class _AssetImage extends StatelessWidget {
  final String imageUrl;

  const _AssetImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high, // ← crisp rendering
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF54568A),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFBDD5C8)),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
