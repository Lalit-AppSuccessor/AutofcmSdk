import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autofcm_sdk/autofcm_sdk.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_ui.dart';

const String appId = "com.journalit.notebook.diaryapp";
const String uidKey = "autofcm_uid_$appId";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 Init local notification UI
  await NotificationUI.init(
    onClick: (payload) {
      AutofcmSdk.handleNotificationClick(payload);
    },
  );
  ;

  // 🔥 Listen for FCM when app is FOREGROUND
  FirebaseMessaging.onMessage.listen((message) {
    print("🔥 FOREGROUND FCM → SHOWING NOTIFICATION UI");

    NotificationUI.show(
      title: message.notification?.title ?? "Test Notification",
      body: message.notification?.body ?? "You received a message",
      payload: message.data,
    );
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("🔥 FCM RECEIVED IN FOREGROUND");
    print("📦 message.data = ${message.data}");
    print("🔔 message.notification = ${message.notification}");
    print("🧩 full message = $message");
  });

  // App opened from BACKGROUND by notification click
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🟢 NOTIFICATION CLICKED (BACKGROUND)");
    print("📦 payload = ${message.data}");
  });

  // App opened from KILLED state by notification click
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    print("🟢 NOTIFICATION CLICKED (KILLED)");
    print("📦 payload = ${initialMessage.data}");
  }

  await AutofcmSdk.init(appId: appId, debug: true);
  Future.delayed(const Duration(seconds: 8), () {
    AutofcmSdk.setAfId("test_af_delayed_002");
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? uid;

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString(uidKey);
    });
  }

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(uidKey, "test_uid_123");
    AutofcmSdk.notifyUserUpdated();
    await _loadUid();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(uidKey);
    AutofcmSdk.notifyUserUpdated();
    await _loadUid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journalit SDK Test")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("UID: ${uid ?? "NOT LOGGED IN"}"),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Login")),
            ElevatedButton(onPressed: _logout, child: const Text("Logout")),
            const SizedBox(height: 20),
            const Text("Keep app in foreground to see API-B every 1 min"),
          ],
        ),
      ),
    );
  }
}
