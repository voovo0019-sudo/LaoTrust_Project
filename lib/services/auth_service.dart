// =============================================================================
// LT-10 [Auth] 라오스 현지 전화번호 기반 인증(Phone Auth) 로직
// lib/services/auth_service.dart — Laos +856, 디지털 캡슐 v1.5. 한/영 주석 병기.
// v7.9: 모바일 Auth 스냅샷 확정(finalize) — currentUser 레이스 완화.
// =============================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_service.dart';

/// 라오스 국가 코드 / Laos country code
const String kLaosCountryCode = '+856';

/// 전화번호를 라오스 형식(+856...)으로 정규화. / Normalize to E.164 for Laos.
String normalizeLaosPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('856')) return '+$digits';
  if (digits.length >= 8) return kLaosCountryCode + digits;
  return kLaosCountryCode + digits;
}

String? _lastVerificationId;

/// 인증 코드 발송 (라오스 현지 번호). / Send verification code to Laos phone.
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

/// Firebase Auth의 최초 스냅샷을 짧게 대기해 `currentUser` 반영 레이스를 줄인다.
/// 화이트리스트(notifier)만 있는 경우는 [hasRecognizedUserSession]이 이미 true이므로 즉시 반환.
Future<void> finalizeAppAuthState({
  Duration timeout = const Duration(milliseconds: 1200),
}) async {
  if (!isFirebaseEnabled) return;
  if (hasRecognizedUserSession) return;
  try {
    await auth.authStateChanges().first.timeout(timeout);
  } on TimeoutException {
    // 네트워크 지연 등 — 이후 동기 검사로 팝업 여부 결정
  }
}
