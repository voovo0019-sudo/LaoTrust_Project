// =============================================================================
// LT-15 [Auth] Google 로그인 (Firebase signInWithPopup 방식)
// lib/services/google_auth_service.dart
//
// 재작성: 2026.05.13
// 이전 방식 (google_sign_in 패키지 + signIn()): Web에서 deprecated
//   → idToken 안정적으로 못 받아 Firebase 로그인 실패
// 새 방식 (Firebase Auth signInWithPopup):
//   → Firebase 공식 권장 (Web)
//   → idToken 자동 처리
//   → Native는 signInWithProvider로 분기
// =============================================================================

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/firebase_service.dart';

// ---------------------------------------------------------------------------
// 로그인 함수
// ---------------------------------------------------------------------------

/// Google 로그인
///
/// 흐름:
///   Web: signInWithPopup → Firebase가 OAuth 흐름 자체 처리
///   Native: signInWithProvider → 동일 API로 처리
///
/// 반환:
///   - UserCredential: 성공 시 Firebase 사용자 정보
///   - null: 사용자가 팝업 닫음
///
/// 에러:
///   - StateError: Firebase 비활성화 시
///   - FirebaseAuthException: 인증 에러
Future<UserCredential?> signInWithGoogle() async {
  if (!isFirebaseEnabled) {
    throw StateError('Firebase is not enabled');
  }

  try {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    if (kIsWeb) {
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      return await FirebaseAuth.instance.signInWithProvider(googleProvider);
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'popup-closed-by-user' ||
        e.code == 'cancelled-popup-request' ||
        e.code == 'web-context-canceled') {
      return null;
    }
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// 로그아웃 함수
// ---------------------------------------------------------------------------

/// Google 로그아웃 (Firebase 세션 종료)
Future<void> signOutGoogle() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {
    // 이미 로그아웃 상태일 수 있음
  }
}

// ---------------------------------------------------------------------------
// 상태 확인
// ---------------------------------------------------------------------------

/// 현재 Google 계정으로 로그인되어 있는지 확인
///
/// Firebase Auth provider 정보 기반 판단
bool get isGoogleSignedIn {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  return user.providerData.any((info) => info.providerId == 'google.com');
}
