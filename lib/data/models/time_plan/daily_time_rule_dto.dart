import '../../../features/today_time/presentation/models/daily_time_rule.dart';

/// JSON projection of [DailyTimeRule] used on the wire.
///
/// `days` is a list of 0..6 weekday indexes (matching `weekdayLabels` order:
/// Mon=0 .. Sun=6). `hour`/`minute` represent the allowed daily duration —
/// not a clock time of day — so a `TimeSelection(hour: 2, minute: 30)` means
/// "2h30m of allowed screen-time on the marked weekdays".
abstract final class DailyTimeRuleDto {
  static Map<String, Object> toJson(DailyTimeRule rule) {
    return <String, Object>{
      'days': (rule.days.toList()..sort()),
      'hour': rule.time.hour,
      'minute': rule.time.minute,
    };
  }

  static DailyTimeRule? fromJson(Map<String, dynamic> json) {
    final Object? daysValue = json['days'];
    final Object? hourValue = json['hour'];
    final Object? minuteValue = json['minute'];
    if (daysValue is! List || hourValue is! int || minuteValue is! int) {
      return null;
    }
    final List<int> dayIndexes = daysValue.whereType<int>().toList();
    if (dayIndexes.length != daysValue.length) {
      return null;
    }
    return DailyTimeRule(
      days: dayIndexes.toSet(),
      time: TimeSelection(hour: hourValue, minute: minuteValue),
    );
  }
}
