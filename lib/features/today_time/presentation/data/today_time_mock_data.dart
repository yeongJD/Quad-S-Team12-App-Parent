import '../models/daily_time_rule.dart';
import '../models/time_plan_confirmation.dart';

abstract final class TodayTimeMockData {
  static const List<DailyTimeRule> emptyDailyRules = <DailyTimeRule>[];

  static const List<DailyTimeRule> completeDailyRules = <DailyTimeRule>[
    DailyTimeRule(
      days: <int>{0, 1, 2, 3, 4},
      time: TimeSelection(hour: 1, minute: 5),
    ),
    DailyTimeRule(days: <int>{5, 6}, time: TimeSelection(hour: 1, minute: 30)),
  ];

  static TimePlanConfirmationData get allEmptyConfirmation {
    final _DateLabels labels = _DateLabels.current();
    return TimePlanConfirmationData(
      monthLabel: labels.monthLabel,
      weekLabel: labels.weekLabel,
      childRevisionAllowed: false,
      weeklyRules: <DailyTimeRule>[],
    );
  }

  static TimePlanConfirmationData get childEmptyConfirmation {
    final _DateLabels labels = _DateLabels.current();
    return TimePlanConfirmationData(
      monthLabel: labels.monthLabel,
      monthlyTotal: const TimeSelection(hour: 64, minute: 40),
      weekLabel: labels.weekLabel,
      childRevisionAllowed: false,
      weeklyRules: <DailyTimeRule>[],
    );
  }

  static TimePlanConfirmationData get parentOnlyConfirmation {
    final _DateLabels labels = _DateLabels.current();
    return TimePlanConfirmationData(
      monthLabel: labels.monthLabel,
      monthlyTotal: const TimeSelection(hour: 64, minute: 40),
      weekLabel: labels.weekLabel,
      childRevisionAllowed: false,
      weeklyRules: <DailyTimeRule>[],
    );
  }

  static TimePlanConfirmationData get filledConfirmation {
    final _DateLabels labels = _DateLabels.current();
    return TimePlanConfirmationData(
      monthLabel: labels.monthLabel,
      monthlyTotal: const TimeSelection(hour: 64, minute: 40),
      weekLabel: labels.weekLabel,
      weeklyTotal: const TimeSelection(hour: 15, minute: 20),
      childRevisionAllowed: true,
      weeklyRules: const <DailyTimeRule>[
        DailyTimeRule(
          days: <int>{0, 2, 4},
          time: TimeSelection(hour: 7, minute: 0),
        ),
        DailyTimeRule(
          days: <int>{1, 3},
          time: TimeSelection(hour: 7, minute: 0),
        ),
        DailyTimeRule(
          days: <int>{5, 6},
          time: TimeSelection(hour: 7, minute: 0),
        ),
      ],
    );
  }

  static TimePlanConfirmationData confirmationForDemo(String? demo) {
    switch (demo) {
      case 'all-empty':
        return allEmptyConfirmation;
      case 'child-empty':
        return childEmptyConfirmation;
      case 'parent-only':
        return parentOnlyConfirmation;
      case 'filled':
        return filledConfirmation;
      default:
        return parentOnlyConfirmation;
    }
  }
}

final class _DateLabels {
  const _DateLabels({required this.monthLabel, required this.weekLabel});

  factory _DateLabels.current() {
    final DateTime now = DateTime.now();
    final int weekOfMonth = _weekOfMonth(now);
    return _DateLabels(
      monthLabel: '${now.month}월달 총 시간',
      weekLabel: '${now.month}월 $weekOfMonth주 자녀의 사용 계획',
    );
  }

  final String monthLabel;
  final String weekLabel;

  static int _weekOfMonth(DateTime date) {
    final DateTime firstDayOfMonth = DateTime(date.year, date.month);
    final int leadingDays =
        (firstDayOfMonth.weekday - DateTime.monday) % DateTime.daysPerWeek;
    return ((date.day + leadingDays - 1) ~/ DateTime.daysPerWeek) + 1;
  }
}
