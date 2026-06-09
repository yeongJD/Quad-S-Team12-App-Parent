import 'package:bridge_p/core/services/fcm_messaging_service.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_item.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_mission_target.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_target_route.dart';
import 'package:bridge_p/features/today_mission/presentation/models/today_mission.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

    test('keeps mission target ids on normalized mission list route', () {
      final Uri normalized = Uri.parse(
        normalizeParentNotificationRoute(
          '/today-mission?childrenId=4',
          parentId: 'parent-1',
          childrenId: '4',
          missionId: '21',
          performanceId: '33',
        ),
      );

      expect(normalized.path, '/today-mission');
      expect(normalized.queryParameters['childrenId'], '4');
      expect(normalized.queryParameters['parentId'], 'parent-1');
      expect(normalized.queryParameters['missionId'], '21');
      expect(normalized.queryParameters['performanceId'], '33');
      expect(normalized.queryParameters['tab'], 'review');
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

  group('parent notification mission target', () {
    const List<TodayMission> missions = <TodayMission>[
      TodayMission(
        missionId: '10',
        performanceId: '100',
        title: '방 정리',
        category: MissionCategory.cleaning,
        resetPeriod: MissionResetPeriod.daily,
        confirmationMethod: MissionConfirmationMethod.parent,
        rewardMinutes: 10,
        description: '책상 정리',
      ),
      TodayMission(
        missionId: '21',
        performanceId: '200',
        title: '문제집',
        category: MissionCategory.study,
        resetPeriod: MissionResetPeriod.daily,
        confirmationMethod: MissionConfirmationMethod.parent,
        rewardMinutes: 20,
        description: '수학 문제집',
      ),
    ];

    test('uses mission id before the generic target route', () {
      final NotificationItem item = NotificationItem(
        id: 'mission-route-1',
        type: NotificationType.missionConfirmationRequested,
        title: '미션 확인 요청',
        message: '자녀가 미션 확인을 요청했습니다.',
        timeAgo: '방금 전',
        payload: <String, Object?>{
          'childId': 4,
          'missionId': '21',
          'targetRoute': '/today-mission?childrenId=4',
        },
      );

      expect(shouldOpenMissionDetailFromNotification(item), isTrue);
      expect(notificationMissionIndexForMissions(missions, item), 1);
    });

    test('falls back to performance id when mission id is absent', () {
      final NotificationItem item = NotificationItem(
        id: 'mission-route-2',
        type: NotificationType.missionConfirmationRequested,
        title: '미션 확인 요청',
        message: '자녀가 미션 확인을 요청했습니다.',
        timeAgo: '방금 전',
        payload: <String, Object?>{
          'childId': 4,
          'performanceId': 100,
          'targetRoute': '/today-mission?childrenId=4',
        },
      );

      expect(notificationMissionIndexForMissions(missions, item), 0);
    });

    test('accepts string mission index from FCM payloads', () {
      final NotificationItem item = NotificationItem(
        id: 'mission-route-3',
        type: NotificationType.missionConfirmationRequested,
        title: '미션 확인 요청',
        message: '자녀가 미션 확인을 요청했습니다.',
        timeAgo: '방금 전',
        payload: <String, Object?>{'missionIndex': '1'},
      );

      expect(notificationMissionIndexForMissions(missions, item), 1);
    });

    test('ignores non-mission notifications with mission-like payloads', () {
      final NotificationItem item = NotificationItem(
        id: 'mission-route-4',
        type: NotificationType.timeConfigured,
        title: '시간 설정 완료',
        message: '부모님이 이번 달 시간을 설정했습니다.',
        timeAgo: '방금 전',
        payload: <String, Object?>{'missionId': '21'},
      );

      expect(shouldOpenMissionDetailFromNotification(item), isFalse);
      expect(notificationMissionIndexForMissions(missions, item), 1);
    });
  });

  group('FcmMessage.fromRemoteMessage', () {
    test('uses backend targetRoute when deeplink is absent', () {
      final FcmMessage message = FcmMessage.fromRemoteMessage(
        const RemoteMessage(
          data: <String, dynamic>{
            'notificationType': 'MISSION_REQUESTED',
            'notificationId': 'n-1',
            'childId': '4',
            'missionId': '21',
            'performanceId': '33',
            'targetRoute': '/today-mission?childrenId=4',
          },
        ),
      );

      expect(message.type, 'MISSION_REQUESTED');
      expect(message.notificationId, 'n-1');
      expect(message.childRef, '4');
      expect(message.missionId, '21');
      expect(message.performanceId, '33');
      expect(message.deeplink, '/today-mission?childrenId=4');
    });

    test('derives mission review route when ids exist without target route', () {
      final FcmMessage message = FcmMessage.fromRemoteMessage(
        const RemoteMessage(
          data: <String, dynamic>{
            'notificationType': 'MISSION_REQUESTED',
            'notificationId': 'n-2',
            'childId': '4',
            'missionId': '21',
            'performanceId': '33',
          },
        ),
      );

      expect(message.type, 'MISSION_REQUESTED');
      expect(message.notificationId, 'n-2');
      expect(message.childRef, '4');
      expect(message.missionId, '21');
      expect(message.performanceId, '33');
      expect(message.deeplink, '/today-mission');
    });
  });
}
