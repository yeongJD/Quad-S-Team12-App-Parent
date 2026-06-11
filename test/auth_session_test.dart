import 'package:bridge_p/core/auth/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('logout clears identity, tokens, and device registration', () async {
    await AuthSession.login(parentId: 'parent-1', email: 'parent@test.com');
    await AuthSession.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    await AuthSession.saveDeviceId('device-1');

    expect(await AuthSession.isLoggedIn(), isTrue);
    expect(await AuthSession.accessToken(), 'access-1');
    expect(await AuthSession.refreshToken(), 'refresh-1');
    expect(await AuthSession.deviceId(), 'device-1');

    await AuthSession.logout();

    expect(await AuthSession.isLoggedIn(), isFalse);
    expect(await AuthSession.getCurrentParentId(), isNull);
    expect(await AuthSession.getCurrentEmail(), isNull);
    expect(await AuthSession.accessToken(), isNull);
    expect(await AuthSession.refreshToken(), isNull);
    expect(await AuthSession.deviceId(), isNull);
  });

  test('empty parent id is not treated as a logged-in session', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.currentParentIdKey: '',
      AuthSession.currentEmailKey: 'parent@test.com',
    });

    expect(await AuthSession.isLoggedIn(), isFalse);
  });
}
