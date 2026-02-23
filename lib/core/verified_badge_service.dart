// =============================================================================
// LT-08 미션03: Verified 배지 상태 관리 (지사 인계용 전략 주석)
// =============================================================================
// 역할: 4.5 USD 인증비 결제 완료 시 파란색 'Verified' 배지를 활성화하는 로직.
// 저장: 로컬(SharedPreferences) + 추후 Firestore 사용자 문서와 연동 가능.
// 지사 인계 시: 결제 검증을 서버/BCEL 웹훅으로 대체할 수 있도록 이 레이어만 교체하면 됨.
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

const String _keyVerified = 'laotrust_verified_badge';

/// 인증 배지 활성화 여부 조회. 앱 전역에서 프로필·카드 등에 배지 표시 시 사용.
Future<bool> isVerifiedBadgeActive() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyVerified) ?? false;
}

/// 4.5 USD 결제 완료 후 호출. Verified 배지를 즉시 활성화.
/// (미션03: BCEL OnePay 시뮬레이션에서 '결제 완료' 시 이 함수 호출)
Future<void> setVerifiedBadgeActive(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyVerified, value);
}
