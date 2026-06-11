import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/environment.dart';
import 'core/services/fcm_bootstrap.dart';

/// Background message handler. Must be a top-level function annotated with
/// `@pragma('vm:entry-point')` because FCM spawns a separate isolate for
/// background delivery — class methods and closures are not reachable.
///
/// Kept minimal: the OS auto-renders the [RemoteMessage.notification]
/// payload to the tray, and `FcmBootstrap` applies the deeplink when the
/// user taps it.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[fcm:bg] type=${message.data['type']} '
    'deeplink=${message.data['deeplink'] ?? message.data['targetRoute']}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BridgePApp());

  // Push setup must not block the first frame. In real API mode the app still
  // needs Firebase/FCM, but simulator/APNs/plugin issues should degrade to
  // "no push" instead of leaving the user on a white launch screen.
  if (!currentEnvironment.useMocks) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializePush());
    });
  }
}

Future<void> _initializePush() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (e, stack) {
    debugPrint('[firebase] init failed — continuing without push: $e');
    debugPrintStack(stackTrace: stack);
    return;
  }

  try {
    await FcmBootstrap.initialize();
  } catch (e, stack) {
    debugPrint('[fcm] bootstrap failed — continuing without push: $e');
    debugPrintStack(stackTrace: stack);
  }
}
