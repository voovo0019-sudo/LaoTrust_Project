// LT-08 태스크02: Firebase(Firestore + 인증 서비스) 초기화.
// 화이트리스트 완전 제거 - Firebase Phone Auth 단일화 완료

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Firebase 활성화 여부. main()에서 초기화 후 설정. 기본값 false.
bool get isFirebaseEnabled => _firebaseEnabled;
bool _firebaseEnabled = false;

void setFirebaseEnabled(bool value) {
  _firebaseEnabled = value;
}

/// Firestore 인스턴스. 오프라인 persistence는 [main] 초기화 후 별도 설정.
FirebaseFirestore get firestore => FirebaseFirestore.instance;

/// Auth 인스턴스 (전역 접근용).
FirebaseAuth get auth => FirebaseAuth.instance;

/// Firebase Phone Auth 기반 로그인 여부 확인
/// 정식 전화번호 로그인 유저만 true 반환 (익명 유저 제외)
bool get hasRecognizedUserSession {
  final user = auth.currentUser;
  return user != null && !user.isAnonymous;
}

/// jobs.employerId 저장용: Firebase Auth UID 반환
/// 미로그인 시 null 반환
String? employerIdForCurrentSession() {
  final uid = auth.currentUser?.uid;
  if (uid != null && uid.isNotEmpty) return uid;
  return null;
}

/// Firestore 오프라인 설정: 플랫폼별 퍼시스턴스 설정 후 Auth 포그라운드 감시 등록.
Future<void> enableFirestoreOfflinePersistence() async {
  if (!_firebaseEnabled) return;
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } else {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  registerAuthForegroundGuard();
}

bool _authForegroundGuardRegistered = false;

class _AuthForegroundGuard with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncAuthOnResume());
    }
  }
}

Future<void> _syncAuthOnResume() async {
  if (!_firebaseEnabled) return;
  final u = auth.currentUser;
  if (u == null) return;
  try {
    await u.getIdToken(true);
    await u.reload();
  } catch (_) {}
}

/// 앱 포그라운드 복귀 시 Auth 토큰 갱신. 1회만 등록.
void registerAuthForegroundGuard() {
  if (_authForegroundGuardRegistered || !_firebaseEnabled) return;
  _authForegroundGuardRegistered = true;
  WidgetsBinding.instance.addObserver(_AuthForegroundGuard());
}

/// 전화번호 인증 코드 발송
Future<void> sendPhoneCode(String phoneNumber) async {
  if (!_firebaseEnabled) throw StateError('Firebase is not enabled');
  await auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
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

/// SMS 코드로 로그인
Future<UserCredential> signInWithPhoneCode(String smsCode) async {
  if (!_firebaseEnabled || _lastVerificationId == null) {
    throw StateError('Firebase is not enabled or verification not started');
  }
  final credential = PhoneAuthProvider.credential(
    verificationId: _lastVerificationId!,
    smsCode: smsCode,
  );
  return auth.signInWithCredential(credential);
}
