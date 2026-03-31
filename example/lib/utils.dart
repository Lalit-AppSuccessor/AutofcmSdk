import 'logger.dart';
// import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autofcm_sdk/autofcm_sdk.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'notification_ui.dart';

Future<void> printAllPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  for (String key in keys) {
    final value = prefs.get(key);
    Logger.log('$key: $value');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  Logger.log("📩 BG HANDLER entered");
  await Firebase.initializeApp();
  Logger.log("📩 BG HANDLER processing");
  final data = Map<String, dynamic>.from(message.data);
  Logger.log("📩 BG HANDLER START");
  Logger.log("📦 BG message data: $data");

  if (data['type'] == 'in_app') {
    Logger.log("💾 BG saving in-app payload");
    await AutofcmSdk.saveInAppForLater(
      appId: "com.example.journalit_test_app",
      data: data,
    );
    Logger.log("✅ BG save complete");
    await printAllPrefs();
  }
}
