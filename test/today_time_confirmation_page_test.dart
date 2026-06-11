import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/time_plan_repository.dart';
import 'package:bridge_p/features/today_time/presentation/models/daily_time_rule.dart';
import 'package:bridge_p/features/today_time/presentation/pages/today_time_confirmation_page.dart';
import 'package:bridge_p/features/today_time/presentation/widgets/time_plan_confirmation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses saved monthly policy instead of recalculated local draft', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayTimeConfirmationPage(
          parentId: 'parent-1',
          childrenId: 'child-1',
          timePlanRepository: _SavedPolicyRepository(
            dailyRules: const <DailyTimeRule>[
              DailyTimeRule(
                days: <int>{0, 1, 2, 3, 4, 5, 6},
                time: TimeSelection(hour: 2, minute: 0),
              ),
            ],
            monthlyTotalMinutes: 600,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is TimeAmountText &&
            widget.time.hour == 10 &&
            widget.time.minute == 0,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is TimeAmountText && widget.time.hour >= 60,
      ),
      findsNothing,
    );
  });
}

class _SavedPolicyRepository implements TimePlanRepository {
  const _SavedPolicyRepository({
    required this.dailyRules,
    required this.monthlyTotalMinutes,
  });

  final List<DailyTimeRule> dailyRules;
  final int? monthlyTotalMinutes;

  @override
  Future<Result<List<DailyTimeRule>>> loadDailyRules({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<List<DailyTimeRule>>.success(dailyRules);
  }

  @override
  Future<Result<void>> saveDailyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    return Result<void>.success(null);
  }

  @override
  Future<Result<List<DailyTimeRule>>> loadChildWeeklyRules({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<List<DailyTimeRule>>.success(const <DailyTimeRule>[]);
  }

  @override
  Future<Result<void>> saveChildWeeklyRules({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    return Result<void>.success(null);
  }

  @override
  Future<Result<int?>> loadMonthlyTotal({
    required String parentId,
    required String childrenId,
  }) async {
    return Result<int?>.success(monthlyTotalMinutes);
  }

  @override
  Future<Result<void>> saveMonthlyTotal({
    required String parentId,
    required String childrenId,
    required int totalMinutes,
  }) async {
    return Result<void>.success(null);
  }

  @override
  Future<Result<ChildTimeSummary>> loadChildTimeSummary({
    required String parentId,
    required String childrenId,
    DateTime? date,
  }) async {
    return Result<ChildTimeSummary>.success(
      const ChildTimeSummary(
        parentPolicyExists: true,
        childPlanExists: false,
        todayScheduleStatus: 'waitingChildPlan',
        basePolicyMinutes: 0,
        baseMinutes: 0,
        extendedMinutes: 0,
        totalAvailableMinutes: 0,
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
    return Result<Set<String>>.success(<String>{});
  }

  @override
  Future<Result<void>> saveWhitelist({
    required String parentId,
    required String childrenId,
    required Set<String> appIds,
  }) async {
    return Result<void>.success(null);
  }
}
