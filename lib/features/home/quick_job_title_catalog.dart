// =============================================================================
// v7.9 급구 알바 제목 동적 현지화 — 사용자 입력 문구 ↔ 저장용 i18n 키
// Firestore title 필드에 키 문자열을 넣으면 모든 언어에서 t()로 표시된다.
// =============================================================================

/// 사용자가 입력한 제목(공백 제거 후)이 사전에 있으면 저장/표시용 키.
const Map<String, String> kQuickJobTitlePhraseToKey = {
  // 짧은 한글 입력 (신규 등록 UX)
  '행사': 'quick_job_dyn_event',
  '이벤트': 'quick_job_dyn_event',
  '배달': 'quick_job_dyn_delivery',
  '청소': 'quick_job_dyn_cleaning',
  '수리': 'quick_job_dyn_repair',
  '경비': 'quick_job_dyn_security',
  '과외': 'quick_job_dyn_tutoring',
  '뷰티': 'quick_job_dyn_beauty',
  '사진': 'quick_job_dyn_photo',
  '정원': 'quick_job_dyn_garden',
  // 영문
  'Event': 'quick_job_dyn_event',
  'Delivery': 'quick_job_dyn_delivery',
  'Cleaning': 'quick_job_dyn_cleaning',
  'Repair': 'quick_job_dyn_repair',
  // 라오어 (홈 그리드·카테고리와 정렬)
  'ອີເວັນ': 'quick_job_dyn_event',
  'ຂົນສົ່ງ': 'quick_job_dyn_delivery',
  'ທຳຄວາມສະອາດ': 'quick_job_dyn_cleaning',
};

/// 등록 시 Firestore에 넣을 값: 사전 키가 있으면 키 문자열, 없으면 null (호출측에서 원문 사용).
String? quickJobTitleStorageKeyForInput(String trimmedTitle) {
  if (trimmedTitle.isEmpty) return null;
  return kQuickJobTitlePhraseToKey[trimmedTitle];
}
