import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/environment.dart';

/// Background message handler. Must be a top-level function annotated with
/// `@pragma('vm:entry-point')` because FCM spawns a separate isolate for
/// background delivery — class methods and closures are not reachable.
///
/// Kept minimal: the OS auto-renders the [RemoteMessage.notification]
/// payload to the tray, and the deeplink is applied on tap (foreground +
/// tap handler wiring is a follow-up ticket — DeviceRepository registration
/// is what `feature/api-prep` covers).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[fcm:bg] type=${message.data['type']} '
    'notificationId=${message.data['notificationId']}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase wiring is skipped in the mock environment so the dev simulator
  // boots without GoogleService-Info.plist embedded into the Xcode build,
  // and without the Android emulator's Google Play Services dependency
  // crashing the background-handler registration.
  if (!currentEnvironment.useMocks) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    } catch (e, stack) {
      // Don't crash the app if Firebase init fails (e.g. simulator without
      // APNs entitlements); DeviceRegistration paths will then no-op too
      // (`requestPermission` returns false on the mock service).
      debugPrint('[firebase] init failed — continuing without push: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  runApp(const BridgePApp());
}
