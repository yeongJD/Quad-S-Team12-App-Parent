enum NotificationType {
  missionCompleted,
  missionConfirmationRequested,
  timeConfigured,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.actionLabel = '확인하러 가기',
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeAgo;
  final String actionLabel;
}
