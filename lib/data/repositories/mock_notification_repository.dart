import '../../core/models/result.dart';
import '../../features/notifications/presentation/data/notification_store.dart';
import '../../features/notifications/presentation/models/notification_item.dart';
import 'notification_repository.dart';

/// SharedPreferences-backed [NotificationRepository] that delegates to
/// [NotificationStore]. The store already keeps a static
/// `defaultNotifications` list plus per-parent hidden/read sets, so this
/// wrapper just promotes the existing methods to the [Result] contract.
class MockNotificationRepository implements NotificationRepository {
  @override
  Future<Result<List<NotificationItem>>> loadInbox(String parentId) async {
    final List<NotificationItem> items = await NotificationStore.load(
      parentId,
    );
    return Result<List<NotificationItem>>.success(items);
  }

  @override
  Future<Result<bool>> hasUnread(String parentId) async {
    final bool unread = await NotificationStore.hasUnread(parentId);
    return Result<bool>.success(unread);
  }

  @override
  Future<Result<void>> markRead({
    required String parentId,
    required String notificationId,
  }) async {
    await NotificationStore.markRead(
      parentId: parentId,
      notificationId: notificationId,
    );
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> hide({
    required String parentId,
    required String notificationId,
  }) async {
    await NotificationStore.hide(
      parentId: parentId,
      notificationId: notificationId,
    );
    return Result<void>.success(null);
  }
}
