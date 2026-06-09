import 'package:bridge_p/core/auth/auth_session.dart';
import 'package:bridge_p/core/models/result.dart';
import 'package:bridge_p/data/repositories/notification_repository.dart';
import 'package:bridge_p/features/notifications/presentation/models/notification_item.dart';
import 'package:bridge_p/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('mark-read failure keeps parent notification unread', (
    WidgetTester tester,
  ) async {
    const String parentId = 'parent-1';
    final _FailingMarkReadNotificationRepository repository =
        _FailingMarkReadNotificationRepository(
          items: const <NotificationItem>[
            NotificationItem(
              id: 'notification-1',
              type: NotificationType.weeklyUsageReport,
              title: '주간 리포트',
              message: '이번 주 사용 리포트를 확인해 주세요.',
              timeAgo: '방금 전',
              payload: <String, Object?>{'targetRoute': '/usage-report'},
            ),
          ],
        );
    await AuthSession.login(parentId: parentId, email: 'p@test.local');

    final GoRouter router = GoRouter(
      initialLocation: '/notifications',
      routes: <RouteBase>[
        GoRoute(
          path: '/notifications',
          builder: (context, state) =>
              NotificationsPage(notificationRepository: repository),
        ),
        GoRoute(
          path: '/usage-report',
          builder: (context, state) =>
              const Scaffold(body: Text('usage report')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인하러 가기 →'));
    await tester.pumpAndSettle();

    expect(repository.markReadCalled, isTrue);
    expect(find.text('읽음 처리 실패'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('이번 주 사용 리포트를 확인해 주세요.'), findsOneWidget);
    expect(find.text('지난알림 확인하기'), findsNothing);
  });
}

final class _FailingMarkReadNotificationRepository
    implements NotificationRepository {
  _FailingMarkReadNotificationRepository({required this.items});

  final List<NotificationItem> items;
  bool markReadCalled = false;

  @override
  Future<Result<List<NotificationItem>>> loadInbox(String parentId) async {
    return Result<List<NotificationItem>>.success(items);
  }

  @override
  Future<Result<bool>> hasUnread(String parentId) async {
    return Result<bool>.success(
      items.any((NotificationItem item) => !item.isRead),
    );
  }

  @override
  Future<Result<void>> markRead({
    required String parentId,
    required String notificationId,
  }) async {
    markReadCalled = true;
    return Result<void>.failure('읽음 처리 실패');
  }

  @override
  Future<Result<void>> hide({
    required String parentId,
    required String notificationId,
  }) async {
    return Result<void>.success(null);
  }
}
