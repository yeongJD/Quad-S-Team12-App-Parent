import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/notifications/presentation/models/notification_item.dart';
import 'notification_repository.dart';

/// Network-backed [NotificationRepository] per `docs/api/05-notification.md`.
///
/// - `GET    /api/v1/notifications`                 → `[NotificationItem]`
/// - unread count is derived locally from the inbox (no backend endpoint)
/// - `PATCH  /api/v1/notifications/{id}/read`
/// - `DELETE /api/v1/notifications/{id}`            (= hide)
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  @override
  Future<Result<List<NotificationItem>>> loadInbox(String parentId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/notifications',
      );
      final List<dynamic> data = _jsonList(response.data);
      final List<NotificationItem> items = data
          .whereType<Map>()
          .map<NotificationItem?>(
            (Map item) =>
                NotificationItem.fromJson(Map<String, Object?>.from(item)),
          )
          .whereType<NotificationItem>()
          .toList(growable: false);
      return Result<List<NotificationItem>>.success(items);
    } on DioException catch (e) {
      return failureFromDioException<List<NotificationItem>>(e);
    }
  }

  @override
  Future<Result<bool>> hasUnread(String parentId) async {
    final Result<List<NotificationItem>> inbox = await loadInbox(parentId);
    return switch (inbox) {
      Success<List<NotificationItem>>(:final List<NotificationItem> data) =>
        Result<bool>.success(data.any((NotificationItem item) => !item.isRead)),
      Failure<List<NotificationItem>>(
        :final String message,
        :final Object? cause,
        :final StackTrace? stack,
      ) =>
        Result<bool>.failure(message, cause: cause, stack: stack),
    };
  }

  @override
  Future<Result<void>> markRead({
    required String parentId,
    required String notificationId,
  }) async {
    final int? id = _positiveNumericId(notificationId);
    if (id == null) {
      return Result<void>.failure('알림 정보를 다시 불러와 주세요.');
    }
    try {
      await _dio.patch<dynamic>('/api/v1/notifications/$id/read');
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
    final int? id = _positiveNumericId(notificationId);
    if (id == null) {
      return Result<void>.failure('알림 정보를 다시 불러와 주세요.');
    }
    try {
      await _dio.delete<dynamic>('/api/v1/notifications/$id');
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  List<dynamic> _jsonList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return const <dynamic>[];
  }

  int? _positiveNumericId(String id) {
    final int? parsed = int.tryParse(id.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}
