import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import 'api_device_repository.dart';
import 'mock_device_repository.dart';

/// Registers the device's FCM token with the backend so it can receive
/// push notifications. The owning user is inferred from the
/// Authorization header, so call sites don't need to pass `parentId`.
///
/// Contract: docs/api/07-device.md.
abstract interface class DeviceRepository {
  /// Upserts the device for the currently authenticated parent. Returns
  /// the server-issued device id which the client should remember and
  /// pass to [unregisterDevice] at logout / account delete time.
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform, // 'ios' or 'android'
  });

  /// Best-effort removal. Failure paths are fine to swallow at the call
  /// site — the device token will eventually be invalidated by FCM anyway.
  Future<Result<void>> unregisterDevice(String deviceId);
}

final DeviceRepository _deviceRepository = currentEnvironment.useMocks
    ? const MockDeviceRepository()
    : ApiDeviceRepository();

DeviceRepository createDeviceRepository() => _deviceRepository;
