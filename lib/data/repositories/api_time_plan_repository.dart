import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/today_time/presentation/data/child_weekly_time_plan_store.dart';
import '../../features/today_time/presentation/data/daily_time_rule_store.dart';
import '../../features/today_time/presentation/models/daily_time_rule.dart';
import 'time_plan_repository.dart';

/// Network-backed [TimePlanRepository] per `docs/api/04-time-plan.md`.
///
/// Endpoints sit under `/children/{childrenId}/time-plan/*` and accept
/// `parentId` as a query param for authorisation. Each sub-resource has
/// its own GET / PUT pair — backends that prefer a single aggregate GET
/// can implement that as an optimisation while still honouring the
/// individual PUTs (see contract doc for details).
class ApiTimePlanRepository implements TimePlanRepository {
  ApiTimePlanRepository({Dio? dio}) : _dio = dio ?? DioConfig.create();

  final Dio _dio;

  // daily-rules / weekly-rules are a parent-only planning aid — they are NOT
  // sent to the backend (the child sets their own schedule via the schedules
  // endpoints, and the backend has no parent-rule processing). We persist them
  // locally so the parent's draft survives, identical to the mock path.

  @override
  Future<Result<List<DailyTimeRule>>> loadDailyRules({
    required String parentId,
    required String childrenId,
  }) async {
    final List<DailyTimeRule> rules = await DailyTimeRuleStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    return Result<List<DailyTimeRule>>.success(rules);
  }

  @override
  Future<Result<void>> saveDailyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    await DailyTimeRuleStore.save(
      parentId: parentId,
      childrenId: childrenId,
      rules: rules,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<List<DailyTimeRule>>> loadChildWeeklyRules({
    required String parentId,
    required String childrenId,
  }) async {
    final List<DailyTimeRule> rules = await ChildWeeklyTimePlanStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    return Result<List<DailyTimeRule>>.success(rules);
  }

  @override
  Future<Result<void>> saveChildWeeklyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    await ChildWeeklyTimePlanStore.save(
      parentId: parentId,
      childrenId: childrenId,
      rules: rules,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<int?>> loadMonthlyTotal({
    required String parentId,
    required String childrenId,
  }) async {
    // Backend has no /time-plan/monthly-total; the child's monthly base time is
    // read from the policy snapshot (GET /api/v1/children/{id}/policies). We
    // surface `baseTime` (the parent-set pure base) as the monthly total.
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/children/$childrenId/policies',
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<int?>.success(null);
      }
      final dynamic value = data['baseTime'];
      return Result<int?>.success(value is num ? value.toInt() : null);
    } on DioException catch (e) {
      return failureFromDioException<int?>(e);
    }
  }

  @override
  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    // Backend has no /time-plan/monthly-total; the parent sets the child's
    // monthly base time via POST /api/v1/parents/time-policy (parent resolved
    // from JWT). This baseTime is the prerequisite the child's weekly-budget
    // save validates against, so both sides file it under the same yearMonth.
    // baseTime must be > 0 (backend @Positive) — a 0 total is rejected with the
    // backend's Korean message, surfaced via failureFromDioException.
    try {
      await _dio.post<dynamic>(
        '/api/v1/parents/time-policy',
        data: <String, dynamic>{
          'childId': int.tryParse(childrenId) ?? childrenId,
          'yearMonth': _currentYearMonth(),
          'baseTime': totalMinutes,
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<Set<String>>> loadWhitelist({
    required String parentId,
    required String childrenId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/children/$childrenId/time-plan/whitelist',
        queryParameters: <String, dynamic>{'parentId': parentId},
      );
      final dynamic data = response.data;
      if (data is! Map) {
        return Result<Set<String>>.success(<String>{});
      }
      final dynamic appIds = data['appIds'];
      if (appIds is! List) {
        return Result<Set<String>>.success(<String>{});
      }
      return Result<Set<String>>.success(appIds.whereType<String>().toSet());
    } on DioException catch (e) {
      return failureFromDioException<Set<String>>(e);
    }
  }

  @override
  Future<Result<void>> saveWhitelist({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/children/$childrenId/time-plan/whitelist',
        queryParameters: <String, dynamic>{'parentId': parentId},
        data: <String, dynamic>{
          'appIds': (appIds.toList()..sort()),
        },
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  /// Current `"yyyy-MM"` — the month the time policy is filed under. Must match
  /// the month the child app uses for weekly-budgets/templates.
  String _currentYearMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
  }
}
