import '../../core/config/environment.dart';
import '../../core/models/result.dart';
import '../../features/notifications/presentation/models/notification_item.dart';
import 'api_notification_repository.dart';
import 'mock_notification_repository.dart';

/// Repository contract for the parent-app notification inbox.
///
/// The inbox is server-driven (FCM fans out push events into the inbox),
/// but read/hide state is per-parent and lives in the same data store. The
/// repository exposes both fetch and mutation methods so pages don't need
/// to coordinate two clients.
abstract interface class NotificationRepository {
  Future<Result<List<NotificationItem>>> loadInbox(String parentId);

  Future<Result<bool>> hasUnread(String parentId);

  Future<Result<void>> markRead({
    required String parentId,
    required String notificationId,
  });

  Future<Result<void>> hide({
    required String parentId,
    required String notificationId,
  });
}

final NotificationRepository _notificationRepository =
    currentEnvironment.useMocks
        ? MockNotificationRepository()
        : ApiNotificationRepository();

NotificationRepository createNotificationRepository() =>
    _notificationRepository;
