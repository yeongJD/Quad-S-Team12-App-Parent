import 'package:shared_preferences/shared_preferences.dart';

import 'account_store.dart';

abstract final class AuthSession {
  static const String bridgeKeyPrefix = 'bridge_p.';
  static const String currentParentIdKey = 'bridge_p.current_parent_id';
  static const String currentEmailKey = 'bridge_p.current_email';
  static const String fallbackName = 'parent';

  static Future<void> login({
    required String parentId,
    required String email,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(currentParentIdKey, parentId);
    await preferences.setString(currentEmailKey, email);
  }

  static Future<bool> isLoggedIn() async {
    return (await getCurrentParentId()) != null;
  }

  static Future<String?> getCurrentParentId() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(currentParentIdKey);
  }

  static Future<String?> getCurrentEmail() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(currentEmailKey);
  }

  static Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(currentParentIdKey);
    await preferences.remove(currentEmailKey);
  }

  static Future<void> resetAllData() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final Set<String> durableAccountKeys = <String>{
      AccountStore.accountsKey,
      currentParentIdKey,
      currentEmailKey,
    };

    final List<String> keysToRemove = preferences
        .getKeys()
        .where(
          (String key) =>
              key.startsWith(bridgeKeyPrefix) &&
              !durableAccountKeys.contains(key),
        )
        .toList(growable: false);

    for (final String key in keysToRemove) {
      final bool didRemove = await preferences.remove(key);
      if (!didRemove) {
        throw StateError('Failed to remove local Bridge data for key: $key');
      }
    }
  }
}
