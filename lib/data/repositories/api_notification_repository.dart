import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/notifications/presentation/models/notification_item.dart';
import 'notification_repository.dart';

/// Network-backed [NotificationRepository] per `docs/api/05-notification.md`.
///
/// - `GET    /notifications?parentId={}`           → `[NotificationItem]`
/// - `GET    /notifications/unread-count?parentId={}` → `{ unread: bool, count: int }`
/// - `PATCH  /notifications/{id}/read?parentId={}`
/// - `DELETE /notifications/{id}?parentId={}`        (= hide)
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<List<NotificationItem>>> loadInbox(String parentId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/notifications',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! List) {
        return Result<List<NotificationItem>>.success(
          const <NotificationItem>[],
        );
      }
      final List<NotificationItem> items = data
          .whereType<Map<String, dynamic>>()
          .map<NotificationItem?>(NotificationItem.fromJson)
          .whereType<NotificationItem>()
          .toList(growable: false);
      return Result<List<NotificationItem>>.success(items);
    } on DioException catch (e) {
      return failureFromDioException<List<NotificationItem>>(e);
    }
  }

  @override
  Future<Result<bool>> hasUnread(String parentId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/notifications/unread-count',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<bool>.success(false);
      }
      return Result<bool>.success(data['unread'] == true);
    } on DioException catch (e) {
      return failureFromDioException<bool>(e);
    }
  }

  @override
  Future<Result<void>> markRead({
    required String parentId,
    required String notificationId,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/notifications/$notificationId/read',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<void>> hide({
    required String parentId,
    required String notificationId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/notifications/$notificationId',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }
}
