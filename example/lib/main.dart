import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autofcm_sdk/autofcm_sdk.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_ui.dart';
import 'logger.dart';
import 'utils.dart';

const String appId = "com.example.journalit_test_app";
const String uidKey = "autofcm_uid_$appId";

// Future<void> printAllPrefs() async {
//   final prefs = await SharedPreferences.getInstance();
//   final keys = prefs.getKeys();
//   for (String key in keys) {
//     final value = prefs.get(key);
//     print('$key: $value');
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  // 🔔 Init local notification UI (unchanged)
  await NotificationUI.init(
    onClick: (payload) {
      AutofcmSdk.handleNotificationClick(payload);
    },
  );

  FirebaseMessaging.onMessage.listen((message) async {
    final data = Map<String, dynamic>.from(message.data);
    if (data['type'] == 'in_app') return;

    Logger.log("🔥 FOREGROUND FCM → SHOWING NOTIFICATION UI");
    NotificationUI.show(
      title: message.notification?.title ?? "Test Notification",
      body: message.notification?.body ?? "You received a message",
      payload: message.data,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    Logger.log("🟢 NOTIFICATION CLICKED (BACKGROUND)");
    Logger.log("📦 payload = $data");
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final data = Map<String, dynamic>.from(initialMessage.data);
    Logger.log("🟢 NOTIFICATION CLICKED (KILLED)");
    Logger.log("📦 payload = $data");
  }

  await AutofcmSdk.init(appId: appId, debug: true);
  Future.delayed(const Duration(seconds: 1), () {
    AutofcmSdk.setAfId("test_af");
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
    return AutofcmInAppScope(
      config: const InAppModalConfig(
        template: ModalLayoutTemplate.imageCard,
      ), // replace with "simple" for journalit style
      child: Scaffold(
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
      ),
    );
  }
}
