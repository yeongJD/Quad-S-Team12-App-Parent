import 'package:shared_preferences/shared_preferences.dart';

import 'account_store.dart';

abstract final class AuthSession {
  static const String bridgeKeyPrefix = 'bridge_p.';
  static const String currentParentIdKey = 'bridge_p.current_parent_id';
  static const String currentEmailKey = 'bridge_p.current_email';
  static const String fallbackName = 'parent';

  static const String _accessTokenKey = 'bridge_p.access_token';
  static const String _refreshTokenKey = 'bridge_p.refresh_token';
  static const String _deviceIdKey = 'bridge_p.device_id';

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

  /// Persist an [accessToken] (and optional [refreshToken]) in
  /// SharedPreferences. Tokens are stored alongside — not in place of —
  /// the existing parentId/email session keys, so a logged-in session can
  /// remain valid across token rotations.
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await preferences.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Returns the stored access token, or `null` if none is present.
  static Future<String?> accessToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_accessTokenKey);
  }

  /// Returns the stored refresh token, or `null` if none is present.
  static Future<String?> refreshToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_refreshTokenKey);
  }

  /// Removes only token entries — kept separate from [logout] so that the
  /// auth flow can iterate on the two concerns independently.
  static Future<void> clearTokens() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
  }

  /// Persist the backend-assigned device id returned by
  /// `DeviceRepository.registerDevice`. Used by the matching
  /// `unregisterDevice` call at logout / delete-account time.
  static Future<void> saveDeviceId(String deviceId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceIdKey, deviceId);
  }

  static Future<String?> deviceId() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_deviceIdKey);
  }

  static Future<void> clearDeviceId() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceIdKey);
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
