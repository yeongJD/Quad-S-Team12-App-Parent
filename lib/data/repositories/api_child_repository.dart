import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../models/child/child_summary.dart';
import 'child_repository.dart';

/// Network-backed [ChildRepository] per `docs/api/02-child.md`.
///
/// - `POST /children/validate-code` → `{ valid: bool }`
/// - `GET  /children?parentId={}`   → `[ChildSummary]`
/// - `POST /children`               → `ChildSummary`
/// - `DELETE /children/{childrenId}?parentId={}`
class ApiChildRepository implements ChildRepository {
  ApiChildRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<bool>> validateChildCode(String code) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/children/validate-code',
        data: <String, dynamic>{'code': code},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<bool>.success(false);
      }
      return Result<bool>.success(data['valid'] == true);
    } on DioException catch (e) {
      return failureFromDioException<bool>(e);
    }
  }

  @override
  Future<Result<List<ChildSummary>>> loadChildren(String parentId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/parents/children',
      );
      final dynamic data = response.data;
      if (data is! List) {
        return Result<List<ChildSummary>>.success(const <ChildSummary>[]);
      }
      final List<ChildSummary> children = data
          .whereType<Map<String, dynamic>>()
          .map(ChildSummary.fromJson)
          .toList(growable: false);
      return Result<List<ChildSummary>>.success(children);
    } on DioException catch (e) {
      return failureFromDioException<List<ChildSummary>>(e);
    }
  }

  @override
  Future<Result<ChildSummary>> addChild({
    required String parentId,
    required String childCode,
    required String name,
    String? photoBase64,
  }) async {
    // Backend identifies the parent via JWT, so parentId is not sent. Field
    // names follow RegisterChildRequest {childrenName, childrenCode,
    // profileImageUrl}. childrenBirth is intentionally omitted — see
    // backend-handoff §2.1 (pinned: childrenBirth optional, response returns
    // the created child object so it parses as ChildSummary below).
    final Map<String, dynamic> body = <String, dynamic>{
      'childrenName': name,
      'childrenCode': childCode,
    };
    if (photoBase64 != null) {
      body['profileImageUrl'] = photoBase64;
    }
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/parents/children',
        data: body,
      );
      final dynamic data = response.data;
      if (data is! Map) {
        throw const FormatException('addChild response was not a JSON object.');
      }
      return Result<ChildSummary>.success(
        ChildSummary.fromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (code == 'INVALID_CHILD_CODE') {
        return Result<ChildSummary>.failure(
          ChildFailureMessages.invalidCode,
          cause: code,
        );
      }
      if (code == 'CHILD_ALREADY_LINKED') {
        return Result<ChildSummary>.failure(
          ChildFailureMessages.duplicateChild,
          cause: code,
        );
      }
      return failureFromDioException<ChildSummary>(e);
    }
  }

  @override
  Future<Result<void>> removeChild({
    required String parentId,
    required String childrenId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/children/$childrenId',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      final String? code = errorCodeOf(e);
      if (code == 'CHILD_NOT_FOUND') {
        return Result<void>.failure(
          ChildFailureMessages.childNotFound,
          cause: code,
        );
      }
      return failureFromDioException<void>(e);
    }
  }
}
