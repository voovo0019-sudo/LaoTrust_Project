import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase_service.dart';
import 'core/offline_first_sync.dart';
import 'core/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // LT-08 미션02: Firebase 연동. 실패 시 앱은 Firebase 없이 동작.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    setFirebaseEnabled(true);
    await enableFirestoreOfflinePersistence();
  } catch (e, st) {
    debugPrint('FIREBASE_INIT_ERROR: $e');
    debugPrint('FIREBASE_INIT_STACK: $st');
    setFirebaseEnabled(false);
  }

  // 오프라인 우선: 연결 복구 시 대기 요청 자동 전송
  await flushPendingRequestsWhenOnline();

  // LT-08 단계05: 푸시 알림(백그라운드) 서비스 초기화
  // 부가 기능이므로 실패해도 앱 실행을 막지 않는다 (웹 서비스워커 미등록 등 대비)
  try {
    await initPushNotificationService();
  } catch (e, st) {
    debugPrint('PUSH_INIT_ERROR: $e');
    debugPrint('PUSH_INIT_STACK: $st');
  }

  runApp(const ProviderScope(child: LaoTrustApp()));
}
