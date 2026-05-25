import '../../core/models/result.dart';
import 'device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  const MockDeviceRepository();

  @override
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    return Result<String>.success('mock-device-id-$fcmToken');
  }

  @override
  Future<Result<void>> unregisterDevice(String deviceId) async {
    return Result<void>.success(null);
  }
}
