import '../../core/models/result.dart';
import '../../features/today_time/presentation/data/child_weekly_time_plan_store.dart';
import '../../features/today_time/presentation/data/daily_time_rule_store.dart';
import '../../features/today_time/presentation/data/monthly_total_time_store.dart';
import '../../features/today_time/presentation/data/whitelist_app_store.dart';
import '../../features/today_time/presentation/models/daily_time_rule.dart';
import 'time_plan_repository.dart';

/// SharedPreferences-backed [TimePlanRepository] that delegates to the four
/// existing stores so local-first behaviour is preserved when
/// `currentEnvironment.useMocks` is true.
class MockTimePlanRepository implements TimePlanRepository {
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
    final int? totalMinutes = await MonthlyTotalTimeStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    return Result<int?>.success(totalMinutes);
  }

  @override
  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    await MonthlyTotalTimeStore.save(
      parentId: parentId,
      childrenId: childrenId,
      totalMinutes: totalMinutes,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<ChildTimeSummary>> loadChildTimeSummary({
    required String parentId,
    required String childrenId,
    DateTime? date,
  }) async {
    final int? monthlyTotal = await MonthlyTotalTimeStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    final bool hasParentPolicy = monthlyTotal != null && monthlyTotal > 0;
    if (!hasParentPolicy) {
      return Result<ChildTimeSummary>.success(
        ChildTimeSummary(
          parentPolicyExists: false,
          childPlanExists: false,
          todayScheduleStatus: 'noParentPolicy',
          basePolicyMinutes: 0,
          baseMinutes: 0,
          extendedMinutes: 0,
          totalAvailableMinutes: 0,
          rewardPoolMinutes: 0,
          monthlyRemainingMinutes: 0,
        ),
      );
    }

    final List<DailyTimeRule> rules = await ChildWeeklyTimePlanStore.load(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (rules.isEmpty) {
      return Result<ChildTimeSummary>.success(
        ChildTimeSummary(
          parentPolicyExists: true,
          childPlanExists: false,
          todayScheduleStatus: 'waitingChildPlan',
          basePolicyMinutes: monthlyTotal,
          baseMinutes: 0,
          extendedMinutes: 0,
          totalAvailableMinutes: 0,
          rewardPoolMinutes: 0,
          monthlyRemainingMinutes: 0,
        ),
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
      return Result<ChildTimeSummary>.success(
        ChildTimeSummary(
          parentPolicyExists: true,
          childPlanExists: true,
          todayScheduleStatus: 'templateMissing',
          basePolicyMinutes: monthlyTotal,
          baseMinutes: 0,
          extendedMinutes: 0,
          totalAvailableMinutes: 0,
          rewardPoolMinutes: 0,
          monthlyRemainingMinutes: 0,
        ),
      );
    }

    final int baseMinutes = todayRule.time.hour * 60 + todayRule.time.minute;
    return Result<ChildTimeSummary>.success(
      ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: true,
        todayScheduleStatus: 'available',
        basePolicyMinutes: monthlyTotal,
        baseMinutes: baseMinutes,
        extendedMinutes: 0,
        totalAvailableMinutes: baseMinutes,
        rewardPoolMinutes: 0,
        monthlyRemainingMinutes: 0,
      ),
    );
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
}
