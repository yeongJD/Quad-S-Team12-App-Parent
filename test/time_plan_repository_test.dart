import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/api_time_plan_repository.dart';
import 'package:bridge_p/data/repositories/time_plan_repository.dart';
import 'package:bridge_p/features/today_time/presentation/data/monthly_total_time_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ApiTimePlanRepository', () {
    test('loads monthly total from parent child time summary', () async {
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
                    data: <String, dynamic>{
                      'isSuccess': true,
                      'data': <String, dynamic>{
                        'parentPolicyExists': true,
                        'childPlanExists': false,
                        'todayScheduleStatus': 'waitingChildPlan',
                        'yearMonth': '2026-06',
                        'basePolicyMinutes': 600,
                        'todaySchedule': null,
                        'rewardPoolMinutes': 30,
                      },
                    },
                  ),
                );
              },
        ),
      );
      final ApiTimePlanRepository repository = ApiTimePlanRepository(dio: dio);

      final Result<int?> result = await repository.loadMonthlyTotal(
        parentId: '1',
        childrenId: '2',
      );

      expect(result, isA<Success<int?>>());
      expect((result as Success<int?>).data, 600);
      expect(calls, <String>['GET /api/v1/parents/children/2/time-summary']);
    });

    test('loads null monthly total when parent policy is missing', () async {
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
                    data: <String, dynamic>{
                      'isSuccess': true,
                      'data': <String, dynamic>{
                        'parentPolicyExists': false,
                        'childPlanExists': false,
                        'todayScheduleStatus': 'noParentPolicy',
                        'yearMonth': '2026-06',
                        'basePolicyMinutes': 0,
                        'todaySchedule': null,
                        'rewardPoolMinutes': 0,
                      },
                    },
                  ),
                );
              },
        ),
      );
      final ApiTimePlanRepository repository = ApiTimePlanRepository(dio: dio);

      final Result<int?> result = await repository.loadMonthlyTotal(
        parentId: '1',
        childrenId: '2',
      );

      expect(result, isA<Success<int?>>());
      expect((result as Success<int?>).data, isNull);
      expect(calls, <String>['GET /api/v1/parents/children/2/time-summary']);
    });

    test('saves monthly total as parent time policy baseTime', () async {
      final List<RequestOptions> calls = <RequestOptions>[];
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                calls.add(options);
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{'isSuccess': true, 'data': null},
                  ),
                );
              },
        ),
      );
      final ApiTimePlanRepository repository = ApiTimePlanRepository(dio: dio);

      final Result<void> result = await repository.saveMonthlyTotal(
        parentId: '1',
        childrenId: '2',
        totalMinutes: 600,
      );

      expect(result, isA<Success<void>>());
      expect(calls, hasLength(1));
      expect(calls.single.method, 'POST');
      expect(calls.single.path, '/api/v1/parents/time-policy');
      expect(calls.single.data, <String, dynamic>{
        'childId': 2,
        'yearMonth': matches(RegExp(r'^\d{4}-\d{2}$')),
        'baseTime': 600,
      });
    });

    test(
      'saves monthly total to local fallback after backend success',
      () async {
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'isSuccess': true, 'data': null},
                    ),
                  );
                },
          ),
        );
        final ApiTimePlanRepository repository = ApiTimePlanRepository(
          dio: dio,
        );

        final Result<void> result = await repository.saveMonthlyTotal(
          parentId: '1',
          childrenId: '2',
          totalMinutes: 600,
        );

        expect(result, isA<Success<void>>());
        expect(
          await MonthlyTotalTimeStore.load(parentId: '1', childrenId: '2'),
          600,
        );
      },
    );

    test('rejects invalid monthly total before network call', () async {
      bool wasCalled = false;
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                wasCalled = true;
                handler.reject(
                  DioException(
                    requestOptions: options,
                    message: 'network should not be called',
                  ),
                );
              },
        ),
      );
      final ApiTimePlanRepository repository = ApiTimePlanRepository(dio: dio);

      final Result<void> result = await repository.saveMonthlyTotal(
        parentId: '1',
        childrenId: '2',
        totalMinutes: 0,
      );

      expect(result, isA<Failure<void>>());
      expect(wasCalled, isFalse);
      if (result case Failure<void>(:final String message)) {
        expect(message, contains('0분보다'));
      }
    });

    test('rejects non-numeric child id before saving monthly total', () async {
      bool wasCalled = false;
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                wasCalled = true;
                handler.reject(
                  DioException(
                    requestOptions: options,
                    message: 'network should not be called',
                  ),
                );
              },
        ),
      );
      final ApiTimePlanRepository repository = ApiTimePlanRepository(dio: dio);

      final Result<void> result = await repository.saveMonthlyTotal(
        parentId: '1',
        childrenId: 'GDG12-1',
        totalMinutes: 600,
      );

      expect(result, isA<Failure<void>>());
      expect(wasCalled, isFalse);
      if (result case Failure<void>(:final String message)) {
        expect(message, contains('자녀 정보'));
      }
    });

    test('parses policy base and reward pool from time summary', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'isSuccess': true,
                      'data': <String, dynamic>{
                        'parentPolicyExists': true,
                        'childPlanExists': true,
                        'todayScheduleStatus': 'available',
                        'yearMonth': '2026-06',
                        'basePolicyMinutes': 600,
                        'todaySchedule': <String, dynamic>{
                          'baseMinutes': 60,
                          'extendedMinutes': 10,
                          'totalAvailableMinutes': 70,
                        },
                        'rewardPoolMinutes': 30,
                      },
                    },
                  ),
                );
              },
        ),
      );
      final ApiTimePlanRepository repository = ApiTimePlanRepository(dio: dio);

      final Result<ChildTimeSummary> result = await repository
          .loadChildTimeSummary(parentId: '1', childrenId: '2');

      expect(result, isA<Success<ChildTimeSummary>>());
      final ChildTimeSummary summary =
          (result as Success<ChildTimeSummary>).data;
      expect(summary.parentPolicyExists, isTrue);
      expect(summary.childPlanExists, isTrue);
      expect(summary.basePolicyMinutes, 600);
      expect(summary.baseMinutes, 60);
      expect(summary.extendedMinutes, 10);
      expect(summary.totalAvailableMinutes, 70);
      expect(summary.rewardPoolMinutes, 30);
    });

    test(
      'falls back to noParentPolicy when time summary request fails',
      () async {
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
                        statusCode: 404,
                      ),
                    ),
                  );
                },
          ),
        );
        final ApiTimePlanRepository repository = ApiTimePlanRepository(
          dio: dio,
        );

        final Result<ChildTimeSummary> result = await repository
            .loadChildTimeSummary(parentId: '1', childrenId: '2');

        expect(result, isA<Success<ChildTimeSummary>>());
        final ChildTimeSummary summary =
            (result as Success<ChildTimeSummary>).data;
        expect(summary.parentPolicyExists, isFalse);
        expect(summary.childPlanExists, isFalse);
        expect(summary.todayScheduleStatus, 'noParentPolicy');
      },
    );

    test(
      'falls back to waitingChildPlan when local monthly total exists',
      () async {
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
                        statusCode: 404,
                      ),
                    ),
                  );
                },
          ),
        );
        await MonthlyTotalTimeStore.save(
          parentId: '1',
          childrenId: '2',
          totalMinutes: 600,
        );
        final ApiTimePlanRepository repository = ApiTimePlanRepository(
          dio: dio,
        );

        final Result<ChildTimeSummary> result = await repository
            .loadChildTimeSummary(parentId: '1', childrenId: '2');

        expect(result, isA<Success<ChildTimeSummary>>());
        final ChildTimeSummary summary =
            (result as Success<ChildTimeSummary>).data;
        expect(summary.parentPolicyExists, isTrue);
        expect(summary.childPlanExists, isFalse);
        expect(summary.todayScheduleStatus, 'waitingChildPlan');
        expect(summary.basePolicyMinutes, 600);
      },
    );

    test('displayable today time follows total available minutes', () {
      const ChildTimeSummary rewardOnlyToday = ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: true,
        todayScheduleStatus: 'available',
        basePolicyMinutes: 600,
        baseMinutes: 0,
        extendedMinutes: 30,
        totalAvailableMinutes: 30,
        rewardPoolMinutes: 120,
        monthlyRemainingMinutes: 120,
      );
      const ChildTimeSummary zeroToday = ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: true,
        todayScheduleStatus: 'available',
        basePolicyMinutes: 600,
        baseMinutes: 0,
        extendedMinutes: 0,
        totalAvailableMinutes: 0,
        rewardPoolMinutes: 120,
        monthlyRemainingMinutes: 120,
      );
      const ChildTimeSummary waitingChildPlan = ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: false,
        todayScheduleStatus: 'waitingChildPlan',
        basePolicyMinutes: 600,
        baseMinutes: 60,
        extendedMinutes: 0,
        totalAvailableMinutes: 60,
        rewardPoolMinutes: 120,
        monthlyRemainingMinutes: 720,
      );

      expect(rewardOnlyToday.hasDisplayableTodayTime, isTrue);
      expect(zeroToday.hasDisplayableTodayTime, isTrue);
      expect(waitingChildPlan.hasDisplayableTodayTime, isFalse);
    });
  });
}
