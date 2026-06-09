import 'package:dio/dio.dart';

import '../../core/config/dio_config.dart';
import '../../core/models/result.dart';
import '../../core/network/api_error.dart';
import '../../features/today_time/presentation/data/child_weekly_time_plan_store.dart';
import '../../features/today_time/presentation/data/daily_time_rule_store.dart';
import '../../features/today_time/presentation/data/monthly_total_time_store.dart';
import '../../features/today_time/presentation/data/whitelist_app_store.dart';
import '../../features/today_time/presentation/models/daily_time_rule.dart';
import 'time_plan_repository.dart';

/// Network-backed [TimePlanRepository] per `docs/api/04-time-plan.md`.
///
/// Uses the AWS Swagger time-policy endpoints where they exist. Daily/weekly
/// draft rules and whitelist app ids have no AWS endpoints, so those remain
/// local-only instead of calling legacy `/children/{id}/time-plan/*` paths.
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
    // Backend has no /time-plan/monthly-total. Parent reads the same
    // parent-scoped summary used by the home screen; do not call the child
    // policy API here because that endpoint is child-token scoped.
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/parents/children/$childrenId/time-summary',
        queryParameters: <String, dynamic>{'date': _yyyyMmDd(DateTime.now())},
      );
      final Map<String, dynamic>? data = _jsonMap(response.data);
      if (data == null) {
        return Result<int?>.success(null);
      }
      final int basePolicyMinutes = _intValue(data['basePolicyMinutes']);
      return Result<int?>.success(
        basePolicyMinutes > 0 ? basePolicyMinutes : null,
      );
    } on DioException catch (e) {
      final int? localTotal = await MonthlyTotalTimeStore.load(
        parentId: parentId,
        childrenId: childrenId,
      );
      if (localTotal != null) {
        return Result<int?>.success(localTotal > 0 ? localTotal : null);
      }
      return failureFromDioException<int?>(e);
    }
  }

  @override
  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    final int? childId = int.tryParse(childrenId);
    if (childId == null) {
      return Result<void>.failure('자녀 정보를 다시 불러와 주세요.');
    }
    if (totalMinutes <= 0) {
      return Result<void>.failure('이번 달 총 시간은 0분보다 커야 합니다.');
    }

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
          'childId': childId,
          'yearMonth': _currentYearMonth(),
          'baseTime': totalMinutes,
        },
      );
      await MonthlyTotalTimeStore.save(
        parentId: parentId,
        childrenId: childrenId,
        totalMinutes: totalMinutes,
      );
      return Result<void>.success(null);
    } on DioException catch (e) {
      return failureFromDioException<void>(e);
    }
  }

  @override
  Future<Result<ChildTimeSummary>> loadChildTimeSummary({
    required String parentId,
    required String childrenId,
    DateTime? date,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/parents/children/$childrenId/time-summary',
        queryParameters: <String, dynamic>{
          if (date != null) 'date': _yyyyMmDd(date),
        },
      );
      final Map<String, dynamic>? data = _jsonMap(response.data);
      if (data == null) {
        return Result<ChildTimeSummary>.success(_emptySummary());
      }
      return Result<ChildTimeSummary>.success(_timeSummaryFromJson(data));
    } on DioException catch (e) {
      final ChildTimeSummary? fallback = await _localTimeSummaryFallback(
        parentId: parentId,
        childrenId: childrenId,
        date: date,
      );
      if (fallback != null) {
        return Result<ChildTimeSummary>.success(fallback);
      }
      return failureFromDioException<ChildTimeSummary>(e);
    }
  }

  @override
  Future<Result<Set<String>>> loadWhitelist({
    required String parentId,
    required String childrenId,
  }) async {
    final Set<String> ids = await WhitelistAppStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    return Result<Set<String>>.success(ids);
  }

  @override
  Future<Result<void>> saveWhitelist({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  }) async {
    await WhitelistAppStore.save(
      parentId: parentId,
      childrenId: childrenId,
      appIds: appIds,
    );
    return Result<void>.success(null);
  }

  /// Current `"yyyy-MM"` — the month the time policy is filed under. Must match
  /// the month the child app uses for weekly-budgets/templates.
  String _currentYearMonth() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
  }

  String _yyyyMmDd(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  ChildTimeSummary _timeSummaryFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> todaySchedule = json['todaySchedule'] is Map
        ? Map<String, dynamic>.from(json['todaySchedule'] as Map)
        : const <String, dynamic>{};
    final int baseMinutes = _intValue(todaySchedule['baseMinutes']);
    final int extendedMinutes = _intValue(todaySchedule['extendedMinutes']);
    return ChildTimeSummary(
      parentPolicyExists: json['parentPolicyExists'] == true,
      childPlanExists: json['childPlanExists'] == true,
      todayScheduleStatus:
          json['todayScheduleStatus']?.toString() ?? 'noParentPolicy',
      basePolicyMinutes: _intValue(json['basePolicyMinutes']),
      baseMinutes: baseMinutes,
      extendedMinutes: extendedMinutes,
      totalAvailableMinutes: _intValue(
        todaySchedule['totalAvailableMinutes'],
        fallback: baseMinutes + extendedMinutes,
      ),
      rewardPoolMinutes: _intValue(json['rewardPoolMinutes']),
    );
  }

  ChildTimeSummary _emptySummary() {
    return const ChildTimeSummary(
      parentPolicyExists: false,
      childPlanExists: false,
      todayScheduleStatus: 'noParentPolicy',
      basePolicyMinutes: 0,
      baseMinutes: 0,
      extendedMinutes: 0,
      totalAvailableMinutes: 0,
      rewardPoolMinutes: 0,
    );
  }

  Future<ChildTimeSummary?> _localTimeSummaryFallback({
    required String parentId,
    required String childrenId,
    DateTime? date,
  }) async {
    final int? monthlyTotal = await MonthlyTotalTimeStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (monthlyTotal == null || monthlyTotal <= 0) {
      return _emptySummary();
    }

    final List<DailyTimeRule> rules = await ChildWeeklyTimePlanStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (rules.isEmpty) {
      return ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: false,
        todayScheduleStatus: 'waitingChildPlan',
        basePolicyMinutes: monthlyTotal,
        baseMinutes: 0,
        extendedMinutes: 0,
        totalAvailableMinutes: 0,
        rewardPoolMinutes: 0,
      );
    }

    final int weekdayIndex = (date ?? DateTime.now()).weekday - 1;
    DailyTimeRule? todayRule;
    for (final DailyTimeRule rule in rules) {
      if (rule.days.contains(weekdayIndex)) {
        todayRule = rule;
        break;
      }
    }
    if (todayRule == null) {
      return ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: true,
        todayScheduleStatus: 'templateMissing',
        basePolicyMinutes: monthlyTotal,
        baseMinutes: 0,
        extendedMinutes: 0,
        totalAvailableMinutes: 0,
        rewardPoolMinutes: 0,
      );
    }

    final int baseMinutes = todayRule.time.hour * 60 + todayRule.time.minute;
    return ChildTimeSummary(
      parentPolicyExists: true,
      childPlanExists: true,
      todayScheduleStatus: 'available',
      basePolicyMinutes: monthlyTotal,
      baseMinutes: baseMinutes,
      extendedMinutes: 0,
      totalAvailableMinutes: baseMinutes,
      rewardPoolMinutes: 0,
    );
  }

  int _intValue(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  Map<String, dynamic>? _jsonMap(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
