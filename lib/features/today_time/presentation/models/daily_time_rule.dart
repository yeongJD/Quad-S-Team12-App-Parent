const List<String> weekdayLabels = <String>['월', '화', '수', '목', '금', '토', '일'];

class TimeSelection {
  const TimeSelection({required this.hour, required this.minute});

  final int hour;
  final int minute;

  bool get isEmpty => hour == 0 && minute == 0;

  String get hourText => hour.toString().padLeft(2, '0');
  String get minuteText => minute.toString().padLeft(2, '0');

  String get displayText {
    if (minute == 0) {
      return '$hour시간';
    }
    if (hour == 0) {
      return '$minute분';
    }
    return '$hour시간 $minute분';
  }
}

class DailyTimeRule {
  const DailyTimeRule({required this.days, required this.time});

  final Set<int> days;
  final TimeSelection time;

  String get dayText {
    final Set<int> allDays = Set<int>.from(
      List<int>.generate(weekdayLabels.length, (int index) => index),
    );
    const Set<int> weekdays = <int>{0, 1, 2, 3, 4};
    const Set<int> weekend = <int>{5, 6};

    if (days.length == allDays.length && days.containsAll(allDays)) {
      return '매일';
    }
    if (days.length == weekdays.length && days.containsAll(weekdays)) {
      return '주중';
    }
    if (days.length == weekend.length && days.containsAll(weekend)) {
      return '주말';
    }

    final List<int> sortedDays = days.toList()..sort();
    return sortedDays.map((int index) => weekdayLabels[index]).join(', ');
  }
}

bool coversEveryWeekday(List<DailyTimeRule> rules) {
  final Set<int> coveredDays = <int>{};
  for (final DailyTimeRule rule in rules) {
    coveredDays.addAll(rule.days);
  }
  return coveredDays.length == weekdayLabels.length;
}

int calculateMonthlyMinutesForRules(
  List<DailyTimeRule> rules, {
  DateTime? month,
}) {
  final DateTime targetMonth = month ?? DateTime.now();
  final int lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final List<int> weekdayCounts = List<int>.filled(DateTime.daysPerWeek, 0);
  for (int day = 1; day <= lastDay; day++) {
    final int weekdayIndex =
        DateTime(targetMonth.year, targetMonth.month, day).weekday - 1;
    weekdayCounts[weekdayIndex]++;
  }

  int total = 0;
  for (final DailyTimeRule rule in rules) {
    final int dailyMinutes = rule.time.hour * 60 + rule.time.minute;
    for (final int dayIndex in rule.days) {
      if (dayIndex < 0 || dayIndex >= weekdayCounts.length) {
        continue;
      }
      total += dailyMinutes * weekdayCounts[dayIndex];
    }
  }
  return total;
}
