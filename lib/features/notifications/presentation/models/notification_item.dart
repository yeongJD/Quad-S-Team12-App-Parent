enum NotificationType {
  weeklyUsageReport,
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
    this.payload,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeAgo;
  final String actionLabel;
  final Map<String, Object?>? payload;

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? timeAgo,
    String? actionLabel,
    Map<String, Object?>? payload,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      actionLabel: actionLabel ?? this.actionLabel,
      payload: payload ?? this.payload,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timeAgo': timeAgo,
      'actionLabel': actionLabel,
      if (payload case final Map<String, Object?> payload) 'payload': payload,
    };
  }

  static NotificationItem? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }

    final Object? id = json['id'];
    final Object? type = json['type'];
    final Object? title = json['title'];
    final Object? message = json['message'];
    final Object? timeAgo = json['timeAgo'];
    final Object? actionLabel = json['actionLabel'];
    final Object? payload = json['payload'];
    if (id is! String ||
        type is! String ||
        title is! String ||
        message is! String ||
        timeAgo is! String ||
        (actionLabel != null && actionLabel is! String) ||
        (payload != null && payload is! Map<String, Object?>)) {
      return null;
    }

    final NotificationType? decodedType = _decodeType(type);
    if (decodedType == null) {
      return null;
    }

    return NotificationItem(
      id: id,
      type: decodedType,
      title: title,
      message: message,
      timeAgo: timeAgo,
      actionLabel: actionLabel is String ? actionLabel : '확인하러 가기',
      payload: payload is Map<String, Object?> ? payload : null,
    );
  }

  static NotificationType? _decodeType(String name) {
    for (final NotificationType type in NotificationType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return null;
  }
}
