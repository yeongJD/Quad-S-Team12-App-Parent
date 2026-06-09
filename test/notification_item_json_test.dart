import 'package:bridge_p/features/notifications/presentation/models/notification_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationItem.fromJson backend payload', () {
    test('keeps routing ids from top-level backend fields', () {
      final NotificationItem? item =
          NotificationItem.fromJson(<String, Object?>{
            'notificationId': 17,
            'notificationType': 'MISSION_REQUESTED',
            'title': '미션 확인 요청',
            'content': '자녀가 미션 확인을 요청했습니다.',
            'createdAt': '2026-06-09T12:30:00',
            'isRead': false,
            'childId': 4,
            'missionId': 21,
            'performanceId': 33,
            'targetRoute': '/today-mission?childrenId=4',
          });

      expect(item, isNotNull);
      expect(item!.id, '17');
      expect(item.type, NotificationType.missionConfirmationRequested);
      expect(item.payload?['childId'], 4);
      expect(item.payload?['missionId'], 21);
      expect(item.payload?['performanceId'], 33);
      expect(item.payload?['targetRoute'], '/today-mission?childrenId=4');
    });

    test('merges nested payload with backend top-level route fields', () {
      final NotificationItem? item = NotificationItem.fromJson(
        <String, Object?>{
          'notificationId': 'time-1',
          'notificationType': 'GENERAL',
          'title': '시간 설정 완료',
          'content': '부모님이 이번 달 시간을 설정했습니다.',
          'createdAt': '2026-06-09T12:30:00',
          'payload': <String, dynamic>{'childCode': 'GDG12-1'},
          'childrenId': '5',
          'deeplink': '/today-time?childrenId=5',
        },
      );

      expect(item, isNotNull);
      expect(item!.type, NotificationType.timeConfigured);
      expect(item.payload?['childCode'], 'GDG12-1');
      expect(item.payload?['childrenId'], '5');
      expect(item.payload?['deeplink'], '/today-time?childrenId=5');
    });
  });
}
