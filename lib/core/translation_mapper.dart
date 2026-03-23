// =============================================================================
// v10.1 급구 알바: 저장/표시 변환 레이어 (TranslationMapper)
// DB에는 i18n 키 또는 __lt_literal__: 접두 + 원문만 둔다. 표시는 t() + 원문 폴백.
// =============================================================================

import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Firestore에 원문을 넣을 때 사용하는 접두(사용자가 입력할 수 없는 형태).
const String kQuickJobLiteralPrefix = '__lt_literal__:';

/// 사용자가 입력한 제목(공백 제거 후)이 사전에 있으면 저장/표시용 키.
const Map<String, String> kQuickJobTitlePhraseToKey = {
  '행사': 'quick_job_dyn_event',
  '이벤트': 'quick_job_dyn_event',
  '배달': 'quick_job_dyn_delivery',
  '청소': 'quick_job_dyn_cleaning',
  '수리': 'quick_job_dyn_repair',
  '경비': 'quick_job_dyn_security',
  '경호': 'quick_job_dyn_security',
  '과외': 'quick_job_dyn_tutoring',
  '뷰티': 'quick_job_dyn_beauty',
  '사진': 'quick_job_dyn_photo',
  '정원': 'quick_job_dyn_garden',
  'Event': 'quick_job_dyn_event',
  'Events': 'quick_job_dyn_event',
  'Delivery': 'quick_job_dyn_delivery',
  'Cleaning': 'quick_job_dyn_cleaning',
  'Repair': 'quick_job_dyn_repair',
  'Security': 'quick_job_dyn_security',
  'Tutoring': 'quick_job_dyn_tutoring',
  'Beauty': 'quick_job_dyn_beauty',
  'Photo': 'quick_job_dyn_photo',
  'Garden': 'quick_job_dyn_garden',
  'ອີເວັນ': 'quick_job_dyn_event',
  'ຂົນສົ່ງ': 'quick_job_dyn_delivery',
  'ທຳຄວາມສະອາດ': 'quick_job_dyn_cleaning',
  'ສ້ອມແປງ': 'quick_job_dyn_repair',
  'ຮັກສາຄວາມປອດໄພ': 'quick_job_dyn_security',
};

/// 업무 상세(짧은 한글 등) → 저장용 i18n 키
const Map<String, String> kQuickJobDetailPhraseToKey = {
  '질서유지': 'quick_job_dyn_desc_order',
  '질서 유지': 'quick_job_dyn_desc_order',
  '질서정리': 'quick_job_dyn_desc_order',
  '질서 정리': 'quick_job_dyn_desc_order',
};

String? quickJobTitleStorageKeyForInput(String trimmedTitle) {
  if (trimmedTitle.isEmpty) return null;
  return kQuickJobTitlePhraseToKey[trimmedTitle];
}

String? quickJobDetailStorageKeyForInput(String trimmedDetail) {
  if (trimmedDetail.isEmpty) return null;
  return kQuickJobDetailPhraseToKey[trimmedDetail];
}

/// 기존 샘플/레거시 한·영·라 값 → 키 (Firestore 정규화·표시 폴백용)
const Map<String, String> kQuickJobTitleLegacyValueToKey = {
  ...kQuickJobTitlePhraseToKey,
  '\uC2DD\uB2F9 \uC11C\uBC84': 'job_title_restaurant_server',
  '\uB2E8\uC21C \uB178\uBB34': 'job_title_simple_labor',
  '\uCE74\uD398 \uC54C\uBC14': 'job_title_cafe_part_time',
  '\uBC30\uB2EC \uB3C4\uC6B0\uBBF8': 'job_title_delivery_helper',
  '\uD589\uC0AC \uC2A4\uD0DC\uD504': 'job_title_event_staff',
  '\uBB3C\uB958 \uBCF4\uC870': 'job_title_logistics',
  '\uD310\uCD09 \uD64D\uBCF4': 'job_title_promotion',
  'Restaurant Server': 'job_title_restaurant_server',
  'Simple Labor': 'job_title_simple_labor',
  'Cafe Part-time': 'job_title_cafe_part_time',
  'Event Staff': 'job_title_event_staff',
  'Logistics Assistant': 'job_title_logistics',
  'Promotion': 'job_title_promotion',
  'ພະນັກງານຮ້ານອາຫານ': 'job_title_restaurant_server',
  'ແຮງງານທົ່ວໄປ': 'job_title_simple_labor',
  'ວຽກພາດໄທມ໌ຮ້ານກາເຟ': 'job_title_cafe_part_time',
  'ພະນັກງານງານອີເວັນ': 'job_title_event_staff',
  'ຊ່ວຍວຽກຂົນສົ່ງ': 'job_title_logistics',
  'ຕະຫຼາດ/ໂຄສະນາ': 'job_title_promotion',
};

const Map<String, String> kQuickJobLocLegacyValueToKey = {
  '\uBE44\uC5D4\uD2F0\uC548 \uC2DC\uCCAD \uC778\uADFC': 'location_near_vientiane_hall',
  '\uD0C0\uB77D\uAD11\uC7A5 \uADFC\uCC98': 'location_near_that_luang',
  '\uC2DC\uB0B4 \uC911\uC2EC\uAC00': 'location_downtown',
  '\uC2DC\uB0B4': 'location_downtown',
};

const Map<String, String> kQuickJobSalaryLegacyValueToKey = {
  '15,000 LAK/\uC2DC\uAC04': 'salary_15k_per_hour',
  '12,000 LAK/\uC2DC\uAC04': 'salary_12k_per_hour',
  '\uD611\uC758': 'salary_negotiable',
};

const Map<String, String> kQuickJobDetailLegacyValueToKey = {
  ...kQuickJobDetailPhraseToKey,
  '\uC2DD\uB2F9 \uC11C\uBC84': 'job_detail_restaurant_server',
  '\uB2E8\uC21C \uB178\uBB34': 'job_detail_simple_labor',
  '\uCE74\uD398 \uC54C\uBC14': 'job_detail_cafe_part_time',
  '\uD589\uC0AC \uC2A4\uD0DC\uD504': 'job_detail_event_staff',
  '\uBB3C\uB958 \uBCF4\uC870': 'job_detail_logistics',
  '\uD310\uCD09 \uD64D\uBCF4': 'job_detail_promotion',
  'Restaurant Server': 'job_detail_restaurant_server',
  'Simple Labor': 'job_detail_simple_labor',
  'Cafe Part-time': 'job_detail_cafe_part_time',
  'Event Staff': 'job_detail_event_staff',
  'Logistics Assistant': 'job_detail_logistics',
  'Promotion': 'job_detail_promotion',
  'ພະນັກງານຮ້ານອາຫານ': 'job_detail_restaurant_server',
  'ແຮງງານທົ່ວໄປ': 'job_detail_simple_labor',
  'ວຽກພາດໄທມ໌ຮ້ານກາເຟ': 'job_detail_cafe_part_time',
  'ພະນັກງານງານອີເວັນ': 'job_detail_event_staff',
  'ຊ່ວຍວຽກຂົນສົ່ງ': 'job_detail_logistics',
  'ຕະຫຼາດ/ໂຄສະນາ': 'job_detail_promotion',
};

bool _looksLikeI18nKey(String s) => s.startsWith('quick_job_') || s.startsWith('job_') || s.startsWith('location_') || s.startsWith('salary_');

String encodeQuickJobTitleForFirestore(String trimmed) {
  if (trimmed.isEmpty) return 'quick_job_default_title';
  final key = quickJobTitleStorageKeyForInput(trimmed);
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$trimmed';
}

String encodeQuickJobLocationForFirestore(String trimmed) {
  if (trimmed.isEmpty) return 'quick_job_default_location';
  final key = kQuickJobLocLegacyValueToKey[trimmed];
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$trimmed';
}

String encodeQuickJobSalaryForFirestore(String trimmed) {
  if (trimmed.isEmpty) return 'salary_negotiable';
  final key = kQuickJobSalaryLegacyValueToKey[trimmed];
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$trimmed';
}

String encodeQuickJobDetailForFirestore(String trimmed) {
  if (trimmed.isEmpty) return '';
  final key = quickJobDetailStorageKeyForInput(trimmed);
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$trimmed';
}

String normalizeQuickJobTitleFromFirestore(dynamic v) {
  if (v == null) return 'quick_job_default_title';
  final s = v.toString().trim();
  if (s.isEmpty) return 'quick_job_default_title';
  if (s.startsWith(kQuickJobLiteralPrefix)) return s;
  if (_looksLikeI18nKey(s)) return s;
  final byPhrase = kQuickJobTitlePhraseToKey[s] ?? kQuickJobTitleLegacyValueToKey[s];
  if (byPhrase != null) return byPhrase;
  return '$kQuickJobLiteralPrefix$s';
}

String normalizeQuickJobLocationFromFirestore(dynamic v) {
  if (v == null) return 'quick_job_default_location';
  final s = v.toString().trim();
  if (s.isEmpty) return 'quick_job_default_location';
  if (s.startsWith(kQuickJobLiteralPrefix)) return s;
  if (_looksLikeI18nKey(s)) return s;
  final key = kQuickJobLocLegacyValueToKey[s];
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$s';
}

String normalizeQuickJobSalaryFromFirestore(dynamic v) {
  if (v == null) return 'salary_negotiable';
  final s = v.toString().trim();
  if (s.isEmpty) return 'salary_negotiable';
  if (s.startsWith(kQuickJobLiteralPrefix)) return s;
  if (_looksLikeI18nKey(s)) return s;
  final key = kQuickJobSalaryLegacyValueToKey[s];
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$s';
}

String normalizeQuickJobDetailFromFirestore(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty) return '';
  if (s.startsWith(kQuickJobLiteralPrefix)) return s;
  if (_looksLikeI18nKey(s)) return s;
  final byPhrase = kQuickJobDetailPhraseToKey[s] ?? kQuickJobDetailLegacyValueToKey[s];
  if (byPhrase != null) return byPhrase;
  return '$kQuickJobLiteralPrefix$s';
}

/// UI 표시: 키는 t(), 리터럴 접두는 원문, 레거시 생텍스트는 사전 역매핑 후 l10n.
String displayQuickJobStoredField(
  BuildContext context,
  String stored, {
  required Map<String, String> legacyValueToKey,
}) {
  final t = stored.trim();
  if (t.isEmpty) return '';
  if (t.startsWith(kQuickJobLiteralPrefix)) {
    return t.substring(kQuickJobLiteralPrefix.length);
  }
  final localized = context.t(t);
  if (localized != t) return localized;
  final key = legacyValueToKey[t];
  return key == null ? t : context.l10n(key);
}

String displayQuickJobTitle(BuildContext context, String stored) {
  return displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobTitleLegacyValueToKey);
}

String displayQuickJobLocation(BuildContext context, String stored) {
  return displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobLocLegacyValueToKey);
}

String displayQuickJobSalary(BuildContext context, String stored) {
  return displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobSalaryLegacyValueToKey);
}

String displayQuickJobDetail(BuildContext context, String stored) {
  return displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobDetailLegacyValueToKey);
}
