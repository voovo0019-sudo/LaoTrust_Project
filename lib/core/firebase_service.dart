// LT-08 미션02: Firebase(Firestore + 전화번호 인증) 개통.
// 지사 인계용: Firestore 오프라인 지속 저장 활성화, Auth 전화번호 로그인 진입점 제공.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Firebase 초기화 여부. main()에서 초기화 실패 시 false.
bool get isFirebaseEnabled => _firebaseEnabled;
bool _firebaseEnabled = false;

void setFirebaseEnabled(bool value) {
  _firebaseEnabled = value;
}

/// Firestore 인스턴스. 오프라인 persistence는 [main] 또는 최초 사용 전에 설정.
FirebaseFirestore get firestore => FirebaseFirestore.instance;

/// Auth 인스턴스 (전화번호 인증 등).
FirebaseAuth get auth => FirebaseAuth.instance;

/// 화이트리스트 로그인 시 Firebase signIn 없이 표시용 전화번호만 저장. 배너/프로필에서 last4 노출용.
final ValueNotifier<String?> whitelistDisplayPhoneNotifier = ValueNotifier<String?>(null);

/// Firebase Auth 세션 **또는** 화이트리스트 표시 로그인(위 notifier에 번호가 있음)이면 true.
/// 환영 배너(0019 엔진)와 급구 알바 등록 가드의 기준을 통일한다.
bool get hasRecognizedUserSession {
  final user = auth.currentUser;
  if (user != null && !user.isAnonymous) return true;
  final v = whitelistDisplayPhoneNotifier.value?.trim();
  return v != null && v.isNotEmpty;
}

/// `jobs.employerId` 저장·소유권 비교용: Auth UID 우선, 없으면 `whitelist_` + 숫자만(안정 키).
String? employerIdForCurrentSession() {
  final uid = auth.currentUser?.uid;
  if (uid != null && uid.isNotEmpty) return uid;
  final raw = whitelistDisplayPhoneNotifier.value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return 'whitelist_$digits';
}

/// Firestore 오프라인 우선: 기기에 먼저 캐시하고 연결 시 서버와 동기화.
/// 앱 시작 시 한 번 호출. (미션02: 인터넷 불안정 지역 대비)
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

// -----------------------------------------------------------------------------
// v10.1 과제 C: 포그라운드 복귀 시 토큰 갱신 → Auth 스트림·세션 인지와 동기화
// (AuthService와 순환 import 방지를 위해 core에 둠. 전화 인증 API는 auth_service.)
// -----------------------------------------------------------------------------

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
  } catch (_) {
    // 네트워크·토큰 오류는 이후 authStateChanges / UI 가드가 처리
  }
}

/// 앱 생명주기당 1회 등록. [enableFirestoreOfflinePersistence] 성공 시 호출.
void registerAuthForegroundGuard() {
  if (_authForegroundGuardRegistered || !_firebaseEnabled) return;
  _authForegroundGuardRegistered = true;
  WidgetsBinding.instance.addObserver(_AuthForegroundGuard());
}

/// 전화번호 인증: 번호로 인증 코드 발송 후, 코드 입력으로 로그인.
/// (실제 사용 시 reCAPTCHA 등 플랫폼별 설정 필요.)
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
      // 호출 측에서 verificationId 저장 후, code 입력 시 signInWithCredential 사용
      _lastVerificationId = verificationId;
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      _lastVerificationId = verificationId;
    },
  );
}

String? _lastVerificationId;

/// 발송된 인증 코드로 로그인.
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
