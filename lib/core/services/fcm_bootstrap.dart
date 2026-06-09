import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../app/router/app_router.dart';
import '../../features/notifications/presentation/models/notification_target_route.dart';
import '../auth/auth_session.dart';
import 'device_registration.dart';
import 'fcm_messaging_service.dart';

abstract final class FcmBootstrap {
  static StreamSubscription<FcmMessage>? _foregroundSub;
  static StreamSubscription<FcmMessage>? _openedAppSub;
  static StreamSubscription<String>? _tokenRefreshSub;

  static Future<void> initialize({
    FcmMessagingService? messagingService,
  }) async {
    final FcmMessagingService messaging =
        messagingService ?? createFcmMessagingService();

    final bool granted = await messaging.requestPermission();
    if (!granted) {
      debugPrint('[fcm] permission denied — skipping bootstrap.');
      return;
    }

    if (await AuthSession.isLoggedIn()) {
      await DeviceRegistration.registerCurrent(messagingService: messaging);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((String _) async {
      if (await AuthSession.isLoggedIn()) {
        await DeviceRegistration.registerCurrent(messagingService: messaging);
      }
    });

    await _foregroundSub?.cancel();
    _foregroundSub = messaging.onForegroundMessage.listen((FcmMessage message) {
      debugPrint(
        '[fcm] foreground: type=${message.type} deeplink=${message.deeplink}',
      );
    });

    await _openedAppSub?.cancel();
    _openedAppSub = messaging.onMessageOpenedApp.listen((FcmMessage message) {
      unawaited(_navigate(message));
    });

    final FcmMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_navigate(initialMessage));
      });
    }
  }

  static Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedAppSub = null;
    _tokenRefreshSub = null;
  }

  static Future<void> _navigate(FcmMessage message) async {
    final String? parentId = await AuthSession.getCurrentParentId();
    final String route = normalizeParentNotificationRoute(
      message.deeplink,
      parentId: parentId,
      childrenId: message.childRef,
    );
    if (!route.startsWith('/')) {
      return;
    }

    try {
      appRouter.go(route);
    } catch (e) {
      debugPrint('[fcm] navigate failed for "$route": $e');
    }
  }
}
