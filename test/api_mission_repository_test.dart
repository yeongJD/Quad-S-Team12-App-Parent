import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/api_mission_repository.dart';
import 'package:bridge_p/features/today_mission/presentation/models/today_mission.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiMissionRepository', () {
    test(
      'addMission posts numeric childId when childrenId is numeric',
      () async {
        Map<String, dynamic>? postedBody;
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  postedBody = Map<String, dynamic>.from(options.data as Map);
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'isSuccess': true},
                    ),
                  );
                },
          ),
        );
        final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

        final Result<void> result = await repository.addMission(
          parentId: 'parent-1',
          childrenId: '22',
          mission: const TodayMission(
            title: '방 청소',
            category: MissionCategory.cleaning,
            resetPeriod: MissionResetPeriod.daily,
            confirmationMethod: MissionConfirmationMethod.parent,
            rewardMinutes: 30,
            description: '사진 제출',
          ),
        );

        expect(result, isA<Success<void>>());
        expect(postedBody?['childId'], 22);
        expect(postedBody?['verificationType'], 'PARENT');
        expect(postedBody?['resetCycle'], 'DAILY');
      },
    );

    test('maps pending performances by verification type', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                final Response<dynamic> response = Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: _missionResponseFor(options.path),
                );
                handler.resolve(response);
              },
        ),
      );
      final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

      final Result<List<TodayMission>> result = await repository.loadMissions(
        parentId: 'parent-1',
        childrenId: '22',
      );

      expect(result, isA<Success<List<TodayMission>>>());
      final List<TodayMission> missions =
          (result as Success<List<TodayMission>>).data;
      final Map<String, TodayMission> byId = <String, TodayMission>{
        for (final TodayMission mission in missions)
          mission.missionId!: mission,
      };

      expect(
        byId['parent-mission']!.effectiveVerificationStatus,
        MissionVerificationStatus.waitingParentApproval,
      );
      expect(byId['parent-mission']!.resetPeriod, MissionResetPeriod.weekly);
      expect(
        byId['parent-mission']!.effectiveStatus,
        TodayMissionStatus.reviewing,
      );
      expect(
        byId['ai-mission']!.effectiveVerificationStatus,
        MissionVerificationStatus.waitingAiVerification,
      );
      expect(byId['ai-mission']!.effectiveStatus, TodayMissionStatus.reviewing);
      expect(
        byId['child-mission']!.effectiveVerificationStatus,
        MissionVerificationStatus.approved,
      );
      expect(
        byId['child-mission']!.effectiveStatus,
        TodayMissionStatus.completed,
      );
    });

    test(
      'approveMissionPerformance patches concrete performance endpoint',
      () async {
        final List<String> calls = <String>[];
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  calls.add('${options.method} ${options.path}');
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'isSuccess': true, 'data': 'ok'},
                    ),
                  );
                },
          ),
        );
        final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

        final Result<void> result = await repository.approveMissionPerformance(
          parentId: 'parent-1',
          childrenId: '22',
          performanceId: '201',
        );

        expect(result, isA<Success<void>>());
        expect(calls, <String>[
          'PATCH /api/v1/missions/performances/201/approve',
        ]);
      },
    );

    test('loadMissions rejects non-numeric child id before network', () async {
      final List<String> calls = <String>[];
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                calls.add('${options.method} ${options.path}');
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{'isSuccess': true},
                  ),
                );
              },
        ),
      );
      final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

      final Result<List<TodayMission>> result = await repository.loadMissions(
        parentId: 'parent-1',
        childrenId: 'child-22',
      );

      expect(result, isA<Failure<List<TodayMission>>>());
      expect(
        (result as Failure<List<TodayMission>>).message,
        '자녀 정보를 다시 불러와 주세요.',
      );
      expect(calls, isEmpty);
    });

    test('addMission rejects non-numeric child id before network', () async {
      final List<String> calls = <String>[];
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                calls.add('${options.method} ${options.path}');
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{'isSuccess': true},
                  ),
                );
              },
        ),
      );
      final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

      final Result<void> result = await repository.addMission(
        parentId: 'parent-1',
        childrenId: 'child-22',
        mission: const TodayMission(
          title: '방 청소',
          category: MissionCategory.cleaning,
          resetPeriod: MissionResetPeriod.daily,
          confirmationMethod: MissionConfirmationMethod.parent,
          rewardMinutes: 30,
          description: '사진 제출',
        ),
      );

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, '자녀 정보를 다시 불러와 주세요.');
      expect(calls, isEmpty);
    });

    test('approveMissionAt loads latest performance before patching', () async {
      final List<String> calls = <String>[];
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                calls.add('${options.method} ${options.path}');
                if (options.path ==
                    '/api/v1/missions/performances/201/approve') {
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'isSuccess': true, 'data': 'ok'},
                    ),
                  );
                  return;
                }
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: _missionResponseFor(options.path),
                  ),
                );
              },
        ),
      );
      final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

      final Result<void> result = await repository.approveMissionAt(
        parentId: 'parent-1',
        childrenId: '22',
        index: 0,
      );

      expect(result, isA<Success<void>>());
      expect(
        calls,
        containsAllInOrder(<String>[
          'GET /api/v1/missions',
          'GET /api/v1/missions/parent-mission',
          'GET /api/v1/missions/parent-mission/performance',
          'PATCH /api/v1/missions/performances/201/approve',
        ]),
      );
    });

    test('approveMissionPerformance maps invalid state errors', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 400,
                      data: <String, dynamic>{
                        'isSuccess': false,
                        'code': 'INVALID_MISSION_STATE',
                        'message': '대기 상태인 부모 확인 미션만 승인/반려할 수 있습니다.',
                      },
                    ),
                  ),
                );
              },
        ),
      );
      final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

      final Result<void> result = await repository.approveMissionPerformance(
        parentId: 'parent-1',
        childrenId: '22',
        performanceId: '201',
      );

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, '지금 상태에서는 이 작업을 할 수 없어요.');
    });

    test(
      'approveMissionPerformance rejects non-numeric performance id before network',
      () async {
        final List<String> calls = <String>[];
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  calls.add('${options.method} ${options.path}');
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'isSuccess': true},
                    ),
                  );
                },
          ),
        );
        final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

        final Result<void> result = await repository.approveMissionPerformance(
          parentId: 'parent-1',
          childrenId: '22',
          performanceId: 'mission-201',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure<void>).message, '지금 상태에서는 이 작업을 할 수 없어요.');
        expect(calls, isEmpty);
      },
    );

    test(
      'rejectMissionPerformance rejects blank performance id before network',
      () async {
        final List<String> calls = <String>[];
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  calls.add('${options.method} ${options.path}');
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'isSuccess': true},
                    ),
                  );
                },
          ),
        );
        final ApiMissionRepository repository = ApiMissionRepository(dio: dio);

        final Result<void> result = await repository.rejectMissionPerformance(
          parentId: 'parent-1',
          childrenId: '22',
          performanceId: '  ',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure<void>).message, '지금 상태에서는 이 작업을 할 수 없어요.');
        expect(calls, isEmpty);
      },
    );
  });
}

dynamic _missionResponseFor(String path) {
  if (path == '/api/v1/missions') {
    return <String, dynamic>{
      'isSuccess': true,
      'data': <Map<String, dynamic>>[
        _missionJson('parent-mission', 'PARENT'),
        _missionJson('ai-mission', 'AI'),
        _missionJson('child-mission', 'CHILD'),
      ],
    };
  }

  final RegExpMatch? performanceMatch = RegExp(
    r'^/api/v1/missions/([^/]+)/performance$',
  ).firstMatch(path);
  if (performanceMatch != null) {
    final String missionId = performanceMatch.group(1)!;
    return <String, dynamic>{
      'isSuccess': true,
      'data': <String, dynamic>{
        'performanceId': _performanceIdFor(missionId),
        'status': 'PENDING',
        'proofImageUrl': 'https://test.local/proof.jpg',
      },
    };
  }

  final RegExpMatch? detailMatch = RegExp(
    r'^/api/v1/missions/([^/]+)$',
  ).firstMatch(path);
  if (detailMatch != null) {
    final String missionId = detailMatch.group(1)!;
    final String verificationType = switch (missionId) {
      'ai-mission' => 'AI',
      'child-mission' => 'CHILD',
      _ => 'PARENT',
    };
    return <String, dynamic>{
      'isSuccess': true,
      'data': _missionJson(missionId, verificationType),
    };
  }

  throw StateError('Unexpected request path: $path');
}

Map<String, dynamic> _missionJson(String missionId, String verificationType) {
  return <String, dynamic>{
    'missionId': missionId,
    'title': '$missionId title',
    'category': 'STUDY',
    'resetCycle': 'WEEKLY',
    'verificationType': verificationType,
    'reward': 30,
    'description': '$missionId description',
  };
}

int _performanceIdFor(String missionId) {
  return switch (missionId) {
    'ai-mission' => 202,
    'child-mission' => 203,
    _ => 201,
  };
}
