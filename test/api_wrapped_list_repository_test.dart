import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/models/child/child_summary.dart';
import 'package:bridge_p/data/repositories/api_child_repository.dart';
import 'package:bridge_p/data/repositories/api_device_repository.dart';
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

  test('ApiNotificationRepository patches read endpoint', () async {
    final List<String> calls = <String>[];
    final ApiNotificationRepository repository = ApiNotificationRepository(
      dio: _dioRecording(
        calls,
        expectedPath: '/api/v1/notifications/17/read',
        expectedMethod: 'PATCH',
      ),
    );

    final Result<void> result = await repository.markRead(
      parentId: 'parent-1',
      notificationId: '17',
    );

    expect(result, isA<Success<void>>());
    expect(calls, <String>['PATCH /api/v1/notifications/17/read']);
  });

  test('ApiNotificationRepository deletes notification endpoint', () async {
    final List<String> calls = <String>[];
    final ApiNotificationRepository repository = ApiNotificationRepository(
      dio: _dioRecording(
        calls,
        expectedPath: '/api/v1/notifications/17',
        expectedMethod: 'DELETE',
      ),
    );

    final Result<void> result = await repository.hide(
      parentId: 'parent-1',
      notificationId: '17',
    );

    expect(result, isA<Success<void>>());
    expect(calls, <String>['DELETE /api/v1/notifications/17']);
  });

  test(
    'ApiDeviceRepository posts FCM token and unwraps response data',
    () async {
      Map<String, dynamic>? postedBody;
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                if (options.path == '/api/v1/fcm/token' &&
                    options.method == 'POST') {
                  postedBody = Map<String, dynamic>.from(options.data as Map);
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'isSuccess': true,
                        'data': 'FCM 토큰 저장 완료',
                      },
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
      final ApiDeviceRepository repository = ApiDeviceRepository(dio: dio);

      final Result<String> result = await repository.registerDevice(
        fcmToken: 'token-1',
        platform: 'ios',
      );

      expect(postedBody, <String, dynamic>{'fcmToken': 'token-1'});
      switch (result) {
        case Success<String>(:final String data):
          expect(data, 'FCM 토큰 저장 완료');
        case Failure<String>(:final String message):
          fail('registerDevice should unwrap FCM response, got $message');
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

Dio _dioRecording(
  List<String> calls, {
  required String expectedPath,
  required String expectedMethod,
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        calls.add('${options.method} ${options.path}');
        if (options.path == expectedPath && options.method == expectedMethod) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'isSuccess': true, 'data': 'ok'},
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
