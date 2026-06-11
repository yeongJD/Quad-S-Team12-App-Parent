import 'package:flutter/foundation.dart';

import '../../data/repositories/device_repository.dart';
import '../auth/auth_session.dart';
import '../models/result.dart';
import 'fcm_messaging_service.dart';

/// Helper that ties `FcmMessagingService.getToken()` →
/// `DeviceRepository.registerDevice()` → `AuthSession.saveDeviceId()` so
/// login / signup / logout / delete-account flows can register and
/// release the device with a single call each.
///
/// All methods are best-effort: failures are logged via [debugPrint] but
/// never thrown to the caller. The auth happy path matters more than a
/// stuck push-registration round-trip — the backend will reconcile the
/// device on the next successful registration anyway.
abstract final class DeviceRegistration {
  /// Resolves the current device token and POSTs it to `/devices`. The
  /// returned device id is persisted in [AuthSession] so the matching
  /// [unregisterCurrent] call can target it. Safe to call repeatedly —
  /// the backend treats this as upsert (409 ALREADY_REGISTERED is
  /// mapped to success inside ApiDeviceRepository).
  static Future<void> registerCurrent({
    FcmMessagingService? messagingService,
    DeviceRepository? deviceRepository,
  }) async {
    final FcmMessagingService messaging =
        messagingService ?? createFcmMessagingService();
    final DeviceRepository devices =
        deviceRepository ?? createDeviceRepository();

    final bool granted = await messaging.requestPermission();
    if (!granted) {
      debugPrint('[fcm] permission denied — skipping registration.');
      return;
    }
    final String? token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[fcm] no token — skipping registration.');
      return;
    }
    final Result<String> result = await devices.registerDevice(
      fcmToken: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
    switch (result) {
      case Success<String>(:final String data):
        await AuthSession.saveDeviceId(data);
        debugPrint('[fcm] device registered id=$data');
      case Failure<String>(:final String message):
        debugPrint('[fcm] device registration failed: $message');
    }
  }

  /// Releases the device id stored on the current session. Always clears
  /// the local id even when the backend call fails (FCM will eventually
  /// invalidate the token regardless).
  static Future<void> unregisterCurrent({
    FcmMessagingService? messagingService,
    DeviceRepository? deviceRepository,
  }) async {
    final FcmMessagingService messaging =
        messagingService ?? createFcmMessagingService();
    final DeviceRepository devices =
        deviceRepository ?? createDeviceRepository();

    final String? deviceId = await AuthSession.deviceId();
    if (deviceId != null && deviceId.isNotEmpty) {
      final Result<void> result = await devices.unregisterDevice(deviceId);
      if (result is Failure<void>) {
        debugPrint('[fcm] device unregister failed: ${result.message}');
      }
    }
    await AuthSession.clearDeviceId();
    await messaging.deleteToken();
  }
}
