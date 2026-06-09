import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/environment.dart';

class FcmMessage {
  const FcmMessage({
    required this.type,
    required this.deeplink,
    this.notificationId,
    this.childId,
    this.childrenId,
    this.childCode,
    this.missionId,
    this.performanceId,
  });

  final String type;
  final String deeplink;
  final String? notificationId;
  final String? childId;
  final String? childrenId;
  final String? childCode;
  final String? missionId;
  final String? performanceId;

  String? get childRef => childrenId ?? childId ?? childCode;

  factory FcmMessage.fromRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    return FcmMessage(
      type:
          _dataString(data, 'notificationType') ??
          _dataString(data, 'type') ??
          '',
      deeplink:
          _dataString(data, 'deeplink') ??
          _dataString(data, 'targetRoute') ??
          '/notifications',
      notificationId: _dataString(data, 'notificationId'),
      childId: _dataString(data, 'childId'),
      childrenId: _dataString(data, 'childrenId'),
      childCode: _dataString(data, 'childCode'),
      missionId: _dataString(data, 'missionId'),
      performanceId: _dataString(data, 'performanceId'),
    );
  }
}

/// Abstraction over [FirebaseMessaging] so the mock environment (tests,
/// dev without google-services credentials) can no-op while production
/// hits the real plugin.
abstract interface class FcmMessagingService {
  /// Request push permission. iOS + Android 13+ both gate on this. Returns
  /// true when the user granted (or provisionally granted) permission.
  Future<bool> requestPermission();

  /// Current device FCM token. Null when permission has been denied or
  /// the platform has not yet provisioned a token.
  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<FcmMessage> get onForegroundMessage;

  Stream<FcmMessage> get onMessageOpenedApp;

  Future<FcmMessage?> getInitialMessage();

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
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<FcmMessage> get onForegroundMessage =>
      const Stream<FcmMessage>.empty();

  @override
  Stream<FcmMessage> get onMessageOpenedApp => const Stream<FcmMessage>.empty();

  @override
  Future<FcmMessage?> getInitialMessage() async => null;

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
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<FcmMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(FcmMessage.fromRemoteMessage);

  @override
  Stream<FcmMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(FcmMessage.fromRemoteMessage);

  @override
  Future<FcmMessage?> getInitialMessage() async {
    final RemoteMessage? message = await FirebaseMessaging.instance
        .getInitialMessage();
    if (message == null) {
      return null;
    }
    return FcmMessage.fromRemoteMessage(message);
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

String? _dataString(Map<String, dynamic> data, String key) {
  final Object? value = data[key];
  final String? stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? null : stringValue;
}
