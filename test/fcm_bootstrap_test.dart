import 'dart:async';

import 'package:bridge_p/core/auth/auth_session.dart';
import 'package:bridge_p/core/services/fcm_bootstrap.dart';
import 'package:bridge_p/core/services/fcm_messaging_service.dart';
import 'package:bridge_p/data/repositories/mock_device_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await FcmBootstrap.dispose();
  });

  tearDown(() async {
    await FcmBootstrap.dispose();
  });

  testWidgets('opened FCM message normalizes parent route context', (
    WidgetTester tester,
  ) async {
    await AuthSession.login(parentId: 'parent-1', email: 'p@test.local');
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    addTearDown(messaging.dispose);
    final GoRouter router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const MockDeviceRepository(),
      router: router,
    );

    messaging.openedMessages.add(
      const FcmMessage(
        type: 'GENERAL',
        deeplink: '/today-time',
        childrenId: '22',
      ),
    );
    await _pumpFcmRoute(tester);

    final Uri uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/today-time');
    expect(uri.queryParameters['parentId'], 'parent-1');
    expect(uri.queryParameters['childrenId'], '22');
  });

  testWidgets('opened FCM time route keeps backend children query', (
    WidgetTester tester,
  ) async {
    await AuthSession.login(parentId: 'parent-1', email: 'p@test.local');
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    addTearDown(messaging.dispose);
    final GoRouter router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const MockDeviceRepository(),
      router: router,
    );

    messaging.openedMessages.add(
      const FcmMessage(type: 'GENERAL', deeplink: '/today-time?childrenId=22'),
    );
    await _pumpFcmRoute(tester);

    final Uri uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/today-time');
    expect(uri.queryParameters['parentId'], 'parent-1');
    expect(uri.queryParameters['childrenId'], '22');
  });

  testWidgets('initial FCM mission message keeps review target ids', (
    WidgetTester tester,
  ) async {
    await AuthSession.login(parentId: 'parent-1', email: 'p@test.local');
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService(
      initialMessage: const FcmMessage(
        type: 'MISSION_REQUESTED',
        deeplink: '/today-mission',
        childrenId: '22',
        missionId: '100',
        performanceId: '200',
      ),
    );
    addTearDown(messaging.dispose);
    final GoRouter router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const MockDeviceRepository(),
      router: router,
    );
    await _pumpFcmRoute(tester);

    final Uri uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/today-mission');
    expect(uri.queryParameters['parentId'], 'parent-1');
    expect(uri.queryParameters['childrenId'], '22');
    expect(uri.queryParameters['missionId'], '100');
    expect(uri.queryParameters['performanceId'], '200');
    expect(uri.queryParameters['tab'], 'review');
  });

  testWidgets('opened FCM backend mission route keeps review target ids', (
    WidgetTester tester,
  ) async {
    await AuthSession.login(parentId: 'parent-1', email: 'p@test.local');
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    addTearDown(messaging.dispose);
    final GoRouter router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const MockDeviceRepository(),
      router: router,
    );

    messaging.openedMessages.add(
      const FcmMessage(
        type: 'MISSION_REQUESTED',
        deeplink: '/today-mission?childrenId=22',
        missionId: '100',
        performanceId: '200',
      ),
    );
    await _pumpFcmRoute(tester);

    final Uri uri = router.routeInformationProvider.value.uri;
    expect(uri.path, '/today-mission');
    expect(uri.queryParameters['parentId'], 'parent-1');
    expect(uri.queryParameters['childrenId'], '22');
    expect(uri.queryParameters['missionId'], '100');
    expect(uri.queryParameters['performanceId'], '200');
    expect(uri.queryParameters['tab'], 'review');
  });

  testWidgets('FCM navigation ignores non-router paths', (
    WidgetTester tester,
  ) async {
    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    addTearDown(messaging.dispose);
    final GoRouter router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const MockDeviceRepository(),
      router: router,
    );

    messaging.openedMessages.add(
      const FcmMessage(type: 'GENERAL', deeplink: 'https://example.com'),
    );
    await _pumpFcmRoute(tester);

    expect(router.routeInformationProvider.value.uri.path, '/');
  });
}

GoRouter _testRouter() {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(path: '/today-time', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/today-mission',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
}

Future<void> _pumpFcmRoute(WidgetTester tester) async {
  await tester.pump();
}

class _FakeFcmMessagingService implements FcmMessagingService {
  _FakeFcmMessagingService({this.initialMessage});

  final FcmMessage? initialMessage;
  final StreamController<FcmMessage> openedMessages =
      StreamController<FcmMessage>.broadcast();

  @override
  Future<void> deleteToken() async {}

  Future<void> dispose() => openedMessages.close();

  @override
  Future<FcmMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Stream<FcmMessage> get onForegroundMessage =>
      const Stream<FcmMessage>.empty();

  @override
  Stream<FcmMessage> get onMessageOpenedApp => openedMessages.stream;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<bool> requestPermission() async => true;
}
