// =============================================================================
// LT-10 Firebase 통신망 · 70:30 전략 반영 Firestore 스키마
// 디지털 캡슐 v1.5 / LT-04 화면 정의서와 일치. 한/영 주석 병기.
// =============================================================================

// Collection names / 컬렉션 이름
const String kColUsers = 'users';
const String kColRequests = 'requests';
const String kColJobs = 'jobs';

// v5.1 전문가 요청: `artifacts/{projectId}/public/data/requests`
// 사진: Firebase Storage 업로드 후 `photos`에 HTTPS URL 배열 — lib/core/expert_request_photo_upload.dart

// -----------------------------------------------------------------------------
// 1. users 컬렉션 (LT-10 필수: is_verified, user_type)
// 문서 ID: Firebase Auth UID 권장.
// v1.3: 전문가 가용성·잠복·파트너 인증 필드 추가.
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
  /// 전문가: 지금 의뢰 받기 ON/OFF. OFF 시 위치 잠복(Clear).
  static const String dutyOn = 'duty_on';
  /// 전문가: 실시간 위치 위도. duty_on==false 이면 null로 갱신.
  static const String lat = 'lat';
  /// 전문가: 실시간 위치 경도. duty_on==false 이면 null로 갱신.
  static const String lng = 'lng';
  /// 사령관 검수 완료 시 true. Verified by Commander.
  static const String commanderApproved = 'commander_approved';
  /// 디지털 파트너 고유 시리얼 번호 (예: LT-P-2024-00001).
  static const String partnerSerialId = 'partner_serial_id';
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
  /// 급구 알바: 마감 시각 (Timestamp). 퀵 데드라인 바 계산용.
  static const String deadlineAt = 'deadline_at';
  /// v10.8: KO/EN/LO 삼중 맵 (Firestore Map)
  static const String titleI18n = 'title_i18n';
  static const String locationI18n = 'location_i18n';
  static const String salaryI18n = 'salary_i18n';
  static const String descriptionI18n = 'description_i18n';
}
