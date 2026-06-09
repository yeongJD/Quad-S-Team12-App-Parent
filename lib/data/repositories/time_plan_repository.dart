import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import '../../features/today_time/presentation/models/daily_time_rule.dart';
import 'api_time_plan_repository.dart';
import 'mock_time_plan_repository.dart';

class ChildTimeSummary {
  const ChildTimeSummary({
    required this.parentPolicyExists,
    required this.childPlanExists,
    required this.todayScheduleStatus,
    required this.basePolicyMinutes,
    required this.baseMinutes,
    required this.extendedMinutes,
    required this.totalAvailableMinutes,
    required this.rewardPoolMinutes,
  });

  final bool parentPolicyExists;
  final bool childPlanExists;
  final String todayScheduleStatus;
  final int basePolicyMinutes;
  final int baseMinutes;
  final int extendedMinutes;
  final int totalAvailableMinutes;
  final int rewardPoolMinutes;

  bool get hasTodaySchedule => todayScheduleStatus == 'available';
  bool get hasDisplayableTodayTime =>
      hasTodaySchedule && totalAvailableMinutes > 0;
}

/// Repository contract for the per-child time-plan domain.
///
/// One repository for four logically related but independently editable
/// sub-resources:
/// 1. dailyRules — parent-set allowed-duration rules per weekday set
/// 2. childWeeklyRules — child-set weekly plan visible to the parent
/// 3. monthlyTotalMinutes — total monthly screen-time budget
/// 4. whitelistAppIds — apps exempted from the budget
///
/// Pages read sub-resources independently (the four `load*` methods) so the
/// repository keeps a coarse-grained interface rather than forcing a single
/// fat aggregate DTO. Backend implementations may collapse multiple
/// `load*` calls into one round-trip if they wish — see docs/api/04-time-plan.md.
abstract interface class TimePlanRepository {
  Future<Result<List<DailyTimeRule>>> loadDailyRules({
    required String parentId,
    required String childrenId,
  });

  Future<Result<void>> saveDailyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  });

  Future<Result<List<DailyTimeRule>>> loadChildWeeklyRules({
    required String parentId,
    required String childrenId,
  });

  Future<Result<void>> saveChildWeeklyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  });

  Future<Result<int?>> loadMonthlyTotal({
    required String parentId,
    required String childrenId,
  });

  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  });

  Future<Result<ChildTimeSummary>> loadChildTimeSummary({
    required String parentId,
    required String childrenId,
    DateTime? date,
  });

  Future<Result<Set<String>>> loadWhitelist({
    required String parentId,
    required String childrenId,
  });

  Future<Result<void>> saveWhitelist({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  });
}

final TimePlanRepository _timePlanRepository = currentEnvironment.useMocks
    ? MockTimePlanRepository()
    : ApiTimePlanRepository();

TimePlanRepository createTimePlanRepository() => _timePlanRepository;
