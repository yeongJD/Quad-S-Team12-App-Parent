import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/models/child/child_summary.dart';
import 'package:bridge_p/data/repositories/api_child_repository.dart';
import 'package:bridge_p/data/repositories/api_notification_repository.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ApiChildRepository parses AWS ApiResponse-wrapped child list',
    () async {
      final ApiChildRepository repository = ApiChildRepository(
        dio: _dioForPath('/api/v1/parents/children', <String, dynamic>{
          'isSuccess': true,
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'childrenId': 22,
              'childCode': 'GDG12-1',
              'name': '하늘',
              'profileImageUrl': 'https://test.local/profile.jpg',
            },
          ],
        }),
      );

      final Result<List<ChildSummary>> result = await repository.loadChildren(
        'parent-1',
      );

      switch (result) {
        case Success<List<ChildSummary>>(:final List<ChildSummary> data):
          expect(data, hasLength(1));
          expect(data.single.childrenId, '22');
          expect(data.single.childCode, 'GDG12-1');
          expect(data.single.name, '하늘');
        case Failure<List<ChildSummary>>(:final String message):
          fail('loadChildren should parse wrapped list, got $message');
      }
    },
  );

  test(
    'ApiNotificationRepository parses AWS ApiResponse-wrapped inbox',
    () async {
      final ApiNotificationRepository repository = ApiNotificationRepository(
        dio: _dioForPath('/api/v1/notifications', <String, dynamic>{
          'isSuccess': true,
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'notificationId': 17,
              'notificationType': 'MISSION_REQUESTED',
              'title': '미션 확인 요청',
              'content': '자녀가 미션 확인을 요청했습니다.',
              'createdAt': '2026-06-09T12:30:00',
              'isRead': false,
              'childId': 22,
              'missionId': 42,
              'performanceId': 201,
              'targetRoute': '/today-mission?childrenId=22',
            },
          ],
        }),
      );

      final Result<List<NotificationItem>> result = await repository.loadInbox(
        'parent-1',
      );

      switch (result) {
        case Success<List<NotificationItem>>(
          :final List<NotificationItem> data,
        ):
          expect(data, hasLength(1));
          expect(data.single.id, '17');
          expect(
            data.single.type,
            NotificationType.missionConfirmationRequested,
          );
          expect(data.single.payload?['missionId'], 42);
        case Failure<List<NotificationItem>>(:final String message):
          fail('loadInbox should parse wrapped list, got $message');
      }
    },
  );
}

Dio _dioForPath(String path, Object? responseData) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        if (options.path == path) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: responseData,
            ),
          );
          return;
        }
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 404,
            ),
          ),
        );
      },
    ),
  );
  return dio;
}
