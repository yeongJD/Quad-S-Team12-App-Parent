import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/environment.dart';

/// Abstraction over [FirebaseMessaging] so the mock environment (tests,
/// dev without google-services credentials) can no-op while production
/// hits the real plugin. Scope is intentionally narrow — token retrieval
/// only, matching what `DeviceRepository.registerDevice` needs. Stream
/// handlers / deeplink routing land in a follow-up ticket.
abstract interface class FcmMessagingService {
  /// Request push permission. iOS + Android 13+ both gate on this. Returns
  /// true when the user granted (or provisionally granted) permission.
  Future<bool> requestPermission();

  /// Current device FCM token. Null when permission has been denied or
  /// the platform has not yet provisioned a token.
  Future<String?> getToken();

  /// Best-effort token revocation, called after `unregisterDevice` so the
  /// next login provisions a fresh token rather than reusing the prior
  /// session's. Failure is swallowed — the platform will rotate the token
  /// on its own schedule anyway.
  Future<void> deleteToken();
}

final FcmMessagingService _fcmMessagingService = currentEnvironment.useMocks
    ? const MockFcmMessagingService()
    : ApiFcmMessagingService();

FcmMessagingService createFcmMessagingService() => _fcmMessagingService;

class MockFcmMessagingService implements FcmMessagingService {
  const MockFcmMessagingService();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => 'mock-fcm-token-parent';

  @override
  Future<void> deleteToken() async {
    // no-op
  }
}

class ApiFcmMessagingService implements FcmMessagingService {
  ApiFcmMessagingService();

  @override
  Future<bool> requestPermission() async {
    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return true;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.notDetermined:
        return false;
    }
  }

  @override
  Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Swallow — see [FcmMessagingService.deleteToken] doc.
    }
  }
}
