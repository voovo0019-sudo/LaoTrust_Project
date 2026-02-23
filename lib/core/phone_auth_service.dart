// =============================================================================
// LT-10 [Auth] 라오스 현지 전화번호 기반 인증(Phone Auth) 로직 초안
// Laos country code +856. 디지털 캡슐 v1.5 / LT-04 일치. 한/영 주석 병기.
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

/// 라오스 국가 코드 / Laos country code
const String kLaosCountryCode = '+856';

/// 전화번호를 라오스 형식(+856...)으로 정규화. / Normalize to E.164 for Laos.
String normalizeLaosPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('856')) return '+$digits';
  if (digits.length >= 8) return kLaosCountryCode + digits;
  return kLaosCountryCode + digits;
}

/// 인증 코드 발송 (라오스 현지 번호). / Send verification code to Laos phone.
/// 호출 전 Firebase 초기화 및 Auth 설정 필요. reCAPTCHA 등 플랫폼별 설정은 실제 배포 시 추가.
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

/// 발송된 SMS 코드로 로그인. / Sign in with received SMS code.
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
