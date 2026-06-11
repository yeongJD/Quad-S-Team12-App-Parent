import 'package:bridge_p/features/today_time/presentation/models/daily_time_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monthly total counts real weekdays in the calendar month', () {
    const List<DailyTimeRule> rules = <DailyTimeRule>[
      DailyTimeRule(
        days: <int>{0, 1, 2, 3, 4},
        time: TimeSelection(hour: 1, minute: 0),
      ),
      DailyTimeRule(days: <int>{5, 6}, time: TimeSelection(hour: 2, minute: 0)),
    ];

    final int totalMinutes = calculateMonthlyMinutesForRules(
      rules,
      month: DateTime(2026, 6),
    );

    // June 2026 starts on Monday: Mon/Tue occur 5 times, Wed-Sun 4 times.
    expect(totalMinutes, 2280);
  });

  test('monthly total ignores invalid weekday indexes', () {
    const List<DailyTimeRule> rules = <DailyTimeRule>[
      DailyTimeRule(days: <int>{0, 7}, time: TimeSelection(hour: 1, minute: 0)),
    ];

    final int totalMinutes = calculateMonthlyMinutesForRules(
      rules,
      month: DateTime(2026, 6),
    );

    expect(totalMinutes, 300);
  });
}
