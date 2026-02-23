import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/firebase_service.dart';
import 'core/offline_first_sync.dart';
import 'core/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // LT-08 미션02: Firebase 연동. 실패 시 앱은 Firebase 없이 동작.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    setFirebaseEnabled(true);
    await enableFirestoreOfflinePersistence();
  } catch (_) {
    setFirebaseEnabled(false);
  }

  // 오프라인 우선: 연결 복구 시 대기 요청 자동 전송
  await flushPendingRequestsWhenOnline();

  // LT-08 미션05: 푸시 알림(긴급 출동) 초기화 — 토픽 구독
  await initPushNotificationService();

  runApp(const LaoTrustApp());
}
