// =============================================================================
// LT-10 [Auth] 라오스 현지 전화번호 기반 인증(Phone Auth) 로직
// lib/services/auth_service.dart — Laos +856, 디지털 캡슐 v1.5. 한/영 주석 병기.
// v7.9: 모바일 Auth 스냅샷 확정(finalize) — currentUser 레이스 완화.
// v10.1: 앱 포그라운드 복귀 시 토큰 갱신·세션 동기화는 순환 import 방지를 위해
//        [registerAuthForegroundGuard]가 core/firebase_service.dart에 있으며,
//        [enableFirestoreOfflinePersistence] 성공 시 1회 등록된다.
// 작전 A: 로그인 성공 후 [pushNamed]로 원래 목적 화면 복귀.
// =============================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

// ---------------------------------------------------------------------------
// Post-login redirect (작전 A) — 보호된 화면 진입 전 [setPostLoginRedirect] 호출.
// ---------------------------------------------------------------------------

/// [MaterialApp]에 등록된 이름으로 라우팅한다. [arguments]는 [Navigator.pushNamed]와 동일.
class PostLoginRedirect {
  const PostLoginRedirect(this.routeName, {this.arguments});
  final String routeName;
  final Object? arguments;
}

PostLoginRedirect? _pendingPostLoginRedirect;

/// 인증을 요청하기 **직전**에 호출: 로그인·화이트리스트 성공 후 해당 경로로 이동.
void setPostLoginRedirect(String routeName, [Object? arguments]) {
  _pendingPostLoginRedirect = PostLoginRedirect(routeName, arguments: arguments);
}

void clearPostLoginRedirect() {
  _pendingPostLoginRedirect = null;
}

/// 일회성 소비(로그인 성공 처리 시). 없으면 null.
PostLoginRedirect? takePostLoginRedirect() {
  final r = _pendingPostLoginRedirect;
  _pendingPostLoginRedirect = null;
  return r;
}

/// 전화/화이트리스트 인증 성공 직후: 시트 닫기 → (옵션) 루트까지 pop → [pushNamed] 리다이렉트.
void schedulePostLoginNavigationAfterAuth({
  required BuildContext sheetContext,
  required VoidCallback closeSheet,
  required bool popToAppRoot,
}) {
  final navigator = Navigator.of(sheetContext, rootNavigator: true);
  final redirect = takePostLoginRedirect();
  closeSheet();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (popToAppRoot) {
      navigator.popUntil((route) => route.isFirst);
    }
    if (redirect != null) {
      navigator.pushNamed(redirect.routeName, arguments: redirect.arguments);
    }
  });
}

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
