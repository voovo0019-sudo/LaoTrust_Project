// LT-08 미션02: Firebase(Firestore + 전화번호 인증) 개통.
// 지사 인계용: Firestore 오프라인 지속 저장 활성화, Auth 전화번호 로그인 진입점 제공.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Firestore 오프라인 우선: 기기에 먼저 캐시하고 연결 시 서버와 동기화.
/// 앱 시작 시 한 번 호출. (미션02: 인터넷 불안정 지역 대비)
Future<void> enableFirestoreOfflinePersistence() async {
  if (!_firebaseEnabled) return;
  // Firestore는 모바일에서 기본적으로 persistence 활성화됨. 설정 명시.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}

/// 전화번호 인증: 번호로 인증 코드 발송 후, 코드 입력으로 로그인.
/// (실제 사용 시 reCAPTCHA 등 플랫폼별 설정 필요.)
Future<void> sendPhoneCode(String phoneNumber) async {
  if (!_firebaseEnabled) throw StateError('Firebase 미연동 상태');
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
    throw StateError('Firebase 미연동이거나 인증 코드가 발송되지 않음');
  }
  final credential = PhoneAuthProvider.credential(
    verificationId: _lastVerificationId!,
    smsCode: smsCode,
  );
  return auth.signInWithCredential(credential);
}
