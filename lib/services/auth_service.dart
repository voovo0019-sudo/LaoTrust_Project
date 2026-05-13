// =============================================================================
// LT-10 [Auth] 인증 서비스 v2.0 - GoRouter 기반
// lib/services/auth_service.dart
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/firebase_service.dart';

// =============================================================================
// [PHONE AUTH 격리 - 2026.05.12]
// 사유: Flutter Web reCAPTCHA Enterprise 미해결 버그
// 대체: Google 로그인 (google_auth_service.dart)
// 부활: Native 앱 출시 시 주석 해제하여 사용
// 주의: PostLoginRedirect 시스템은 유지! (Google 로그인에서도 재사용)
// =============================================================================
/*
/// 라오스 국가 코드
const String kLaosCountryCode = '+856';

/// 라오스 전화번호를 E.164 형식으로 정규화
String normalizeLaosPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('856')) return '+$digits';
  if (digits.length >= 8) return kLaosCountryCode + digits;
  return kLaosCountryCode + digits;
}

String? _lastVerificationId;
*/
// =============================================================================
// [PHONE AUTH 격리 끝 - 1차]
// =============================================================================

// ---------------------------------------------------------------------------
// PostLoginRedirect v2.0 - GoRouter 기반
// ---------------------------------------------------------------------------

/// 로그인 후 이동할 경로 (GoRouter location 기반)
class PostLoginRedirect {
  const PostLoginRedirect(this.location, {this.extra});
  final String location;
  final Object? extra;
}

PostLoginRedirect? _pendingPostLoginRedirect;

/// 로그인 후 이동할 경로 설정
void setPostLoginRedirect(String location, [Object? extra]) {
  _pendingPostLoginRedirect = PostLoginRedirect(location, extra: extra);
}

/// 로그인 리다이렉트 초기화
void clearPostLoginRedirect() {
  _pendingPostLoginRedirect = null;
}

/// 로그인 리다이렉트 가져오기 (한 번 읽으면 초기화)
PostLoginRedirect? takePostLoginRedirect() {
  final r = _pendingPostLoginRedirect;
  _pendingPostLoginRedirect = null;
  return r;
}

/// 로그인 완료 후 GoRouter 기반 화면 이동
void schedulePostLoginNavigationAfterAuth({
  required BuildContext sheetContext,
  required VoidCallback closeSheet,
  required bool popToAppRoot,
}) {
  final redirect = takePostLoginRedirect();
  closeSheet();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!sheetContext.mounted) return;
    final router = GoRouter.of(sheetContext);
    if (popToAppRoot) {
      router.go('/main');
    }
    if (redirect != null) {
      if (popToAppRoot) {
        router.push(redirect.location, extra: redirect.extra);
      } else {
        router.go(redirect.location, extra: redirect.extra);
      }
    }
  });
}

// =============================================================================
// [PHONE AUTH 격리 - 2026.05.12 - 2차]
// =============================================================================
/*
/// SMS 인증 코드 전송
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

/// SMS 코드로 로그인
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
// [PHONE AUTH 격리 끝 - 2차]
// 아래 PostLoginRedirect 시스템과 finalizeAppAuthState는 유지!
// =============================================================================

/// 프로필 시트 등 기존 호출부 컴파일 유지용. 실제 SMS 플로우는 격리됨.
Future<void> sendPhoneCode(String fullE164Number) async {
  throw StateError('Phone authentication is disabled; use Google sign-in.');
}

/// 프로필 시트 등 기존 호출부 컴파일 유지용.
Future<void> signInWithPhoneCode(String smsCode) async {
  throw StateError('Phone authentication is disabled; use Google sign-in.');
}

/// Firebase Auth 상태 안정화
Future<void> finalizeAppAuthState({
  Duration timeout = const Duration(milliseconds: 1200),
}) async {
  if (!isFirebaseEnabled) return;
  if (hasRecognizedUserSession) return;
  try {
    await auth.authStateChanges().first.timeout(timeout);
  } on TimeoutException {
    // 타임아웃 시 현재 상태 유지
  }
}
