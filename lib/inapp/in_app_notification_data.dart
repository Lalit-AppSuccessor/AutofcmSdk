import 'dart:convert';

/// Data model for an in-app notification received from the backend.
///
/// The backend should send an FCM data-only message with these fields:
///   {
///     "type": "in_app",
///     "notification_id":        "<unique-id>",
///     "inapp_title":     "Hey there!",
///     "inapp_body":      "Check out our new feature.",
///     "inapp_image_url": "https://example.com/banner.jpg",  // optional
///     "inapp_cta_text":  "Explore",                         // optional
///     "inapp_cta_url":   "https://example.com/feature"      // optional
///   }
///

class InAppNotificationData {
  final String id;
  final String? imageUrl;
  final String? title;
  final String? body;
  final String? ctaText;
  final String? ctaUrl;

  const InAppNotificationData({
    required this.id,
    this.imageUrl,
    this.title,
    this.body,
    this.ctaText,
    this.ctaUrl,
  });

  /// Parses directly from FCM message.data map.
  factory InAppNotificationData.fromFcmData(Map<String, dynamic> map) {
    final id = map['notification_id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Missing required field: notification_id');
    }
    return InAppNotificationData(
      id: id,
      imageUrl: map['inapp_image_url'] as String?,
      title: map['inapp_title'] as String?,
      body: map['inapp_body'] as String?,
      ctaText: map['inapp_cta_text'] as String?,
      ctaUrl: map['inapp_cta_url'] as String?,
    );
  }

  Map<String, dynamic> _toMap() => {
    'id': id,
    'image_url': imageUrl,
    'title': title,
    'body': body,
    'cta_text': ctaText,
    'cta_url': ctaUrl,
  };

  String toJson() => jsonEncode(_toMap());

  factory InAppNotificationData.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return InAppNotificationData(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      ctaText: map['cta_text'] as String?,
      ctaUrl: map['cta_url'] as String?,
    );
  }
}
