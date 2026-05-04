import 'daily_time_rule.dart';

class TimePlanConfirmationData {
  const TimePlanConfirmationData({
    required this.monthLabel,
    required this.weekLabel,
    required this.weeklyRules,
    required this.childRevisionAllowed,
    this.monthlyTotal,
    this.weeklyTotal,
  });

  final String monthLabel;
  final TimeSelection? monthlyTotal;
  final String weekLabel;
  final TimeSelection? weeklyTotal;
  final List<DailyTimeRule> weeklyRules;
  final bool childRevisionAllowed;

  bool get hasMonthlyRule => monthlyTotal != null;
  bool get hasWeeklyPlan => weeklyRules.isNotEmpty;
}
