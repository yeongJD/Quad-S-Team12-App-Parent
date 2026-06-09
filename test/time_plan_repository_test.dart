import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/api_time_plan_repository.dart';
import 'package:bridge_p/data/repositories/time_plan_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
                      'parentPolicyExists': true,
                      'childPlanExists': false,
                      'todayScheduleStatus': 'waitingChildPlan',
                      'yearMonth': '2026-06',
                      'basePolicyMinutes': 600,
                      'todaySchedule': null,
                      'rewardPoolMinutes': 30,
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
  });
}
