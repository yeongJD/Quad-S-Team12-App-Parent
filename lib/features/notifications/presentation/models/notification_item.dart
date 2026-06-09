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
    this.isRead = false,
    this.payload,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeAgo;
  final String actionLabel;
  final bool isRead;
  final Map<String, Object?>? payload;

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? timeAgo,
    String? actionLabel,
    bool? isRead,
    Map<String, Object?>? payload,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      actionLabel: actionLabel ?? this.actionLabel,
      isRead: isRead ?? this.isRead,
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
      'isRead': isRead,
      if (payload case final Map<String, Object?> payload) 'payload': payload,
    };
  }

  static NotificationItem? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }

    final Object? id = json['notificationId'];
    final Object? type = json['notificationType'];
    final Object? title = json['title'];
    final Object? message = json['content'];
    final Object? createdAt = json['createdAt'];
    final Object? actionLabel = json['actionLabel'];
    final Object? isRead = json['isRead'];
    final Object? payload = json['payload'];
    // Backend sends notificationId as a number (Long); accept any non-null and
    // stringify so notifications are not silently dropped.
    if (id == null ||
        type is! String ||
        title is! String ||
        message is! String ||
        createdAt is! String ||
        (actionLabel != null && actionLabel is! String) ||
        (isRead != null && isRead is! bool) ||
        (payload != null && payload is! Map<String, Object?>)) {
      return null;
    }

    final NotificationType decodedType = _decodeType(type);

    return NotificationItem(
      id: id.toString(),
      type: decodedType,
      title: title,
      message: message,
      timeAgo: _formatTimeAgo(createdAt),
      actionLabel: actionLabel is String ? actionLabel : '확인하러 가기',
      isRead: isRead is bool ? isRead : false,
      payload: _payloadFromJson(json, payload),
    );
  }

  static Map<String, Object?>? _payloadFromJson(
    Map<String, Object?> json,
    Object? rawPayload,
  ) {
    final Map<String, Object?> payload = rawPayload is Map
        ? Map<String, Object?>.from(rawPayload)
        : <String, Object?>{};
    for (final String key in <String>[
      'childId',
      'childrenId',
      'childCode',
      'missionId',
      'missionIndex',
      'performanceId',
      'targetRoute',
      'deeplink',
    ]) {
      final Object? value = json[key];
      if (value != null) {
        payload[key] = value;
      }
    }
    return payload.isEmpty ? null : payload;
  }

  static String _formatTimeAgo(String createdAt) {
    final DateTime? parsed = DateTime.tryParse(createdAt);
    if (parsed == null) {
      return createdAt;
    }
    final Duration diff = DateTime.now().difference(parsed.toLocal());
    if (diff.isNegative || diff.inMinutes < 1) {
      return '방금 전';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}시간 전';
    }
    return '${diff.inDays}일 전';
  }

  static NotificationType _decodeType(String name) {
    // App-enum name match first (keeps mock payloads working).
    for (final NotificationType type in NotificationType.values) {
      if (type.name == name) {
        return type;
      }
    }
    // Backend NotificationType {MISSION_CREATED, MISSION_APPROVED,
    // MISSION_REJECTED, GENERAL} → closest parent-app category.
    switch (name) {
      case 'MISSION_APPROVED':
        return NotificationType.missionCompleted;
      case 'MISSION_CREATED':
      case 'MISSION_REQUESTED':
      case 'MISSION_REJECTED':
        return NotificationType.missionConfirmationRequested;
      case 'GENERAL':
      default:
        return NotificationType.timeConfigured;
    }
  }
}
