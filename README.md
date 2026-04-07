# AutoFCM SDK

> **Flutter SDK for Firebase Cloud Messaging automation with in-app notification modals and campaign tracking**

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/Lalit-AppSuccessor/AutoFcm-backend)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.7.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D2.18.0-0175C2?logo=dart)](https://dart.dev)

---

## 🎯 Overview

AutoFCM SDK automates Firebase Cloud Messaging integration with:

- **Automated Tracking** - Install, heartbeat, and click analytics
- **In-App Modals** - Rich notification dialogs within your app
- **Campaign Management** - Foreground/background state detection
- **Zero Backend Work** - SDK handles all API calls

---

## ✨ Features

| Feature             | Description                                     |
| ------------------- | ----------------------------------------------- |
| 🔔 In-App Modals    | Customizable notification dialogs in-app        |
| 📊 Auto Tracking    | Install, heartbeat, and click analytics         |
| 🎨 Customizable     | Full styling control (colors, borders, padding) |
| 🔄 State Aware      | Handles foreground, background, killed states   |
| 🚀 Campaign Ready   | Deduplication and ID-based tracking             |
| ⚡ Easy Integration | Minimal code, works with existing Firebase      |

---

## 📦 Prerequisites

```yaml
dependencies:
  firebase_core: any
  firebase_messaging: ^15.0.0
  flutter_local_notifications: any
  shared_preferences: ^2.2.2
  url_launcher: ^6.2.0
```

**Requirements:**

- Flutter 3.7.0+ / Dart 2.18.0+
- Android minSdk 21 / iOS 11.0+
- Firebase project with FCM enabled

---

## 🔧 Installation

```yaml
dependencies:
  autofcm_sdk:
    path: ../AutofcmSdk # Local path
    # OR
    git:
      url: https://github.com/Lalit-AppSuccessor/AutoFcm-backend.git
```

```bash
flutter pub get
```

---

## 🚀 Quick Start

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize SDK
  await AutofcmSdk.init(
    appId: 'com.your.app',
    debug: true,
  );

  runApp(const MyApp());
}

// Set AppsFlyer ID when available
AutofcmSdk.setAfId(appsFlyerUID);

// Notify on login/logout
AutofcmSdk.notifyUserUpdated();
```

---

## 📚 Implementation Guide

### Step 1: Firebase Setup

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<application>
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="autofcm_default_channel" />
</application>
```

**Android Build** (`android/app/build.gradle`):

```gradle
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

**iOS** - Add `GoogleService-Info.plist` and enable Push Notifications in Xcode.

---

### Step 2: SDK Initialization

```dart
const String appId = "com.your.app";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AutofcmSdk.init(appId: appId, debug: true);

  runApp(const MyApp());
}
```

---

### Step 3: AppsFlyer Integration

```dart
// After AppsFlyer initializes
final uid = await appsFlyerSdk.getAppsFlyerUID();
AutofcmSdk.setAfId(uid ?? '');
```

---

### Step 4: User Authentication

**On Login:**

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('autofcm_uid_$appId', userId);
AutofcmSdk.notifyUserUpdated();
```

**On Logout:**

```dart
await prefs.remove('autofcm_uid_$appId');
AutofcmSdk.notifyUserUpdated();
```

---

### Step 5: Foreground Notifications

Create `lib/notification_ui.dart` or replace with the example `notification_ui.dart` file.

**Initialize in main:**

```dart
await NotificationUI.init(
  onClick: (payload) => AutofcmSdk.handleNotificationClick(payload),
);
```

**Handle foreground messages:**

```dart
FirebaseMessaging.onMessage.listen((message) {
  if (message.data['type'] == 'in_app') return; // SDK handles
  NotificationUI.show(
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    payload: message.data,
  );
});
```

---

### Step 6: In-App Notifications

**Backend Payload:**

```json
{
  "token": "<token>",
  "data": {
    "type": "in_app",
    "notification_id": "campaign_123",
    "inapp_title": "New Feature!",
    "inapp_body": "Check out what's new",
    "inapp_image_url": "https://example.com/image.jpg",
    "inapp_cta_text": "Explore",
    "inapp_cta_url": "https://example.com/feature"
  }
}
```

**Wrap your screen:**

```dart
import 'package:autofcm_sdk/autofcm_sdk.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutofcmInAppScope(
      config: const InAppModalConfig(
        template: ModalLayoutTemplate.imageCard,
      ), // replace with "simple" for journalit style
      child: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: YourContent(),
      ),
    );
  }
}
```

---

## 📖 API Reference

### AutofcmSdk

```dart
// Initialize SDK
await AutofcmSdk.init({required String appId, bool debug = false});

// Set AppsFlyer ID
AutofcmSdk.setAfId(String afId);

// Notify user changes
AutofcmSdk.notifyUserUpdated();

// Handle notification clicks
AutofcmSdk.handleNotificationClick(String payload);

// Manual in-app check (advanced)
await AutofcmSdk.registerInAppScreen(
  BuildContext context,
  {InAppModalConfig config, Function(String)? onCtaPressed}
);
```

### AutofcmInAppScope

```dart
AutofcmInAppScope({
  required Widget child,
  InAppModalConfig config = const InAppModalConfig(),
  void Function(String url)? onCtaPressed,
})
```

### InAppModalConfig

```dart
const InAppModalConfig({
  Color backgroundColor,      // Card background
  Color barrierColor,         // Overlay color
  Color ctaButtonColor,       // Button background
  Color ctaTextColor,         // Button text
  Color titleColor,           // Title text
  Color bodyColor,            // Body text
  Color closeIconColor,       // Close icon
  double borderRadius,        // Corner radius
  EdgeInsets insetPadding,    // Screen margins
})
```

---

## 🎨 In-App Notification Flow

```
Backend → SDK Listener → Storage (SharedPreferences) → AutofcmInAppScope → Modal Display
```

**Behavior:**

- Same `notification_id` shown only once
- Latest notification overwrites pending ones
- Works in foreground, background, and killed states
- Modal displays when user navigates to designated screen

---

## 🔍 Troubleshooting

### In-App Modal Not Showing

- Check `type: "in_app"` in FCM payload
- Verify `AutofcmInAppScope` is on the screen
- Enable debug logs: `debug: true`
- Try different `notification_id`

### Foreground Notifications Missing

- Verify `FirebaseMessaging.onMessage` listener
- Check notification channel creation
- Skip in-app types: `if (data['type'] == 'in_app') return;`

### Click Tracking Issues

- Ensure `handleNotificationClick()` is called
- Check payload has `notification_id` and `user_afid`

### Android Build Errors

- Enable desugaring in `build.gradle`
- Add `coreLibraryDesugaring` dependency

---

## 📁 File Structure

```
lib/
├── autofcm_sdk.dart              # Public API
├── inapp/                        # In-app system
│   ├── in_app_modal_widget.dart
│   ├── in_app_scope_widget.dart
│   └── in_app_notification_*
├── notification/                 # FCM & tracking
│   ├── notification_listener.dart
│   └── notification_click_handler.dart
└── src/                          # Core
    ├── sdk_manager.dart
    ├── api_client.dart
    └── lifecycle_observer.dart
```

---

## 🤝 Support

- **Homepage**: [https://pingautobe.boostproductivity.online/](https://pingautobe.boostproductivity.online/)
- **Repository**: [https://github.com/Lalit-AppSuccessor/AutoFcm-backend](https://github.com/Lalit-AppSuccessor/AutoFcm-backend)

---

## 📝 Changelog

**v1.1.0**

- In-app notification modals
- Network monitoring
- Comprehensive docs

**v1.0.0**

- Initial release

---

**Built with ❤️ for Flutter developers**
