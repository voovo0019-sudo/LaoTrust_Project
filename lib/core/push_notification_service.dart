// =============================================================================
// LT-08 Mission05: real-time push notification skeleton (handover notes)
// =============================================================================
// - Initialize FCM, obtain token, subscribe to topics.
// - Provide message receiving structure for foreground/background/terminated states.
// - Actual sending should be done by backend (e.g., Cloud Functions) to a region topic.
// =============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Background message handler (top-level for terminated state).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[LT-08 Push] Background message: ${message.messageId}');
  }
}

/// Emergency dispatch FCM topic. Consider splitting by region/category in production.
const String kTopicEmergencyDispatch = 'emergency_dispatch';

/// Initialize FCM and topic subscription. Call once at app start.
Future<void> initPushNotificationService() async {
  if (!isFirebaseEnabled) return;

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Show notification while in foreground (optional)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  //final token = await FirebaseMessaging.instance.getToken();
  //if (kDebugMode && token != null) {
  //  print('[LT-08 Push] FCM token (partial): ${token.substring(0, 20)}...');
  //}

 // await FirebaseMessaging.instance.subscribeToTopic(kTopicEmergencyDispatch);
}

/// Foreground message callback registration.
void setForegroundMessageHandler(void Function(RemoteMessage message) handler) {
  FirebaseMessaging.onMessage.listen(handler);
}

/// Callback when app is opened by tapping a notification.
void setMessageOpenedAppHandler(void Function(RemoteMessage message) handler) {
  FirebaseMessaging.onMessageOpenedApp.listen(handler);
}

/// Initial message when app was launched from terminated state.
Future<RemoteMessage?> getInitialPushMessage() async {
  return FirebaseMessaging.instance.getInitialMessage();
}
