// =============================================================================
// LT-08 미션05: 실시간 푸시(Push) 알림 — 긴급 출동 지령 시스템 코드 구조 (지사 인계용 전략 주석)
// =============================================================================
// 역할: 유저 요청 시 근처 전문가에게 0.1초 만에 알람이 가도록 하는 '긴급 출동' 인프라 뼈대.
// - FCM(Firebase Cloud Messaging) 초기화, 토큰 획득, 토픽 구독.
// - 포그라운드/백그라운드/종료 상태별 메시지 수신 처리 구조만 확보.
// 실제 발송: 백엔드(Cloud Functions / 서버)에서 요청 수신 시 해당 지역 토픽으로 메시지 전송.
// 지사 인계 시: 1) 지역/카테고리별 토픽 세분화 2) 페이로드에 requestId, 위치 등 포함 3) 알림 클릭 시 해당 요청 상세 화면으로 딥링크.
// =============================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// 백그라운드 메시지 핸들러. top-level 함수로 두어 종료 상태에서도 동작.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[LT-08 푸시] 백그라운드 수신: ${message.messageId}');
  }
}

/// 긴급 출동용 FCM 토픽. 실제 운영 시 지역/카테고리별로 세분화 (예: emergency_viangchan_ac).
const String kTopicEmergencyDispatch = 'emergency_dispatch';

/// FCM 초기화 및 토픽 구독. 앱 시작 시 한 번 호출.
/// 지사 인계: 전문가 로그인 후 자신의 지역·카테고리 토픽만 구독하도록 확장.
Future<void> initPushNotificationService() async {
  if (!isFirebaseEnabled) return;

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 포그라운드에서도 알림 표시 (선택)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  //final token = await FirebaseMessaging.instance.getToken();
  //if (kDebugMode && token != null) {
  //  print('[LT-08 푸시] FCM 토큰(일부): ${token.substring(0, 20)}...');
  //}

 // await FirebaseMessaging.instance.subscribeToTopic(kTopicEmergencyDispatch);
}

/// 포그라운드 메시지 수신 시 콜백. UI에서 등록해 사용.
void setForegroundMessageHandler(void Function(RemoteMessage message) handler) {
  FirebaseMessaging.onMessage.listen(handler);
}

/// 알림 탭으로 앱 열었을 때 콜백. 딥링크/요청 상세 화면 이동 등.
void setMessageOpenedAppHandler(void Function(RemoteMessage message) handler) {
  FirebaseMessaging.onMessageOpenedApp.listen(handler);
}

/// 앱이 종료된 상태에서 알림 탭으로 실행된 경우. getInitialMessage()로 처리.
Future<RemoteMessage?> getInitialPushMessage() async {
  return FirebaseMessaging.instance.getInitialMessage();
}
