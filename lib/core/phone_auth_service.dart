// =============================================================================
// [PHONE AUTH 격리 - 2026.05.12]
// 사유: Flutter Web reCAPTCHA Enterprise 미해결 버그
// 대체: Google 로그인 (google_auth_service.dart)
// 부활: Native 앱 출시 시 주석 해제하여 사용
// 이 파일은 auth_service.dart와 100% 중복이며 미사용 상태였음
// =============================================================================
/*
// =============================================================================
// LT-10 [Auth] 라오스 전화번호 인증 (Phone Auth) 서비스 모듈
// Laos country code +856. 라오트러스트 v1.5 / LT-04 신뢰성. 외부 의존 없음.
// =============================================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

/// 라오스 국가 코드 / Laos country code
const String kLaosCountryCode = '+856';

/// 라오스 전화번호를 E.164 형식으로 정규화
String normalizeLaosPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('856')) return '+$digits';
  if (digits.length >= 8) return kLaosCountryCode + digits;
  return kLaosCountryCode + digits;
}

/// SMS 인증 코드 전송 (라오스 번호 기준)
Future<void> sendPhoneVerificationCodeLaos(String phoneNumber) async {
  if (!isFirebaseEnabled) throw StateError('Firebase not connected');
  final normalized = normalizeLaosPhone(phoneNumber);
  await auth.verifyPhoneNumber(
    phoneNumber: normalized,
    verificationCompleted: (PhoneAuthCredential credential) async {
      await auth.signInWithCredential(credential);
    },
    verificationFailed: (FirebaseAuthException e) {
      throw e;
    },
    codeSent: (String verificationId, int? resendToken) {
      _lastVerificationId = verificationId;
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      _lastVerificationId = verificationId;
    },
  );
}

String? _lastVerificationId;

/// 수신한 SMS 코드로 로그인
Future<UserCredential> signInWithPhoneCodeLaos(String smsCode) async {
  if (!isFirebaseEnabled || _lastVerificationId == null) {
    throw StateError('Firebase not connected or no verification sent');
  }
  final credential = PhoneAuthProvider.credential(
    verificationId: _lastVerificationId!,
    smsCode: smsCode,
  );
  return auth.signInWithCredential(credential);
}
*/
// =============================================================================
// [PHONE AUTH 격리 끝]
// =============================================================================
