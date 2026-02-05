AUTOFCM FLUTTER SDK – SIMPLE INTEGRATION GUIDE

PURPOSE

This SDK automatically handles:
• App install tracking
• Device heartbeat (foreground only)
• Notification click tracking (foreground / background / killed)

App developers only need to provide minimal inputs.

REQUIREMENTS

• Flutter 3.x
• Android app
• Firebase configured
• Firebase Cloud Messaging enabled

Required packages:
• firebase_core
• firebase_messaging
• flutter_local_notifications
• shared_preferences


STEP 1 – ADD SDK DEPENDENCY

pubspec.yaml

dependencies:
  autofcm_sdk:
    git:
      url: https://github.com/Lalit-AppSuccessor/AutofcmSdk.git
      ref: main

  firebase_core: any
  firebase_messaging: any
  flutter_local_notifications: any
  shared_preferences: any

Run:
flutter pub get


STEP 2 – FIREBASE SETUP (MANDATORY)

Place google-services.json in:
android/app/google-services.json

Enable Firebase Messaging in Firebase Console

AndroidManifest.xml:
Inside <application> tag, add:

<meta-data
  android:name="com.google.firebase.messaging.default_notification_channel_id"
  android:value="autofcm_default_channel" />


STEP 3 – ANDROID BUILD FIX (IMPORTANT)

If you use flutter_local_notifications:

android/app/build.gradle.kts

Inside compileOptions:

compileOptions {
  sourceCompatibility = JavaVersion.VERSION_17
  targetCompatibility = JavaVersion.VERSION_17
  isCoreLibraryDesugaringEnabled = true
}

Add dependency:

dependencies {
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}


STEP 4 – INITIALIZE SDK (REQUIRED)

main.dart

const String appId = "com.test.app.id";
const String uidKey = "autofcm_uid_$appId";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await AutofcmSdk.init(
    appId: appId,
    debug: true,
  );

  runApp(MyApp());
}


STEP 5 – PROVIDE AF ID (REQUIRED)

SDK does NOT fetch AF ID automatically.

App MUST provide AF ID when available.

Example:

AutofcmSdk.setAfId("your_af_id_here");

This can be:
• Immediate
• Delayed
• After AppsFlyer initializes

SDK will auto-react.


STEP 6 – USER LOGIN / LOGOUT

On login:

await prefs.setString(
  "autofcm_uid_com.your.app.package",
  "user_123",
);
AutofcmSdk.notifyUserUpdated();

On logout:

await prefs.remove("autofcm_uid_com.your.app.package");
AutofcmSdk.notifyUserUpdated();

SDK behavior:
• Starts heartbeat loop on login
• Stops loop on logout or background


STEP 7 – FOREGROUND NOTIFICATION DISPLAY

Android does NOT show system notifications in foreground.

You MUST show a local notification.

Create file:

lib/notification_ui.dart

(Use flutter_local_notifications to show notification)


STEP 8 – FOREGROUND FCM HANDLING

main.dart

FirebaseMessaging.onMessage.listen((message) {
  NotificationUI.show(
    title: message.notification?.title ?? "Notification",
    body: message.notification?.body ?? "",
    payload: message.data,
  );
});


STEP 9 – NOTIFICATION CLICK HANDLING

When a local notification is clicked, call:

AutofcmSdk.handleNotificationClick(payloadString);

Like this before app run:

// 🔔 Init local notification UI
  await NotificationUI.init(
    onClick: (payload) {
      AutofcmSdk.handleNotificationClick(payload);
    },
  );
  ;

DO NOT call backend APIs manually.

SDK will:
• Detect foreground vs background
• Deduplicate clicks
• Fire API automatically


NOTIFICATION CLICK API (AUTO)

Endpoint:
POST /datatrack/notification-clicked

Payload sent by SDK:

{
  "notification_id": "...",
  "user_afid": "...",
  "is_open": true | false
}

is_open = true
→ Notification clicked while app already open

is_open = false
→ Notification opened app from background or killed


WHAT APP DEVELOPER MUST DO

✓ Initialize Firebase
✓ Initialize SDK
✓ Provide AF ID
✓ Notify SDK on login/logout
✓ Show foreground notification UI
✓ Forward notification click to SDK


WHAT APP DEVELOPER SHOULD NOT DO

✗ Call backend APIs
✗ Deduplicate events
✗ Detect app state manually
✗ Import SDK internal files


DEBUGGING

Enable logs:
debug: true in SDK init

Logs will appear as:
[AutoFcmSDK] ...


COMMON ISSUES

Notification not visible:
• Missing local notification UI

Click not tracked:
• payload missing notification_id or user_afid
• handleNotificationClick not called

Android build error:
• Enable coreLibraryDesugaring


END OF FILE
