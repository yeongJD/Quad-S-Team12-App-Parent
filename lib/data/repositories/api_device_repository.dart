import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import 'device_repository.dart';

class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/v1/fcm/token',
        data: <String, dynamic>{
          'fcmToken': fcmToken,
        },
      );
      return Result<String>.success('transferred');
    } on DioException catch (e) {
      // 409 ALREADY_REGISTERED is a transfer-case (token moved to current
      // user). Treat as success if the server still returned an id.
      if (e.response?.statusCode == 409) {
        return Result<String>.success('transferred');
      }
      return failureFromDioException<String>(e);
    }
  }

  @override
  Future<Result<void>> unregisterDevice(String deviceId) async {
    try {
      await _dio.delete<dynamic>('/devices/$deviceId');
      return Result<void>.success(null);
    } on DioException catch (e) {
      // 404 — already gone; treat as success.
      if (e.response?.statusCode == 404) {
        return Result<void>.success(null);
      }
      return failureFromDioException<void>(e);
    }
  }
}
