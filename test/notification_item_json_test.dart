import 'package:bridge_p/features/notifications/presentation/models/notification_item.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_target_route.dart';
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

  group('parent notification target route', () {
    test('adds current parent id to backend mission deeplink', () {
      final NotificationItem item = NotificationItem(
        id: 'route-1',
        type: NotificationType.missionConfirmationRequested,
        title: '미션 확인 요청',
        message: '자녀가 미션 확인을 요청했습니다.',
        timeAgo: '방금 전',
        payload: <String, Object?>{
          'childId': 4,
          'targetRoute': '/today-mission?childrenId=4',
        },
      );

      final Uri normalized = Uri.parse(
        parentNotificationTargetRoute(item, parentId: 'parent-1')!,
      );

      expect(normalized.path, '/today-mission');
      expect(normalized.queryParameters['childrenId'], '4');
      expect(normalized.queryParameters['parentId'], 'parent-1');
    });

    test('keeps existing parent id and fills missing children id', () {
      final NotificationItem item = NotificationItem(
        id: 'route-2',
        type: NotificationType.timeConfigured,
        title: '시간 설정 완료',
        message: '자녀가 시간 계획을 제출했습니다.',
        timeAgo: '방금 전',
        payload: <String, Object?>{
          'childrenId': '5',
          'deeplink': '/today-time?parentId=parent-existing',
        },
      );

      final Uri normalized = Uri.parse(
        parentNotificationTargetRoute(item, parentId: 'parent-ignored')!,
      );

      expect(normalized.path, '/today-time');
      expect(normalized.queryParameters['parentId'], 'parent-existing');
      expect(normalized.queryParameters['childrenId'], '5');
    });

    test('does not rewrite routes that do not need parent context', () {
      final NotificationItem item = NotificationItem(
        id: 'route-3',
        type: NotificationType.timeConfigured,
        title: '알림',
        message: '확인해주세요.',
        timeAgo: '방금 전',
        payload: <String, Object?>{'targetRoute': '/notifications?tab=all'},
      );

      expect(
        parentNotificationTargetRoute(item, parentId: 'parent-1'),
        '/notifications?tab=all',
      );
    });
  });
}
