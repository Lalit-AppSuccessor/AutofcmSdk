# AutoFCM SDK - Quick Start Example

> **Get started with AutoFCM SDK in 5 minutes**

This example demonstrates the minimal setup required to integrate AutoFCM SDK into your Flutter app.

---

## 🎯 What This SDK Does

AutoFCM SDK automatically handles:

- ✅ **App Install Tracking** - Automatic device registration on first launch
- ✅ **Device Heartbeat** - Periodic check-ins while app is in foreground
- ✅ **In-App Modals** - Beautiful notification dialogs within your app
- ✅ **Notification Click Tracking** - Foreground vs background state detection
- ✅ **Campaign Analytics** - Complete tracking without backend code

**You provide:**

- Firebase setup
- User ID (on login/logout)
- AppsFlyer ID
- Basic UI configuration

**SDK handles the rest!**

---

## 📋 Prerequisites

Before starting, ensure you have:

```yaml
# Required packages
dependencies:
  firebase_core: any
  firebase_messaging: any
  flutter_local_notifications: any
  shared_preferences: any
  url_launcher: any # for in-app modal CTA buttons
```

**Platform Requirements:**

- Flutter 3.7.0+
- Android minSdk 21 / iOS 11.0+
- Firebase project with FCM enabled
- `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)

---

## 🚀 5-Minute Integration

### Step 1: Add SDK Dependency

**pubspec.yaml:**

```yaml
dependencies:
  autofcm_sdk:
    path: ../AutofcmSdk # Adjust to your path
```

Run:

```bash
flutter pub get
```

---

### Step 2: Android Configuration

**android/app/google-services.json:**

```
Place your Firebase config file here
```

**android/app/src/main/AndroidManifest.xml:**

```xml
<application>
    <!-- Add inside application tag -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="autofcm_default_channel" />
</application>
```

**android/app/build.gradle:**

```gradle
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true  // Important!
    }
}

dependencies {
    // Add this for flutter_local_notifications compatibility
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

---

### Step 3: Initialize SDK

**lib/main.dart:**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:autofcm_sdk/autofcm_sdk.dart';

const String APP_ID = "com.your.app.package";  // Your bundle ID

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Initialize AutoFCM SDK
  await AutofcmSdk.init(
    appId: APP_ID,
    debug: true,  // Set false in production
  );

  runApp(const MyApp());
}
```

---

### Step 4: Set AppsFlyer ID

**Provide AppsFlyer ID when available:**

```dart
// After AppsFlyer initializes
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

Future<void> initAppsFlyer() async {
  final sdk = AppsflyerSdk(/*config*/);
  await sdk.initSdk();

  final afId = await sdk.getAppsFlyerUID();

  // Provide to AutoFCM
  AutofcmSdk.setAfId(afId ?? '');
}
```

---

### Step 5: Handle User Login/Logout

**On Login:**

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> onUserLogin(String userId) async {
  final prefs = await SharedPreferences.getInstance();

  // Store user ID (SDK reads this)
  await prefs.setString('autofcm_uid_$APP_ID', userId);

  // Notify SDK to start heartbeat
  AutofcmSdk.notifyUserUpdated();
}
```

**On Logout:**

```dart
Future<void> onUserLogout() async {
  final prefs = await SharedPreferences.getInstance();

  // Remove user ID
  await prefs.remove('autofcm_uid_$APP_ID');

  // Notify SDK to stop heartbeat
  AutofcmSdk.notifyUserUpdated();
}
```

---

### Step 6: Setup Notifications

**Create lib/notification_ui.dart:**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationUI {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Function(String)? _onClick;

  static Future<void> init({Function(String)? onClick}) async {
    _onClick = onClick;

    // Android setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // IOS setup
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && _onClick != null) {
          _onClick!(response.payload!);
        }
      },
    );

    // Create notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'autofcm_default_channel',
            'Default Notifications',
            importance: Importance.high,
          ),
        );
  }

  static Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'autofcm_default_channel',
          'Default Notifications',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }
}
```

**Update main.dart:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AutofcmSdk.init(appId: APP_ID, debug: true);

  // Initialize notification UI
  await NotificationUI.init(
    onClick: (payload) {
      // Forward clicks to SDK for tracking
      AutofcmSdk.handleNotificationClick(payload);
    },
  );

  runApp(const MyApp());
}
```

---

### Step 7: Handle Foreground Messages

**Add FCM listener:**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // Skip in-app type (SDK handles these)
      if (message.data['type'] == 'in_app') return;

      // Show regular notifications
      NotificationUI.show(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: message.data,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(/*...*/);
  }
}
```

---

### Step 8: Add In-App Modal (Optional)

**Wrap your home screen with AutofcmInAppScope:**

```dart
import 'package:autofcm_sdk/autofcm_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutofcmInAppScope(
      config:  const InAppModalConfig(
        template: ModalLayoutTemplate.imageCard,     // replace with "simple" for journalit style
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const YourContent(),
      ),
    );
  }
}
```

**Backend sends in-app notification:**

```json
{
  "token": "<device_token>",
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

---

## ✅ Complete Integration Checklist

Use this to verify your setup:

- [ ] SDK added to `pubspec.yaml`
- [ ] `google-services.json` placed in `android/app/`
- [ ] AndroidManifest.xml updated with FCM channel
- [ ] Desugaring enabled in `build.gradle`
- [ ] `AutofcmSdk.init()` called in `main()`
- [ ] AppsFlyer ID provided via `setAfId()`
- [ ] User login calls `notifyUserUpdated()`
- [ ] User logout calls `notifyUserUpdated()`
- [ ] `NotificationUI` initialized with click handler
- [ ] Foreground FCM listener set up
- [ ] In-app notifications skipped in foreground listener
- [ ] `AutofcmInAppScope` added to target screen (optional)

---

## 📤 What Happens Automatically

Once integrated, the SDK handles:

### Device Registration

```
User logs in
  ↓
SDK reads user ID from SharedPreferences
  ↓
POST /datatrack/install (first time only)
  ↓
Periodic POST /datatrack/heartbeat (while foreground)
```

### Notification Click Tracking

```
User clicks notification
  ↓
NotificationUI fires onClick callback
  ↓
AutofcmSdk.handleNotificationClick() called
  ↓
POST /datatrack/notification-clicked
  {
    "notification_id": "...",
    "user_afid": "...",
    "is_open": true/false  // foreground vs background
  }
```

### In-App Notifications

```
Backend sends FCM (type: "in_app")
  ↓
SDK saves to SharedPreferences
  ↓
User navigates to screen with AutofcmInAppScope
  ↓
Modal displays (once per notification_id)
```

---

## 🐛 Common Issues

### Issue: Notifications not showing in foreground

**Solution:**

```dart
// Make sure you're calling NotificationUI.show()
FirebaseMessaging.onMessage.listen((message) {
  if (message.data['type'] == 'in_app') return;
  NotificationUI.show(/*...*/);  // <- Don't forget this!
});
```

---

### Issue: Click tracking not working

**Solution:**

```dart
// Verify onClick handler is set
await NotificationUI.init(
  onClick: (payload) {
    AutofcmSdk.handleNotificationClick(payload);  // <- Must call this
  },
);
```

---

### Issue: In-app modal not appearing

**Solutions:**

1. Check FCM message has `"type": "in_app"`
2. Verify `AutofcmInAppScope` is on the screen
3. Check logs: `[AutoFcmSDK] In-app notification received: <id>`
4. Modal may have already been shown (try new `notification_id`)

---

### Issue: Android build fails

**Solution:**

```gradle
// Add to android/app/build.gradle
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

---

## 🔍 Debug Logging

Enable detailed logs:

```dart
await AutofcmSdk.init(
  appId: APP_ID,
  debug: true,  // Set false in production
);
```

You'll see:

```
[AutoFcmSDK] SDK initialized
[AutoFcmSDK] FCM token: <token>
[AutoFcmSDK] User updated, starting loop
[AutoFcmSDK] Device registered
[AutoFcmSDK] In-app notification received: promo_123
[AutoFcmSDK] Modal displayed for: promo_123
[AutoFcmSDK] Notification click tracked: campaign_456
```

---

## 📖 Need More Details?

See the main README in the root folder for:

- Complete API reference
- Advanced configuration
- Troubleshooting guide
- Architecture details
- Best practices

---

## 🎯 What You DON'T Need to Do

The SDK handles these automatically:

- ❌ Call backend APIs manually
- ❌ Detect app foreground/background state
- ❌ Deduplicate notification clicks
- ❌ Manage FCM token refresh
- ❌ Handle app lifecycle changes
- ❌ Store shown notification IDs

**Just integrate and let the SDK work!**

---

## 📝 Example App Structure

```
lib/
├── main.dart                    # SDK init + app entry
├── notification_ui.dart         # Local notification helper
├── screens/
│   └── home_screen.dart        # Screen with AutofcmInAppScope
└── services/
    └── auth_service.dart       # Login/logout with SDK notify
```

---

**Questions? Check the main README or contact support.**

**Happy coding! 🚀**
