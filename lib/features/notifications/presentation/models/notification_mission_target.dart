import '../../../today_mission/presentation/models/today_mission.dart';
import 'notification_item.dart';

bool shouldOpenMissionDetailFromNotification(NotificationItem item) {
  return switch (item.type) {
        NotificationType.missionCompleted ||
        NotificationType.missionConfirmationRequested => true,
        NotificationType.timeConfigured ||
        NotificationType.weeklyUsageReport => false,
      } &&
      notificationHasMissionTarget(item);
}

bool notificationHasMissionTarget(NotificationItem item) {
  return notificationMissionId(item) != null ||
      notificationPerformanceId(item) != null ||
      notificationMissionIndex(item) != null;
}

String? notificationMissionId(NotificationItem item) {
  return _payloadString(item.payload, 'missionId');
}

String? notificationPerformanceId(NotificationItem item) {
  return _payloadString(item.payload, 'performanceId');
}

int? notificationMissionIndex(NotificationItem item) {
  final Object? missionIndex = item.payload?['missionIndex'];
  if (missionIndex is int) {
    return missionIndex;
  }
  if (missionIndex is String) {
    return int.tryParse(missionIndex);
  }
  return null;
}

int? notificationMissionIndexForMissions(
  List<TodayMission> missions,
  NotificationItem item,
) {
  final String? missionId = notificationMissionId(item);
  if (missionId != null) {
    final int index = missions.indexWhere(
      (TodayMission mission) => mission.missionId == missionId,
    );
    if (index >= 0) {
      return index;
    }
  }

  final String? performanceId = notificationPerformanceId(item);
  if (performanceId != null) {
    final int index = missions.indexWhere(
      (TodayMission mission) => mission.performanceId == performanceId,
    );
    if (index >= 0) {
      return index;
    }
  }

  final int? missionIndex = notificationMissionIndex(item);
  if (missionIndex != null &&
      missionIndex >= 0 &&
      missionIndex < missions.length) {
    return missionIndex;
  }
  return null;
}

String? _payloadString(Map<String, Object?>? payload, String key) {
  final Object? value = payload?[key];
  final String? stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}
