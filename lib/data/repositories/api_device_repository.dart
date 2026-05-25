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
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/devices',
        data: <String, dynamic>{
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );
      final Object? body = response.data;
      if (body is! Map<String, dynamic>) {
        return Result<String>.failure(
          'Unexpected device-registration response shape.',
        );
      }
      final String? id = body['id'] as String?;
      if (id == null) {
        return Result<String>.failure('Device registration returned no id.');
      }
      return Result<String>.success(id);
    } on DioException catch (e) {
      // 409 ALREADY_REGISTERED is a transfer-case (token moved to current
      // user). Treat as success if the server still returned an id.
      if (e.response?.statusCode == 409) {
        final Object? body = e.response?.data;
        if (body is Map<String, dynamic>) {
          final String? id = body['id'] as String?;
          if (id != null) {
            return Result<String>.success(id);
          }
        }
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
