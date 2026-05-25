String currentMonthWeekLabel({DateTime? now}) {
  final DateTime date = now ?? DateTime.now();
  final int weekOfMonth = ((date.day - 1) ~/ 7) + 1;
  return '${date.month}월 $weekOfMonth주차';
}
