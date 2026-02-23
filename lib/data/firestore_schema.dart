// =============================================================================
// LT-10 Firebase 통신망 · 70:30 전략 반영 Firestore 스키마
// 디지털 캡슐 v1.5 / LT-04 화면 정의서와 일치. 한/영 주석 병기.
// =============================================================================

// Collection names / 컬렉션 이름
const String kColUsers = 'users';
const String kColRequests = 'requests';
const String kColJobs = 'jobs';

// -----------------------------------------------------------------------------
// 1. users 컬렉션 (LT-10 필수: is_verified, user_type)
// 문서 ID: Firebase Auth UID 권장.
// -----------------------------------------------------------------------------
abstract class UserFields {
  static const String phone = 'phone';
  static const String displayName = 'displayName';
  static const String photoUrl = 'photoUrl';
  /// 인증 배지 유무 (4.5 USD 결제 완료 시 true) / Verification badge
  static const String isVerified = 'is_verified';
  /// 전문가/일반 구분 (필수) / expert | general
  static const String userType = 'user_type';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// user_type 값 / User type values
const String kUserTypeExpert = 'expert';
const String kUserTypeGeneral = 'general';

// -----------------------------------------------------------------------------
// 2. requests 컬렉션 (70% 전문가 매칭 · 3단계 질문 데이터 저장 구조)
// 요청서 제출 시 생성. LT-04 요청서 화면(질문지 Step1~3)과 동일 구조.
// -----------------------------------------------------------------------------
abstract class RequestFields {
  static const String userId = 'userId';
  static const String category = 'category';
  /// Step1 증상 선택 / Step1 symptom IDs
  static const String symptoms = 'symptoms';
  /// Step2 위치 / Step2 location
  static const String location = 'location';
  /// Step2 희망 시간 / Step2 wished time
  static const String wishedTime = 'wishedTime';
  /// Step3 사진 URL 등 / Step3 photo (optional)
  static const String photoUrl = 'photoUrl';
  /// Step3 추가 요청사항 / Step3 extra note
  static const String extraNote = 'extraNote';
  static const String status = 'status';
  static const String expertVerified = 'expertVerified';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// -----------------------------------------------------------------------------
// 3. jobs 컬렉션 (30% 위치 기반 급구 알바 · GeoPoint)
// LT-10: 위치 기반(GeoPoint) 저장 구조. 지도 연동용.
// -----------------------------------------------------------------------------
abstract class JobFields {
  static const String employerId = 'employerId';
  static const String title = 'title';
  static const String description = 'description';
  /// 주소 텍스트 / Address string
  static const String location = 'location';
  /// 위치 기반(GeoPoint) 필수. 지도 표시/거리 계산용. / GeoPoint for map & distance
  static const String locationGeo = 'location_geo';
  static const String salary = 'salary';
  static const String jobType = 'jobType';
  static const String employerVerified = 'employerVerified';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}
