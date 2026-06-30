// =============================================================================
// LT-08 Mission05: real-time push notification skeleton (handover notes)
// =============================================================================
// - Initialize FCM, obtain token, subscribe to topics.
// - Provide message receiving structure for foreground/background/terminated states.
// - Actual sending should be done by backend (e.g., Cloud Functions) to a region topic.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'locale_service.dart';

/// Background message handler (top-level for terminated state).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[LT-08 Push] Background message: ${message.messageId}');
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

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    if (kDebugMode) {
      debugPrint('[LT-08 Push] FCM token (partial): ${token.substring(0, 20)}...');
    }
    await _saveFcmTokenToFirestore(token);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    _saveFcmTokenToFirestore(newToken);
  });
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

/// Save the current device's FCM token to the logged-in user's Firestore document.
/// Called on app start and whenever the token refreshes.
Future<void> _saveFcmTokenToFirestore(String token) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (kDebugMode) {
      debugPrint('[LT-08 Push] No logged-in user yet, skip token save.');
    }
    return;
  }
  try {
    final savedLocale = await getSavedLocale();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'preferredLang': savedLocale.languageCode,
      },
      SetOptions(merge: true),
    );
    if (kDebugMode) {
      debugPrint('[LT-08 Push] FCM token saved for uid=${user.uid}, lang=${savedLocale.languageCode}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[LT-08 Push] Failed to save FCM token: $e');
    }
  }
}

/// Public wrapper to refresh and save the FCM token right after a successful login.
/// Call this immediately after sign-in completes, since the token save during
/// app startup may have been skipped while the user was not yet authenticated.
Future<void> saveFcmTokenAfterLogin() async {
  if (!isFirebaseEnabled) return;
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await _saveFcmTokenToFirestore(token);
  }
}
