import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../models/parent_profile/parent_profile.dart';
import 'parent_profile_repository.dart';

/// Network-backed [ParentProfileRepository] per `docs/api/06-parent-profile.md`.
///
/// - `GET   /parents/{parentId}`         → `ParentProfile`
/// - `PATCH /parents/{parentId}` body: `{ name }`        → `ParentProfile`
/// - `PATCH /parents/{parentId}/status` body: `{ status }`
class ApiParentProfileRepository implements ParentProfileRepository {
  ApiParentProfileRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<ParentProfile>> getProfile(String parentId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/parents/$parentId',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'getProfile response was not a JSON object.',
        );
      }
      return Result<ParentProfile>.success(
        ParentProfile.fromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (code == 'ACCOUNT_NOT_FOUND') {
        return Result<ParentProfile>.failure(
          ParentProfileFailureMessages.notFound,
          cause: code,
        );
      }
      return failureFromDioException<ParentProfile>(e);
    }
  }

  @override
  Future<Result<ParentProfile>> updateName({
    required String parentId,
    required String name,
  }) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/parents/$parentId',
        data: <String, dynamic>{'name': name},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException(
          'updateName response was not a JSON object.',
        );
      }
      return Result<ParentProfile>.success(
        ParentProfile.fromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      return failureFromDioException<ParentProfile>(e);
    }
  }

  @override
  Future<Result<void>> updateStatus({
    required String parentId,
    required ParentProfileStatus status,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/parents/$parentId/status',
        data: <String, dynamic>{'status': status.name},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}
