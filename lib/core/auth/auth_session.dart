import 'package:shared_preferences/shared_preferences.dart';

abstract final class AuthSession {
  static const String loggedInKey = 'bridge_p.is_logged_in';
  static const String usernameKey = 'bridge_p.username';
  static const String fallbackUsername = 'gdg12';

  static Future<void> saveLogin({required String username}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(loggedInKey, true);
    await preferences.setString(usernameKey, username);
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(loggedInKey) ?? false;
  }

  static Future<String> username() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(usernameKey) ?? fallbackUsername;
  }

  static Future<void> clearLogin() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(loggedInKey);
    await preferences.remove(usernameKey);
  }
}
