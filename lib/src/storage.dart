import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _uidKey(String appId) => "autofcm_uid_$appId";
  static String _installKey(String appId) => "autofcm_install_$appId";

  static String? getUid(String appId) {
    return _prefs.getString(_uidKey(appId));
  }

  static bool installSent(String appId) {
    return _prefs.getBool(_installKey(appId)) ?? false;
  }

  static Future<void> markInstallSent(String appId) async {
    await _prefs.setBool(_installKey(appId), true);
  }
}
