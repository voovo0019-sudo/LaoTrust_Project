// =============================================================================
// LT-10 [Auth] 인증 서비스 v2.0 - GoRouter 기반
// lib/services/auth_service.dart
// =============================================================================

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/firebase_service.dart';

/// 라오스 국가 코드
const String kLaosCountryCode = '+856';

/// 라오스 전화번호 E.164 정규화
String normalizeLaosPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('856')) return '+$digits';
  if (digits.length >= 8) return kLaosCountryCode + digits;
  return kLaosCountryCode + digits;
}

String? _lastVerificationId;

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

/// SMS 인증 코드 발송
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
