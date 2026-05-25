import '../../../../core/auth/account_store.dart';
import '../models/daily_time_rule.dart';

abstract final class ChildWeeklyTimePlanStore {
  static Future<void> save({
    required String parentId,
    required String childrenId,
    required List<DailyTimeRule> rules,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return;
    }

    await AccountStore.updateChild(
      parentId: parentId,
      childrenId: childrenId,
      update: (AccountChildData child) {
        return child.copyWith(
          childWeeklyRules: rules.map(_encodeRule).toList(growable: false),
        );
      },
    );
  }

  static Future<List<DailyTimeRule>> load({
    required String parentId,
    required String childrenId,
  }) async {
    if (parentId.isEmpty || childrenId.isEmpty) {
      return <DailyTimeRule>[];
    }

    final AccountChildData? child = await AccountStore.getChild(
      parentId: parentId,
      childrenId: childrenId,
    );
    if (child == null) {
      return <DailyTimeRule>[];
    }

    return child.childWeeklyRules
        .map(_decodeRule)
        .whereType<DailyTimeRule>()
        .toList();
  }

  static Map<String, Object> _encodeRule(DailyTimeRule rule) {
    return <String, Object>{
      'days': rule.days.toList()..sort(),
      'hour': rule.time.hour,
      'minute': rule.time.minute,
    };
  }

  static DailyTimeRule? _decodeRule(Map<String, Object?> json) {
    final Object? daysValue = json['days'];
    final Object? hourValue = json['hour'];
    final Object? minuteValue = json['minute'];
    if (daysValue is! List<Object?> ||
        hourValue is! int ||
        minuteValue is! int) {
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
