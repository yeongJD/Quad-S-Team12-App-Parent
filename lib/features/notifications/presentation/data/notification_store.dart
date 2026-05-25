import '../../../../core/auth/account_store.dart';
import '../../../../core/date/week_label.dart';
import '../models/notification_item.dart';

abstract final class NotificationStore {
  static List<NotificationItem> get defaultNotifications {
    final String weekLabel = currentMonthWeekLabel();
    return <NotificationItem>[
      NotificationItem(
        id: 'weekly-usage-report',
        type: NotificationType.weeklyUsageReport,
        title: '$weekLabel 사용 리포트',
        message: '$weekLabel 사용 분석이 담긴 리포트가 도착했어요!\n리포트를 바탕으로, 더 나은 계획을 세워봐요.',
        timeAgo: '15분 전',
        payload: <String, Object?>{'childCode': 'GDG12-1'},
      ),
      const NotificationItem(
        id: 'mission-completed',
        type: NotificationType.missionCompleted,
        title: '미션완료',
        message: '자녀가 숙제하기 미션을 완료했어요.\n보너스 시간 15분 획득!',
        timeAgo: '15분 전',
        payload: <String, Object?>{'childCode': 'GDG12-1', 'missionIndex': 0},
      ),
      const NotificationItem(
        id: 'mission-confirmation-requested',
        type: NotificationType.missionConfirmationRequested,
        title: '미션 확인 요청',
        message: '자녀가 숙제하기 미션 완료 확인을 요청했어요.',
        timeAgo: '15분 전',
        payload: <String, Object?>{'childCode': 'GDG12-1', 'missionIndex': 1},
      ),
      const NotificationItem(
        id: 'time-configured',
        type: NotificationType.timeConfigured,
        title: '시간설정 완료',
        message: '자녀가 1월달 사용 시간 설정을 완료했어요!',
        timeAgo: '15분 전',
        payload: <String, Object?>{'childCode': 'GDG12-1'},
      ),
    ];
  }

  static Future<List<NotificationItem>> load(String? parentId) async {
    if (parentId == null || parentId.isEmpty) {
      return defaultNotifications;
    }

    final ParentAccount? account = await AccountStore.getAccountById(parentId);
    if (account == null) {
      return defaultNotifications;
    }

    final Set<String> hiddenIds = account.hiddenNotificationIds.toSet();
    final Set<String> readIds = account.readNotificationIds.toSet();
    return defaultNotifications
        .where((NotificationItem item) => !hiddenIds.contains(item.id))
        .map(
          (NotificationItem item) =>
              item.copyWith(isRead: readIds.contains(item.id)),
        )
        .toList(growable: false);
  }

  static Future<bool> hasUnread(String? parentId) async {
    return (await load(parentId)).any((NotificationItem item) => !item.isRead);
  }

  static Future<void> markRead({
    required String parentId,
    required String notificationId,
  }) async {
    if (parentId.isEmpty || notificationId.isEmpty) {
      return;
    }

    await AccountStore.updateNotifications(
      parentId: parentId,
      update: (ParentAccount account) {
        final Set<String> readIds = account.readNotificationIds.toSet()
          ..add(notificationId);
        return account.copyWith(
          readNotificationIds: readIds.toList(growable: false),
        );
      },
    );
  }

  static Future<void> hide({
    required String parentId,
    required String notificationId,
  }) async {
    if (parentId.isEmpty || notificationId.isEmpty) {
      return;
    }

    await AccountStore.updateNotifications(
      parentId: parentId,
      update: (ParentAccount account) {
        final Set<String> hiddenIds = account.hiddenNotificationIds.toSet()
          ..add(notificationId);
        return account.copyWith(
          hiddenNotificationIds: hiddenIds.toList(growable: false),
        );
      },
    );
  }
}
