// =============================================================================
// v10.1 급구 알바: 저장/표시 변환 레이어 (TranslationMapper)
// DB에는 i18n 키 또는 __lt_literal__: 접두 + 원문만 둔다. 표시는 t() + 원문 폴백.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  '비엔티안 시청 인근': 'location_near_vientiane_hall',
  '비엔티안시청인근': 'location_near_vientiane_hall',
  '비엔티안': 'location_near_vientiane_hall',
  'Vientiane city hall area': 'location_near_vientiane_hall',
  'Near Vientiane Hall': 'location_near_vientiane_hall',
  '타락광장 근처': 'location_near_that_luang',
  'That Luang area': 'location_near_that_luang',
  '시내 중심가': 'location_downtown',
  '시내중심가': 'location_downtown',
  'Downtown': 'location_downtown',
  'City center': 'location_downtown',
  'City Center': 'location_downtown',
  '시내': 'location_downtown',
  'ໃຈກາງເມືອງ': 'location_downtown',
};

const Map<String, String> kQuickJobSalaryLegacyValueToKey = {
  '15,000 LAK/\uC2DC\uAC04': 'salary_15k_per_hour',
  '12,000 LAK/\uC2DC\uAC04': 'salary_12k_per_hour',
  '\uD611\uC758': 'salary_negotiable',
  '추후 결정': 'salary_negotiable',
  '추후결정': 'salary_negotiable',
  'Negotiable': 'salary_negotiable',
  'TBD': 'salary_negotiable',
  'To be determined': 'salary_negotiable',
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

String _trimCollapseWs(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String _compactNoSpace(String s) => s.replaceAll(RegExp(r'\s+'), '');

String? _lookupLocationPhrase(String trimmed) {
  final t = trimmed.trim();
  if (t.isEmpty) return null;
  return kQuickJobLocLegacyValueToKey[t] ??
      kQuickJobLocLegacyValueToKey[_trimCollapseWs(t)] ??
      kQuickJobLocLegacyValueToKey[_compactNoSpace(t)];
}

String? _lookupSalaryPhrase(String trimmed) {
  final t = trimmed.trim();
  if (t.isEmpty) return null;
  return kQuickJobSalaryLegacyValueToKey[t] ??
      kQuickJobSalaryLegacyValueToKey[_trimCollapseWs(t)] ??
      kQuickJobSalaryLegacyValueToKey[_compactNoSpace(t)];
}

String encodeQuickJobTitleForFirestore(String trimmed) {
  if (trimmed.isEmpty) return 'quick_job_default_title';
  final key = quickJobTitleStorageKeyForInput(trimmed);
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$trimmed';
}

String encodeQuickJobLocationForFirestore(String trimmed) {
  if (trimmed.isEmpty) return 'quick_job_default_location';
  final key = _lookupLocationPhrase(trimmed);
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$trimmed';
}

String encodeQuickJobSalaryForFirestore(String trimmed) {
  if (trimmed.isEmpty) return 'salary_negotiable';
  final key = _lookupSalaryPhrase(trimmed);
  if (key != null) return key;
  final t = trimmed.trim();
  if (RegExp(r'^\s*협의\s*$', unicode: true).hasMatch(t)) {
    return 'salary_negotiable';
  }
  if (t.contains('협의')) {
    return '$kQuickJobLiteralPrefix$t';
  }
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
  final key = _lookupLocationPhrase(s);
  if (key != null) return key;
  return '$kQuickJobLiteralPrefix$s';
}

String normalizeQuickJobSalaryFromFirestore(dynamic v) {
  if (v == null) return 'salary_negotiable';
  final s = v.toString().trim();
  if (s.isEmpty) return 'salary_negotiable';
  if (s.startsWith(kQuickJobLiteralPrefix)) return s;
  if (_looksLikeI18nKey(s)) return s;
  final key = _lookupSalaryPhrase(s);
  if (key != null) return key;
  if (s.contains('협의')) {
    return '$kQuickJobLiteralPrefix$s';
  }
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

/// 리터럴/혼합 문자열 속 자주 쓰는 장소 키워드를 현재 로케일 [t]로 치환 (긴 구문 우선).
String localizeQuickJobLocationFreeText(BuildContext context, String s) {
  if (s.isEmpty) return s;
  var o = s;
  final pairs = <(String, String)>[
    ('비엔티안 시청 인근', 'location_near_vientiane_hall'),
    ('비엔티안시청인근', 'location_near_vientiane_hall'),
    ('타락광장 근처', 'location_near_that_luang'),
    ('시내 중심가', 'location_downtown'),
    ('시내중심가', 'location_downtown'),
    ('비엔티안', 'location_near_vientiane_hall'),
  ];
  for (final p in pairs) {
    o = o.replaceAll(p.$1, context.t(p.$2));
  }
  return o;
}

/// 급여 문구 속 '협의·추후 결정' 등을 현재 로케일 키로 치환 (숫자·단위는 유지).
String localizeQuickJobSalaryFreeText(BuildContext context, String s) {
  if (s.isEmpty) return s;
  var o = s;
  o = o.replaceAll('추후 결정', context.t('salary_negotiable'));
  o = o.replaceAll('추후결정', context.t('salary_negotiable'));
  o = o.replaceAll('협의', context.t('salary_negotiable'));
  o = o.replaceAll('Negotiable', context.t('salary_negotiable'));
  o = o.replaceAll('TBD', context.t('salary_negotiable'));
  return o;
}

String localizeQuickJobDetailFreeText(BuildContext context, String s) {
  if (s.isEmpty) return s;
  var o = s;
  o = o.replaceAll('질서 유지', context.t('quick_job_dyn_desc_order'));
  o = o.replaceAll('질서유지', context.t('quick_job_dyn_desc_order'));
  o = o.replaceAll('질서 정리', context.t('quick_job_dyn_desc_order'));
  o = o.replaceAll('질서정리', context.t('quick_job_dyn_desc_order'));
  return o;
}

String displayQuickJobTitle(BuildContext context, String stored) {
  return displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobTitleLegacyValueToKey);
}

String displayQuickJobLocation(BuildContext context, String stored) {
  final base = displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobLocLegacyValueToKey);
  return localizeQuickJobLocationFreeText(context, base);
}

String displayQuickJobSalary(BuildContext context, String stored) {
  final base = displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobSalaryLegacyValueToKey);
  return localizeQuickJobSalaryFreeText(context, base);
}

String displayQuickJobDetail(BuildContext context, String stored) {
  final base = displayQuickJobStoredField(context, stored, legacyValueToKey: kQuickJobDetailLegacyValueToKey);
  return localizeQuickJobDetailFreeText(context, base);
}

// =============================================================================
// v12.0 급구 알바: TranslationMapper AI 일괄 번역 + Zero-Pending (문구 미노출)
// =============================================================================

/// EN 슬롯 폴백 (한글·번역 실패 시, "Pending" 문구 사용 금지).
const String kQuickJobNeutralLineEn = 'View full details in the LaoTrust app.';

/// LO 슬롯 폴백
const String kQuickJobNeutralLineLo = 'ເບິ່ງລາຍລະອຽດໃນແອັບ LaoTrust';

/// KO 슬롯 폴백 (비한글 원문만 있을 때)
const String kQuickJobNeutralLineKo = '라오트러스트 앱에서 상세 내용을 확인할 수 있습니다.';

/// 신청 완료 등 UI용 정적 Triple-Map (키 → ko / en / lo).
const Map<String, Map<String, String>> kStaticUiTripleByMessageKey = {
  'application_complete_title': {
    'ko': '신청 완료',
    'en': 'Application Complete',
    'lo': 'ສຳເລັດການສະໝັກ',
  },
  'application_complete_message': {
    'ko': '전문가에게 요청이 성공적으로 전달되었습니다.\n잠시만 기다려주시면 전문가가 연락을 드립니다.',
    'en': 'Your request has been successfully sent to an expert.\nPlease wait and the expert will contact you shortly.',
    'lo': 'ຄຳຮ້ອງຂໍຂອງທ່ານຖືກສົ່ງໄປຫາຜູ້ຊ່ຽວຊານສຳເລັດແລ້ວ.\nກະລຸນາລໍຖ້າ, ຜູ້ຊ່ຽວຊານຈະຕິດຕໍ່ທ່ານໄວໆນີ້.',
  },
  'uploading_photos': {
    'ko': '사진 업로드 중...',
    'en': 'Uploading photos...',
    'lo': 'ກຳລັງອັບໂຫລດຮູບພາບ...',
  },
  'translating_request': {
    'ko': '번역 중...',
    'en': 'Translating...',
    'lo': 'ກຳລັງແປພາສາ...',
  },
  'submitting_request': {
    'ko': '전문가에게 전달 중...',
    'en': 'Sending to expert...',
    'lo': 'ກຳລັງສົ່ງຫາຜູ້ຊ່ຽວຊານ...',
  },
  'almost_done': {
    'ko': '거의 완료됐습니다...',
    'en': 'Almost done...',
    'lo': 'ເກືອບສຳເລັດແລ້ວ...',
  },
  'radar_searching': {
    'ko': '주변 전문가를 탐색하는 중...',
    'en': 'Searching for nearby experts...',
    'lo': 'ກຳລັງຊອກຫາຜູ້ຊ່ຽວຊານໃກ້ຄຽງ...',
  },
  'radar_found': {
    'ko': '전문가를 찾았습니다!',
    'en': 'Expert found!',
    'lo': 'ພົບຜູ້ຊ່ຽວຊານແລ້ວ!',
  },
  'radar_stage_1km': {
    'ko': '반경 1km 탐색 중...',
    'en': 'Searching within 1km...',
    'lo': 'ກຳລັງຊອກຫາໃນລັດສະໝີ 1km...',
  },
  'radar_stage_3km': {
    'ko': '반경 3km로 확대 중...',
    'en': 'Expanding to 3km...',
    'lo': 'ກຳລັງຂະຫຍາຍໄປ 3km...',
  },
  'radar_stage_5km_plus': {
    'ko': '5km 이상 광역 탐색 중...',
    'en': 'Wide search beyond 5km...',
    'lo': 'ກຳລັງຊອກຫາໄກກວ່າ 5km...',
  },
  'area_or_size': {
    'ko': '면적 / 크기',
    'en': 'Area / Size',
    'lo': 'ພື້ນທີ່ / ຂະໜາດ',
  },
  'scale_small': {
    'ko': '소형 (S)',
    'en': 'Small (S)',
    'lo': 'ນ້ອຍ (S)',
  },
  'scale_medium': {
    'ko': '중형 (M)',
    'en': 'Medium (M)',
    'lo': 'ກາງ (M)',
  },
  'scale_large': {
    'ko': '대형 (L)',
    'en': 'Large (L)',
    'lo': 'ໃຫຍ່ (L)',
  },
  'logout': {
    'ko': '로그아웃',
    'en': 'Log Out',
    'lo': 'ອອກຈາກລະບົບ',
  },
  'logout_sub': {
    'ko': '현재 계정에서 로그아웃합니다',
    'en': 'Sign out from current account',
    'lo': 'ອອກຈາກບັນຊີປັດຈຸບັນ',
  },
  'inbox_title': {
    'ko': '수신함',
    'en': 'Inbox',
    'lo': 'ກ່ອງຈົດໝາຍ',
  },
  'inbox_empty': {
    'ko': '받은 신청이 없습니다',
    'en': 'No requests received',
    'lo': 'ບໍ່ມີຄໍາຮ້ອງຂໍ',
  },
  'inbox_status_pending': {
    'ko': '대기중',
    'en': 'Pending',
    'lo': 'ລໍຖ້າ',
  },
  'inbox_status_accepted': {
    'ko': '수락됨',
    'en': 'Accepted',
    'lo': 'ຍອມຮັບແລ້ວ',
  },
  'inbox_status_rejected': {
    'ko': '거절됨',
    'en': 'Rejected',
    'lo': 'ປະຕິເສດແລ້ວ',
  },
  'inbox_btn_accept': {
    'ko': '수락하기',
    'en': 'Accept',
    'lo': 'ຍອມຮັບ',
  },
  'inbox_btn_reject': {
    'ko': '거절하기',
    'en': 'Reject',
    'lo': 'ປະຕິເສດ',
  },
  'inbox_detail_title': {
    'ko': '신청 상세',
    'en': 'Request Detail',
    'lo': 'ລາຍລະອຽດຄໍາຮ້ອງ',
  },
  'inbox_category': {
    'ko': '카테고리',
    'en': 'Category',
    'lo': 'ໝວດໝູ່',
  },
  'inbox_location': {
    'ko': '위치',
    'en': 'Location',
    'lo': 'ສະຖານທີ່',
  },
  'inbox_schedule': {
    'ko': '희망 일시',
    'en': 'Preferred Date',
    'lo': 'ວັນທີທີ່ຕ້ອງການ',
  },
  'inbox_memo': {
    'ko': '추가 메모',
    'en': 'Additional Note',
    'lo': 'ບັນທຶກເພີ່ມເຕີມ',
  },
  'inbox_accept_confirm': {
    'ko': '이 신청을 수락하시겠습니까?',
    'en': 'Do you want to accept this request?',
    'lo': 'ທ່ານຕ້ອງການຍອມຮັບຄໍາຮ້ອງນີ້ບໍ?',
  },
  'inbox_reject_confirm': {
    'ko': '이 신청을 거절하시겠습니까?',
    'en': 'Do you want to reject this request?',
    'lo': 'ທ່ານຕ້ອງການປະຕິເສດຄໍາຮ້ອງນີ້ບໍ?',
  },
  'inbox_confirm_yes': {
    'ko': '네',
    'en': 'Yes',
    'lo': 'ແມ່ນ',
  },
  'inbox_confirm_no': {
    'ko': '아니오',
    'en': 'No',
    'lo': 'ບໍ່',
  },
  'inbox_photos': {
    'ko': '사진',
    'en': 'Photos',
    'lo': 'ຮູບພາບ',
  },
  'sub_cleaning_house': {
    'ko': '주택청소',
    'en': 'House Cleaning',
    'lo': 'ທຳຄວາມສະອາດເຮືອນ',
  },
  'sub_cleaning_restaurant_cafe': {
    'ko': '식당/카페',
    'en': 'Restaurant/Café',
    'lo': 'ຮ້ານອາຫານ/ກາເຟ',
  },
  'wizard_cleaning_restaurant_label': {
    'ko': '업종 유형',
    'en': 'Business Type',
    'lo': 'ປະເພດທຸລະກິດ',
  },
  'wizard_cleaning_restaurant_hint': {
    'ko': '예: 한식당, 카페, 베이커리 등',
    'en': 'e.g. Korean restaurant, café, bakery',
    'lo': 'ເຊັ່ນ: ຮ້ານອາຫານ, ກາເຟ, ເບເກີລີ',
  },
  'wizard_cleaning_scale_title': {
    'ko': '규모 선택 (S/M/L)',
    'en': 'Select Size (S/M/L)',
    'lo': 'ເລືອກຂະໜາດ (S/M/L)',
  },
  'cleaning_size_s': {
    'ko': 'S (30㎡ 이하)',
    'en': 'S (under 30㎡)',
    'lo': 'S (ຕ່ຳກວ່າ 30㎡)',
  },
  'cleaning_size_m': {
    'ko': 'M (30~60㎡)',
    'en': 'M (30~60㎡)',
    'lo': 'M (30~60㎡)',
  },
  'cleaning_size_l': {
    'ko': 'L (60㎡ 이상)',
    'en': 'L (over 60㎡)',
    'lo': 'L (ເກີນ 60㎡)',
  },
  'cleaning_house_type': {
    'ko': '주거 형태',
    'en': 'Housing Type',
    'lo': 'ປະເພດທີ່ພັກ',
  },
  'cleaning_house_apartment': {
    'ko': '아파트',
    'en': 'Apartment',
    'lo': 'ອາພາດເມັນ',
  },
  'cleaning_house_villa': {
    'ko': '빌라',
    'en': 'Villa',
    'lo': 'ວິນລາ',
  },
  'cleaning_house_detached': {
    'ko': '단독주택',
    'en': 'Detached House',
    'lo': 'ເຮືອນດ່ຽວ',
  },
  'cleaning_house_officetel': {
    'ko': '오피스텔',
    'en': 'Studio/Officetel',
    'lo': 'ສະຕູດິໂອ',
  },
  'cleaning_room_count': {
    'ko': '방 개수',
    'en': 'Number of Rooms',
    'lo': 'ຈຳນວນຫ້ອງ',
  },
  'cleaning_bathroom_count': {
    'ko': '화장실 개수',
    'en': 'Number of Bathrooms',
    'lo': 'ຈຳນວນຫ້ອງນ້ຳ',
  },
  'cleaning_area_m2': {
    'ko': '면적 (m²)',
    'en': 'Area (m²)',
    'lo': 'ພື້ນທີ່ (m²)',
  },
  'cleaning_area_hint': {
    'ko': '예: 50',
    'en': 'e.g. 50',
    'lo': 'ຕົວຢ່າງ: 50',
  },
  'cleaning_visit_target': {
    'ko': '청소 대상',
    'en': 'Cleaning Target',
    'lo': 'ເປົ້າໝາຍການທຳຄວາມສະອາດ',
  },
  'cleaning_visit_home': {
    'ko': '가정집',
    'en': 'Home',
    'lo': 'ເຮືອນ',
  },
  'cleaning_visit_office': {
    'ko': '사무실',
    'en': 'Office',
    'lo': 'ຫ້ອງການ',
  },
  'cleaning_visit_store': {
    'ko': '매장',
    'en': 'Store',
    'lo': 'ຮ້ານຄ້າ',
  },
  'cleaning_visit_cycle': {
    'ko': '방문 주기',
    'en': 'Visit Frequency',
    'lo': 'ຄວາມຖີ່ການເຂົ້າຢ້ຽມ',
  },
  'cleaning_cycle_w1': {
    'ko': '주 1회',
    'en': 'Once a week',
    'lo': '1 ຄັ້ງ/ອາທິດ',
  },
  'cleaning_cycle_w2': {
    'ko': '주 2회',
    'en': 'Twice a week',
    'lo': '2 ຄັ້ງ/ອາທິດ',
  },
  'cleaning_cycle_m2': {
    'ko': '월 2회',
    'en': 'Twice a month',
    'lo': '2 ຄັ້ງ/ເດືອນ',
  },
  'cleaning_cycle_m1': {
    'ko': '월 1회',
    'en': 'Once a month',
    'lo': '1 ຄັ້ງ/ເດືອນ',
  },
  'cleaning_bedding_type': {
    'ko': '침구 종류',
    'en': 'Bedding Type',
    'lo': 'ປະເພດເຄື່ອງນອນ',
  },
  'cleaning_bedding_duvet': {
    'ko': '이불',
    'en': 'Duvet',
    'lo': 'ຜ້າຫົ່ມ',
  },
  'cleaning_bedding_pillow': {
    'ko': '베개',
    'en': 'Pillow',
    'lo': 'ໝອນ',
  },
  'cleaning_bedding_mattress': {
    'ko': '매트리스',
    'en': 'Mattress',
    'lo': 'ທີ່ນອນ',
  },
  'cleaning_bedding_set': {
    'ko': '전체 세트',
    'en': 'Full Set',
    'lo': 'ຊຸດທັງໝົດ',
  },
  'cleaning_appliance_type': {
    'ko': '가전 종류 (복수 선택)',
    'en': 'Appliance Type (multiple)',
    'lo': 'ປະເພດເຄື່ອງໃຊ້ໄຟຟ້າ',
  },
  'cleaning_appliance_ac': {
    'ko': '에어컨',
    'en': 'Air Conditioner',
    'lo': 'ເຄື່ອງປັບອາກາດ',
  },
  'cleaning_appliance_fridge': {
    'ko': '냉장고',
    'en': 'Refrigerator',
    'lo': 'ຕູ້ເຢັນ',
  },
  'cleaning_appliance_washer': {
    'ko': '세탁기',
    'en': 'Washing Machine',
    'lo': 'ເຄື່ອງຊັກຜ້າ',
  },
  'cleaning_appliance_dishwasher': {
    'ko': '식기세척기',
    'en': 'Dishwasher',
    'lo': 'ເຄື່ອງລ້າງຈານ',
  },
  'cleaning_appliance_oven': {
    'ko': '오븐',
    'en': 'Oven',
    'lo': 'ເຕົາອົບ',
  },
  'cleaning_appliance_microwave': {
    'ko': '전자레인지',
    'en': 'Microwave',
    'lo': 'ໄມໂຄເວັບ',
  },
  'cleaning_appliance_count': {
    'ko': '대수',
    'en': 'Number of Units',
    'lo': 'ຈຳນວນເຄື່ອງ',
  },
  'cleaning_count_1': {
    'ko': '1대',
    'en': '1 unit',
    'lo': '1 ເຄື່ອງ',
  },
  'cleaning_count_2': {
    'ko': '2대',
    'en': '2 units',
    'lo': '2 ເຄື່ອງ',
  },
  'cleaning_count_3plus': {
    'ko': '3대 이상',
    'en': '3+ units',
    'lo': '3+ ເຄື່ອງ',
  },
  'moving_vehicle_type': {
    'ko': '차량 종류',
    'en': 'Vehicle Type',
    'lo': 'ປະເພດລົດ',
  },
  'moving_vehicle_damas': {
    'ko': '소형 밴',
    'en': 'Small Van',
    'lo': 'ລົດຕູ້ນ້ອຍ',
  },
  'moving_vehicle_labo': {
    'ko': '픽업 트럭',
    'en': 'Pickup Truck',
    'lo': 'ລົດກະບະ',
  },
  'moving_vehicle_truck_1t': {
    'ko': '1톤 트럭',
    'en': '1-Ton Truck',
    'lo': 'ລົດບັນທຸກ 1 ໂຕນ',
  },
  'moving_vehicle_truck_2t': {
    'ko': '2.5톤 트럭',
    'en': '2.5-Ton Truck',
    'lo': 'ລົດບັນທຸກ 2.5 ໂຕນ',
  },
  'moving_floor_from': {
    'ko': '출발 층수',
    'en': 'From Floor',
    'lo': 'ຊັ້ນຕົ້ນທາງ',
  },
  'moving_floor_to': {
    'ko': '도착 층수',
    'en': 'To Floor',
    'lo': 'ຊັ້ນປາຍທາງ',
  },
  'moving_floor_1': {
    'ko': '1층',
    'en': '1F',
    'lo': 'ຊັ້ນ 1',
  },
  'moving_floor_2': {
    'ko': '2층',
    'en': '2F',
    'lo': 'ຊັ້ນ 2',
  },
  'moving_floor_3': {
    'ko': '3층',
    'en': '3F',
    'lo': 'ຊັ້ນ 3',
  },
  'moving_floor_4plus': {
    'ko': '4층 이상',
    'en': '4F+',
    'lo': 'ຊັ້ນ 4+',
  },
  'moving_elevator': {
    'ko': '엘리베이터',
    'en': 'Elevator',
    'lo': 'ລິຟ',
  },
  'moving_elevator_yes': {
    'ko': '있음',
    'en': 'Available',
    'lo': 'ມີ',
  },
  'moving_elevator_no': {
    'ko': '없음',
    'en': 'Not Available',
    'lo': 'ບໍ່ມີ',
  },
  'moving_room_count': {
    'ko': '방 개수',
    'en': 'Number of Rooms',
    'lo': 'ຈຳນວນຫ້ອງ',
  },
  'moving_house_type': {
    'ko': '주거 형태',
    'en': 'Housing Type',
    'lo': 'ປະເພດທີ່ພັກ',
  },
  'moving_cargo_type': {
    'ko': '짐 종류',
    'en': 'Cargo Type',
    'lo': 'ປະເພດສິນຄ້າ',
  },
  'moving_cargo_furniture': {
    'ko': '가구',
    'en': 'Furniture',
    'lo': 'ເຟີນິເຈີ',
  },
  'moving_cargo_appliance': {
    'ko': '가전',
    'en': 'Appliances',
    'lo': 'ເຄື່ອງໃຊ້ໄຟຟ້າ',
  },
  'moving_cargo_box': {
    'ko': '박스/짐',
    'en': 'Boxes/Luggage',
    'lo': 'ກ່ອງ/ເຄື່ອງ',
  },
  'moving_cargo_etc': {
    'ko': '기타',
    'en': 'Other',
    'lo': 'ອື່ນໆ',
  },
  'moving_weight': {
    'ko': '무게 (kg)',
    'en': 'Weight (kg)',
    'lo': 'ນ້ຳໜັກ (kg)',
  },
  'moving_weight_hint': {
    'ko': '예: 100',
    'en': 'e.g. 100',
    'lo': 'ຕົວຢ່າງ: 100',
  },
  'moving_distance': {
    'ko': '이동 거리',
    'en': 'Moving Distance',
    'lo': 'ໄລຍະທາງ',
  },
  'moving_distance_local': {
    'ko': '동네 이동',
    'en': 'Local',
    'lo': 'ໃນທ້ອງຖິ່ນ',
  },
  'moving_distance_city': {
    'ko': '시내 이동',
    'en': 'Within City',
    'lo': 'ໃນເມືອງ',
  },
  'moving_distance_intercity': {
    'ko': '도시 간 이동',
    'en': 'Between Cities',
    'lo': 'ລະຫວ່າງເມືອງ',
  },
  'login_required_title': {
    'ko': '로그인이 필요합니다',
    'en': 'Login Required',
    'lo': 'ຕ້ອງການເຂົ້າສູ່ລະບົບ',
  },
  'login_required_content': {
    'ko': '서비스를 이용하려면 전화번호로 로그인해 주세요.',
    'en': 'Please log in with your phone number to use this service.',
    'lo': 'ກະລຸນາເຂົ້າສູ່ລະບົບດ້ວຍເບີໂທລະສັບເພື່ອໃຊ້ບໍລິການ.',
  },
  'login_required_btn': {
    'ko': '로그인하기',
    'en': 'Log In',
    'lo': 'ເຂົ້າສູ່ລະບົບ',
  },
  'appliance_select_title': {
    'ko': '어떤 가전제품인가요?',
    'en': 'Which appliance needs repair?',
    'lo': 'ເຄື່ອງໃຊ້ໄຟຟ້າຫຍັງ?',
  },
  'appliance_select_desc': {
    'ko': '수리가 필요한 가전을 선택해 주세요',
    'en': 'Select the appliance that needs repair',
    'lo': 'ເລືອກເຄື່ອງໃຊ້ໄຟຟ້າທີ່ຕ້ອງການສ້ອມແປງ',
  },
  'appliance_ac': {
    'ko': '에어컨',
    'en': 'Air Conditioner',
    'lo': 'ເຄື່ອງປັບອາກາດ',
  },
  'appliance_fridge': {
    'ko': '냉장고',
    'en': 'Refrigerator',
    'lo': 'ຕູ້ເຢັນ',
  },
  'appliance_washer': {
    'ko': '세탁기',
    'en': 'Washing Machine',
    'lo': 'ເຄື່ອງຊັກຜ້າ',
  },
  'appliance_tv': {
    'ko': 'TV',
    'en': 'Television',
    'lo': 'ໂທລະທັດ',
  },
  'appliance_water_purifier': {
    'ko': '정수기',
    'en': 'Water Purifier',
    'lo': 'ເຄື່ອງກັ່ນນ້ຳ',
  },
  'appliance_fan': {
    'ko': '선풍기',
    'en': 'Electric Fan',
    'lo': 'ພັດລົມ',
  },
  'appliance_rice_cooker': {
    'ko': '전기밥솥',
    'en': 'Rice Cooker',
    'lo': 'ໝໍ້ຫຸງເຂົ້າໄຟຟ້າ',
  },
  'appliance_generator': {
    'ko': '발전기',
    'en': 'Generator',
    'lo': 'ເຄື່ອງປັ່ນໄຟ',
  },
  'appliance_other': {
    'ko': '기타 가전',
    'en': 'Other Appliance',
    'lo': 'ເຄື່ອງໃຊ້ໄຟຟ້າອື່ນ',
  },
  'sub_repair_appliance': {'ko': '가전제품 수리', 'en': 'Appliance Repair', 'lo': 'ສ້ອມແປງເຄື່ອງໃຊ້ໄຟຟ້າ'},
  'request_step1_title': {'ko': '어떤 증상인가요?', 'en': 'What is the symptom?', 'lo': 'ມີອາການຫຍັງ?'},
  'request_step1_desc': {'ko': '해당하는 증상을 모두 선택해 주세요', 'en': 'Select all symptoms that apply', 'lo': 'ເລືອກອາການທີ່ກົງກັນທັງໝົດ'},
  'symptom_other': {'ko': '기타', 'en': 'Other', 'lo': 'ອື່ນໆ'},
  'symptom_ac_no_cold_air': {'ko': '냉방이 안 돼요', 'en': 'No cold air', 'lo': 'ບໍ່ເຢັນ'},
  'symptom_ac_noise': {'ko': '소음이 심해요', 'en': 'Making noise', 'lo': 'ມີສຽງດັງ'},
  'symptom_ac_water_sound': {'ko': '물 소리가 나요', 'en': 'Water sound', 'lo': 'ມີສຽງນ້ຳ'},
  'symptom_ac_not_cool': {'ko': '시원하지 않아요', 'en': 'Not cooling enough', 'lo': 'ບໍ່ເຢັນພໍ'},
  'service_electric': {'ko': '전기', 'en': 'Electrical', 'lo': 'ໄຟຟ້າ'},
  'service_plumbing': {'ko': '배관', 'en': 'Plumbing', 'lo': 'ທໍ່ນ້ຳ'},
  'wizard_repair_sub_roof_paint': {'ko': '페인트 및 지붕 보수', 'en': 'Paint & Roof Repair', 'lo': 'ທາສີ ແລະ ສ້ອມຫຼັງຄາ'},
  'sub_interior_wallpaper': {'ko': '도배', 'en': 'Wallpaper', 'lo': 'ຕິດວໍລເປເປີ'},
  'sub_interior_flooring': {'ko': '바닥재', 'en': 'Flooring', 'lo': 'ພື້ນ'},
  'sub_interior_painting': {'ko': '페인트', 'en': 'Painting', 'lo': 'ທາສີ'},
  'sub_interior_bathroom': {'ko': '욕실', 'en': 'Bathroom', 'lo': 'ຫ້ອງນ້ຳ'},
  'sub_interior_kitchen': {'ko': '주방', 'en': 'Kitchen', 'lo': 'ຫ້ອງຄົວ'},
  'sub_interior_remodel': {'ko': '전체 리모델링', 'en': 'Full Remodel', 'lo': 'ສ້ອມແປງທັງໝົດ'},
  'interior_area_label': {'ko': '면적 (㎡)', 'en': 'Area (㎡)', 'lo': 'ພື້ນທີ່ (㎡)'},
  'interior_area_hint': {'ko': '예: 20', 'en': 'e.g. 20', 'lo': 'ຕົວຢ່າງ: 20'},
  'interior_housing_type': {'ko': '건물 유형', 'en': 'Building Type', 'lo': 'ປະເພດອາຄານ'},
  'interior_housing_house': {'ko': '단독주택', 'en': 'House', 'lo': 'ເຮືອນ'},
  'interior_housing_apartment': {'ko': '아파트', 'en': 'Apartment', 'lo': 'ອາພາດເມັນ'},
  'interior_housing_condo': {'ko': '콘도', 'en': 'Condo', 'lo': 'ຄອນໂດ'},
  'interior_housing_commercial': {'ko': '상업공간', 'en': 'Commercial', 'lo': 'ພື້ນທີ່ການຄ້າ'},
  'interior_wallpaper_type': {'ko': '벽지 종류', 'en': 'Wallpaper Type', 'lo': 'ປະເພດວໍລເປເປີ'},
  'interior_wallpaper_paper': {'ko': '종이 벽지', 'en': 'Paper', 'lo': 'ກະດາດ'},
  'interior_wallpaper_fabric': {'ko': '패브릭', 'en': 'Fabric', 'lo': 'ຜ້າ'},
  'interior_wallpaper_paint': {'ko': '페인트 마감', 'en': 'Paint Finish', 'lo': 'ທາສີ'},
  'interior_floor_type': {'ko': '바닥재 종류', 'en': 'Floor Type', 'lo': 'ປະເພດພື້ນ'},
  'interior_floor_tile': {'ko': '타일', 'en': 'Tile', 'lo': 'ກະເບື້ອງ'},
  'interior_floor_wood': {'ko': '원목/마루', 'en': 'Wood', 'lo': 'ໄມ້'},
  'interior_floor_marble': {'ko': '대리석', 'en': 'Marble', 'lo': 'ໝາກໄມ້'},
  'interior_floor_vinyl': {'ko': '비닐/LVT', 'en': 'Vinyl/LVT', 'lo': 'ໄວນີລ'},
  'interior_painting_area': {'ko': '도색 범위', 'en': 'Painting Scope', 'lo': 'ຂອບເຂດທາສີ'},
  'interior_painting_interior': {'ko': '내부', 'en': 'Interior', 'lo': 'ພາຍໃນ'},
  'interior_painting_exterior': {'ko': '외부', 'en': 'Exterior', 'lo': 'ພາຍນອກ'},
  'interior_painting_both': {'ko': '내외부 모두', 'en': 'Both', 'lo': 'ທັງສອງ'},
  'interior_bathroom_scope': {'ko': '욕실 공사 범위', 'en': 'Bathroom Scope', 'lo': 'ຂອບເຂດຫ້ອງນ້ຳ'},
  'interior_bathroom_tile': {'ko': '타일 교체', 'en': 'Tile', 'lo': 'ກະເບື້ອງ'},
  'interior_bathroom_toilet': {'ko': '변기 교체', 'en': 'Toilet', 'lo': 'ສ້ວມ'},
  'interior_bathroom_sink': {'ko': '세면대', 'en': 'Sink', 'lo': 'ອ່າງລ້າງໜ້າ'},
  'interior_bathroom_shower': {'ko': '샤워부스', 'en': 'Shower', 'lo': 'ອາບນ້ຳ'},
  'interior_bathroom_full': {'ko': '전체 공사', 'en': 'Full Renovation', 'lo': 'ສ້ອມແປງທັງໝົດ'},
  'interior_kitchen_scope': {'ko': '주방 공사 범위', 'en': 'Kitchen Scope', 'lo': 'ຂອບເຂດຫ້ອງຄົວ'},
  'interior_kitchen_cabinet': {'ko': '수납장', 'en': 'Cabinet', 'lo': 'ຕູ້'},
  'interior_kitchen_countertop': {'ko': '상판', 'en': 'Countertop', 'lo': 'ໜ້າໂຕະ'},
  'interior_kitchen_sink': {'ko': '싱크대', 'en': 'Sink', 'lo': 'ອ່າງລ້າງໄຫ'},
  'interior_kitchen_full': {'ko': '전체 교체', 'en': 'Full Replace', 'lo': 'ປ່ຽນທັງໝົດ'},
  'interior_remodel_scope': {'ko': '리모델링 범위', 'en': 'Remodel Scope', 'lo': 'ຂອບເຂດການສ້ອມແປງ'},
  'interior_remodel_partial': {'ko': '부분 리모델링', 'en': 'Partial', 'lo': 'ບາງສ່ວນ'},
  'interior_remodel_full': {'ko': '전체 리모델링', 'en': 'Full', 'lo': 'ທັງໝົດ'},
  'interior_budget_label': {'ko': '예산 범위', 'en': 'Budget Range', 'lo': 'ງົບປະມານ'},
  'interior_budget_s': {'ko': '500만원 이하', 'en': 'Under \$500', 'lo': 'ຕ່ຳກວ່າ 500USD'},
  'interior_budget_m': {'ko': '500~2000만원', 'en': '\$500~\$2,000', 'lo': '500~2,000USD'},
  'interior_budget_l': {'ko': '2000만원 이상', 'en': 'Over \$2,000', 'lo': 'ສູງກວ່າ 2,000USD'},
  'request_success_title': {'ko': '신청 완료', 'en': 'Request Sent!', 'lo': 'ສົ່ງຄຳຂໍແລ້ວ!'},
  'request_success_message': {'ko': '전문가에게 성공적으로 전달되었습니다.\n잠시 후 전문가가 연락드립니다.', 'en': 'Your request has been sent.\nAn expert will contact you shortly.', 'lo': 'ຄຳຂໍຂອງທ່ານໄດ້ຖືກສົ່ງແລ້ວ.\nຜູ້ຊ່ຽວຊານຈະຕິດຕໍ່ທ່ານໃນໄວໆນີ້.'},
  'confirm': {'ko': '확인', 'en': 'Confirm', 'lo': 'ຢືນຢັນ'},
  'wizard_other_service_label': {'ko': '기타 (직접 입력)', 'en': 'Other (direct input)', 'lo': 'ອື່ນໆ (ປ້ອນເອງ)'},
  'wizard_other_service_hint': {'ko': '원하시는 서비스를 직접 입력해 주세요', 'en': 'Please describe the service you need', 'lo': 'ກະລຸນາອະທິບາຍການບໍລິການທີ່ທ່ານຕ້ອງການ'},
  'wizard_other_service_name_label': {'ko': '기타 서비스명', 'en': 'Other service name', 'lo': 'ຊື່ການບໍລິການອື່ນ'},
  'wizard_other_service_name_hint': {'ko': '예: 베란다 수리, 창문 교체', 'en': 'e.g. Balcony repair, Window replacement', 'lo': 'ຕົວຢ່າງ: ສ້ອມລະເບຽງ, ປ່ຽນປ່ອງຢ້ຽມ'},
  'symptom_fridge_no_cool': {
    'ko': '냉각이 안 돼요',
    'en': 'Not cooling',
    'lo': 'ບໍ່ເຢັນ',
  },
  'symptom_fridge_noise': {
    'ko': '소음이 심해요',
    'en': 'Making noise',
    'lo': 'ມີສຽງດັງ',
  },
  'symptom_fridge_door': {
    'ko': '문이 안 닫혀요',
    'en': 'Door not closing',
    'lo': 'ປະຕູບໍ່ປິດ',
  },
  'symptom_fridge_ice': {
    'ko': '성에가 심해요',
    'en': 'Excessive frost',
    'lo': 'ນ້ຳກ້ອນຫຼາຍ',
  },
  'symptom_washer_no_spin': {
    'ko': '탈수가 안 돼요',
    'en': 'Not spinning',
    'lo': 'ບໍ່ປັ່ນ',
  },
  'symptom_washer_water_leak': {
    'ko': '물이 새요',
    'en': 'Water leaking',
    'lo': 'ນ້ຳຮົ່ວ',
  },
  'symptom_washer_noise': {
    'ko': '소음이 심해요',
    'en': 'Making noise',
    'lo': 'ມີສຽງດັງ',
  },
  'symptom_washer_no_power': {
    'ko': '전원이 안 켜져요',
    'en': 'No power',
    'lo': 'ບໍ່ເປີດໄດ້',
  },
  'symptom_tv_no_display': {
    'ko': '화면이 안 나와요',
    'en': 'No display',
    'lo': 'ໜ້າຈໍບໍ່ສະແດງ',
  },
  'symptom_tv_no_sound': {
    'ko': '소리가 안 나와요',
    'en': 'No sound',
    'lo': 'ບໍ່ມີສຽງ',
  },
  'symptom_tv_no_power': {
    'ko': '전원이 안 켜져요',
    'en': 'No power',
    'lo': 'ບໍ່ເປີດໄດ້',
  },
  'symptom_tv_remote': {
    'ko': '리모컨이 안 돼요',
    'en': 'Remote not working',
    'lo': 'ລີໂມດບໍ່ເຮັດວຽກ',
  },
  'symptom_wp_water_leak': {
    'ko': '물이 새요',
    'en': 'Water leaking',
    'lo': 'ນ້ຳຮົ່ວ',
  },
  'symptom_wp_no_cold': {
    'ko': '냉수가 안 나와요',
    'en': 'No cold water',
    'lo': 'ນ້ຳເຢັນບໍ່ອອກ',
  },
  'symptom_wp_no_hot': {
    'ko': '온수가 안 나와요',
    'en': 'No hot water',
    'lo': 'ນ້ຳຮ້ອນບໍ່ອອກ',
  },
  'symptom_wp_filter': {
    'ko': '필터 교체 필요해요',
    'en': 'Filter replacement needed',
    'lo': 'ຕ້ອງການປ່ຽນຕົວກອງ',
  },
  'symptom_fan_no_spin': {
    'ko': '날개가 안 돌아요',
    'en': 'Fan not spinning',
    'lo': 'ໃບພັດບໍ່ໝຸນ',
  },
  'symptom_fan_noise': {
    'ko': '소음이 심해요',
    'en': 'Making noise',
    'lo': 'ມີສຽງດັງ',
  },
  'symptom_fan_no_power': {
    'ko': '전원이 안 켜져요',
    'en': 'No power',
    'lo': 'ບໍ່ເປີດໄດ້',
  },
  'symptom_rc_no_cook': {
    'ko': '밥이 안 지어져요',
    'en': 'Not cooking rice',
    'lo': 'ຫຸງເຂົ້າບໍ່ໄດ້',
  },
  'symptom_rc_no_heat': {
    'ko': '가열이 안 돼요',
    'en': 'Not heating',
    'lo': 'ບໍ່ຮ້ອນ',
  },
  'symptom_rc_no_power': {
    'ko': '전원이 안 켜져요',
    'en': 'No power',
    'lo': 'ບໍ່ເປີດໄດ້',
  },
  'symptom_gen_no_start': {
    'ko': '시동이 안 걸려요',
    'en': "Won't start",
    'lo': 'ບໍ່ຕິດເຄື່ອງ',
  },
  'symptom_gen_no_power': {
    'ko': '전기가 안 나와요',
    'en': 'No power output',
    'lo': 'ໄຟຟ້າບໍ່ອອກ',
  },
  'symptom_gen_noise': {
    'ko': '소음이 심해요',
    'en': 'Making noise',
    'lo': 'ມີສຽງດັງ',
  },
  'symptom_gen_fuel_leak': {
    'ko': '연료가 새요',
    'en': 'Fuel leaking',
    'lo': 'ນໍ້າມັນຮົ່ວ',
  },
  'symptom_other_broken': {
    'ko': '작동이 안 돼요',
    'en': 'Not working',
    'lo': 'ບໍ່ເຮັດວຽກ',
  },
  'symptom_other_noise': {
    'ko': '소음이 심해요',
    'en': 'Making noise',
    'lo': 'ມີສຽງດັງ',
  },
  'symptom_other_no_power': {
    'ko': '전원이 안 켜져요',
    'en': 'No power',
    'lo': 'ບໍ່ເປີດໄດ້',
  },
};

bool translationMapperIsLegacyEnglishBridgePhrase(String s) {
  final t = s.trim().toLowerCase();
  return t.contains('this field was provided in korean') ||
      t.contains('this field was provided in lao');
}

bool translationMapperContainsHangul(String s) =>
    RegExp(r'[\u3131-\uD79D]').hasMatch(s);

/// 라오 문자 블록(표시·검수용).
bool translationMapperHasLaoScript(String s) =>
    RegExp(r'[\u0E80-\u0EFF]').hasMatch(s);

bool translationMapperIsLegacyPendingPhrase(String s) {
  final t = s.trim().toLowerCase();
  return t == 'pending translation' || t.contains('pending translation');
}

String _translationMapperLang2(String? code) {
  if (code == null || code.isEmpty) return 'en';
  final c = code.toLowerCase();
  if (c.startsWith('ko')) return 'ko';
  if (c.startsWith('lo')) return 'lo';
  return 'en';
}

bool _isLatinNumericSalaryLike(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  return RegExp(r'^[\d\s.,$/A-Za-z\u00a0\-+]+$', unicode: true).hasMatch(t);
}

/// Firestore 저장용 번역 결과.
class QuickJobTranslationResult {
  const QuickJobTranslationResult._({
    required this.isSuccess,
    this.bundle,
    this.message,
  });

  final bool isSuccess;
  final Map<String, Map<String, String>>? bundle;
  final String? message;

  factory QuickJobTranslationResult.ok(Map<String, Map<String, String>> b) =>
      QuickJobTranslationResult._(isSuccess: true, bundle: b, message: null);

  factory QuickJobTranslationResult.fail(String message) =>
      QuickJobTranslationResult._(isSuccess: false, bundle: null, message: message);
}

/// 급구 필드 4개 일괄 번역 → Firestore용 맵 리스트 [title, location, salary, detail].
class TranslationMapper {
  TranslationMapper._();

  static const String _translateEndpoint =
      'https://translation.googleapis.com/language/translate/v2';

  static bool _dotenvLoadAttempted = false;

  /// [main]에서 호출하지 않아도 되도록, 최초 번역 요청 시 한 번만 `.env` 로드.
  static Future<void> _ensureDotenvLoaded() async {
    if (_dotenvLoadAttempted) return;
    _dotenvLoadAttempted = true;
    try {
      await dotenv.load(fileName: '.env');
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranslationMapper: .env 로드 실패: $e');
        debugPrint('$st');
      }
    }
  }

  static const String _dartDefineApiKey =
      String.fromEnvironment('GOOGLE_TRANSLATE_API_KEY', defaultValue: '');

  static String _translateApiKeyValue() {
    if (_dartDefineApiKey.isNotEmpty) return _dartDefineApiKey;
    if (!dotenv.isInitialized) return '';
    try {
      return dotenv.get('GOOGLE_TRANSLATE_API_KEY').trim();
    } on Object catch (_) {
      return '';
    }
  }

  static bool get isTranslateApiKeyConfigured =>
      _translateApiKeyValue().isNotEmpty;

  static String neutralCaptionForLangCode(String localeLanguageCode) {
    switch (_translationMapperLang2(localeLanguageCode)) {
      case 'ko':
        return kQuickJobNeutralLineKo;
      case 'lo':
        return kQuickJobNeutralLineLo;
      default:
        return kQuickJobNeutralLineEn;
    }
  }

  /// v13.6: API 실패·키 없음 시 **원문을 ko/en/lo에 동일 복제** (비상 문구 금지).
  static Map<String, String> rawTripleForSameText(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return {'ko': '', 'en': '', 'lo': ''};
    return {'ko': t, 'en': t, 'lo': t};
  }

  /// 네 필드 각각 원문 삼중 맵 (Firestore 저장용).
  static Map<String, Map<String, String>> rawTripleBundleForFields(
    Map<String, String> originalData,
  ) {
    const keys = ['title', 'location', 'salary', 'detail'];
    return {
      for (final k in keys) k: rawTripleForSameText(originalData[k] ?? ''),
    };
  }

  /// 레거시·오프라인: [sourceLanguageCode]는 호환용으로만 유지.
  static Map<String, String> fallbackTripleForText(
    String raw,
    String sourceLanguageCode,
  ) {
    return rawTripleForSameText(raw);
  }

  static List<Map<String, String>> fallbackAllFields(
    String title,
    String location,
    String salary,
    String detail,
    String sourceLanguageCode,
  ) {
    return [
      fallbackTripleForText(title, sourceLanguageCode),
      fallbackTripleForText(location, sourceLanguageCode),
      fallbackTripleForText(salary, sourceLanguageCode),
      fallbackTripleForText(detail, sourceLanguageCode),
    ];
  }

  /// 키 없음·타임아웃·예외 시와 동일한 **원문 기반** 삼중 맵(각 필드 [finalizeTripleForFirestoreSave] 적용).
  static QuickJobTranslationResult _rawFinalizeBundleForAllFields(
    Map<String, String> originalData,
  ) {
    const keys = ['title', 'location', 'salary', 'detail'];
    final out = <String, Map<String, String>>{};
    for (final k in keys) {
      final src = (originalData[k] ?? '').trim();
      out[k] = finalizeTripleForFirestoreSave(
        {'ko': src, 'en': src, 'lo': src},
        src,
        k,
      );
    }
    return QuickJobTranslationResult.ok(out);
  }

  /// v13.9: 배치 → 후처리로 항상 저장 가능한 Triple-Map (검수 실패 반환 없음).
  /// 전체 상한은 [translateAllFieldsStrict]에서 단일 [timeout]으로 걸린다.
  static Future<QuickJobTranslationResult> _translateAllFieldsStrictImpl(
    Map<String, String> originalData, {
    required String sourceLanguageCode,
  }) async {
    await _ensureDotenvLoaded();
    const keys = ['title', 'location', 'salary', 'detail'];
    final keyTrim = _translateApiKeyValue();
    if (kDebugMode) {
      debugPrint(
        'TranslationMapper: GOOGLE_TRANSLATE_API_KEY configured=${keyTrim.isNotEmpty} '
        'length=${keyTrim.length} (키 본문은 로그에 넣지 않음)',
      );
    }
    if (!isTranslateApiKeyConfigured) {
      return _rawFinalizeBundleForAllFields(originalData);
    }

    Map<String, Map<String, String>>? batch;
    try {
      batch = await _translateBatchAllFourFields(
        originalData,
        sourceLanguageCode: sourceLanguageCode,
      ).timeout(const Duration(seconds: 10));
    } on _GeminiNoRetryException {
      batch = null;
    } on TimeoutException {
      batch = null;
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranslationMapper: 배치 번역 예외(즉시 폴백): $e');
        debugPrint('$st');
      }
      batch = null;
    }

    batch ??= {};
    final merged = <String, Map<String, String>>{};
    for (final k in keys) {
      final src = (originalData[k] ?? '').trim();
      final fromBatch = batch[k];
      var triple = fromBatch != null
          ? _sanitizeAiTripleStrict(fromBatch)
          : <String, String>{'ko': '', 'en': '', 'lo': ''};
      if (!fieldTriplePassesPolicy(triple, src, k)) {
        triple = {'ko': '', 'en': '', 'lo': ''};
      }
      merged[k] = triple;
    }

    // 번역·검수 실패 시 API 재호출·지연 재시도 없음 → 원문을 ko/en/lo에 동일 반영 후 [finalize]만 수행 (루프 차단).
    for (final k in keys) {
      final src = (originalData[k] ?? '').trim();
      if (src.isEmpty) continue;
      if (!fieldTriplePassesPolicy(merged[k]!, src, k)) {
        merged[k] = rawTripleForSameText(src);
      }
    }

    for (final k in keys) {
      merged[k] = finalizeTripleForFirestoreSave(
        merged[k]!,
        originalData[k] ?? '',
        k,
      );
    }

    return QuickJobTranslationResult.ok(merged);
  }

  /// 전체 작업(서비스 호출·후처리)을 **최대 10초**에 끝낸다. 초과·예외 시 원문 트리플만 반환(무한 대기 방지).
  static Future<QuickJobTranslationResult> translateAllFieldsStrict(
    Map<String, String> originalData, {
    required String sourceLanguageCode,
  }) async {
    debugPrint('[TRANSLATE] 번역 시작');
    try {
      final r = await _translateAllFieldsStrictImpl(
        originalData,
        sourceLanguageCode: sourceLanguageCode,
      ).timeout(const Duration(seconds: 10));
      debugPrint('[TRANSLATE] 번역 완료');
      return r;
    } on TimeoutException catch (e) {
      debugPrint('[TRANSLATE] 실패: $e');
      return _rawFinalizeBundleForAllFields(originalData);
    } on Object catch (e, st) {
      debugPrint('[TRANSLATE] 실패: $e');
      if (kDebugMode) debugPrint('$st');
      return _rawFinalizeBundleForAllFields(originalData);
    }
  }

  /// 급여 줄처럼 숫자·라틴 문자만 있는 lo 슬롯 허용(표시용).
  static bool looksLikeLatinSalaryLine(String s) => _isLatinNumericSalaryLike(s);

  /// en/lo에서 한글·쓰레기 토큰 제거 후 빈 슬롯을 안전 문자로 채워 **항상 Firestore 저장 가능**하게 만든다.
  static Map<String, String> finalizeTripleForFirestoreSave(
    Map<String, String> triple,
    String sourceText,
    String fieldKey,
  ) {
    final src = sourceText.trim();
    if (src.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    var ko = (triple['ko'] ?? '').trim();
    var en = (triple['en'] ?? '').trim();
    var lo = (triple['lo'] ?? '').trim();
    if (ko.isEmpty) ko = src;

    String purifyEnLo(String v) {
      var x = v.trim();
      if (translationMapperIsLegacyPendingPhrase(x) ||
          translationMapperIsLegacyEnglishBridgePhrase(x)) {
        x = '';
      }
      return x.replaceAll(RegExp(r'[\u3131-\uD79D]'), '').trim();
    }

    en = purifyEnLo(en);
    lo = purifyEnLo(lo);

    if (en.isEmpty) {
      if (fieldKey == 'salary' &&
          lo.isNotEmpty &&
          !translationMapperContainsHangul(lo) &&
          (_isLatinNumericSalaryLike(lo) || translationMapperHasLaoScript(lo))) {
        en = lo;
      }
    }
    if (en.isEmpty) en = ko;
    if (lo.isEmpty) {
      if (!translationMapperContainsHangul(en) && en.isNotEmpty) {
        if (fieldKey == 'salary') {
          if (_isLatinNumericSalaryLike(en) || translationMapperHasLaoScript(en)) {
            lo = en;
          }
        } else if (translationMapperHasLaoScript(en)) {
          lo = en;
        }
      }
    }
    if (lo.isEmpty) lo = ko;

    if (translationMapperContainsHangul(en)) en = ko;
    if (translationMapperContainsHangul(lo)) lo = ko;

    return {'ko': ko, 'en': en, 'lo': lo};
  }

  /// 재시도 게이트용(완화): en·lo에 한글만 없으면 통과. 라오 문자 강제 없음 — 최종은 [finalizeTripleForFirestoreSave].
  static bool fieldTriplePassesPolicy(
    Map<String, String> triple,
    String sourceText,
    String fieldKey,
  ) {
    final src = sourceText.trim();
    final ko = (triple['ko'] ?? '').trim();
    final en = (triple['en'] ?? '').trim();
    final lo = (triple['lo'] ?? '').trim();
    if (src.isEmpty) {
      return ko.isEmpty && en.isEmpty && lo.isEmpty;
    }
    if (ko.isEmpty || en.isEmpty || lo.isEmpty) return false;
    if (translationMapperContainsHangul(en) || translationMapperContainsHangul(lo)) {
      return false;
    }
    return true;
  }

  /// 저장 직전 (리스트 순서): [title, location, salary, description] 맵.
  static Future<List<Map<String, String>>> translateAll({
    required String title,
    required String location,
    required String salary,
    required String detail,
    required String sourceLanguageCode,
  }) async {
    final r = await translateAllFieldsStrict(
      {
        'title': title,
        'location': location,
        'salary': salary,
        'detail': detail,
      },
      sourceLanguageCode: sourceLanguageCode,
    );
    if (!r.isSuccess || r.bundle == null) {
      throw StateError(r.message ?? 'translation failed');
    }
    final m = r.bundle!;
    return [
      m['title']!,
      m['location']!,
      m['salary']!,
      m['detail']!,
    ];
  }

  /// 자유 텍스트만: 한글이면 원문을 KO로 두고 EN/LO는 중립, 그 외는 UI 로케일 힌트로 폴백.
  static Map<String, String> legacyScalarToTripleForDisplay(
    String raw,
    String uiLanguageCode,
  ) {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    final src = translationMapperContainsHangul(t)
        ? 'ko'
        : _translationMapperLang2(uiLanguageCode);
    return fallbackTripleForText(t, src);
  }

  /// 레거시 `title` 스칼라 → 표시용 triple (리터럴 접두·i18n 키·구문 역매핑).
  static Map<String, String> legacyTitleScalarToDisplayTriple(
    String raw,
    String uiLanguageCode,
  ) {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    if (t.startsWith(kQuickJobLiteralPrefix)) {
      return legacyScalarToTripleForDisplay(
        t.substring(kQuickJobLiteralPrefix.length),
        uiLanguageCode,
      );
    }
    if (_looksLikeI18nKey(t)) {
      return {'ko': t, 'en': t, 'lo': t};
    }
    final key = kQuickJobTitlePhraseToKey[t] ?? kQuickJobTitleLegacyValueToKey[t];
    if (key != null) {
      return {'ko': key, 'en': key, 'lo': key};
    }
    return legacyScalarToTripleForDisplay(t, uiLanguageCode);
  }

  /// 레거시 `loc` 스칼라 → 표시용 triple.
  static Map<String, String> legacyLocationScalarToDisplayTriple(
    String raw,
    String uiLanguageCode,
  ) {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    if (t.startsWith(kQuickJobLiteralPrefix)) {
      return legacyScalarToTripleForDisplay(
        t.substring(kQuickJobLiteralPrefix.length),
        uiLanguageCode,
      );
    }
    if (_looksLikeI18nKey(t)) {
      return {'ko': t, 'en': t, 'lo': t};
    }
    final key = _lookupLocationPhrase(t);
    if (key != null) {
      return {'ko': key, 'en': key, 'lo': key};
    }
    return legacyScalarToTripleForDisplay(t, uiLanguageCode);
  }

  /// 레거시 `salary` 스칼라 → 표시용 triple.
  static Map<String, String> legacySalaryScalarToDisplayTriple(
    String raw,
    String uiLanguageCode,
  ) {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    if (t.startsWith(kQuickJobLiteralPrefix)) {
      return legacyScalarToTripleForDisplay(
        t.substring(kQuickJobLiteralPrefix.length),
        uiLanguageCode,
      );
    }
    if (_looksLikeI18nKey(t)) {
      return {'ko': t, 'en': t, 'lo': t};
    }
    final key = _lookupSalaryPhrase(t);
    if (key != null) {
      return {'ko': key, 'en': key, 'lo': key};
    }
    return legacyScalarToTripleForDisplay(t, uiLanguageCode);
  }

  /// 레거시 `detail` 스칼라 → 표시용 triple.
  static Map<String, String> legacyDetailScalarToDisplayTriple(
    String raw,
    String uiLanguageCode,
  ) {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    if (t.startsWith(kQuickJobLiteralPrefix)) {
      return legacyScalarToTripleForDisplay(
        t.substring(kQuickJobLiteralPrefix.length),
        uiLanguageCode,
      );
    }
    if (_looksLikeI18nKey(t)) {
      return {'ko': t, 'en': t, 'lo': t};
    }
    final key = kQuickJobDetailPhraseToKey[t] ?? kQuickJobDetailLegacyValueToKey[t];
    if (key != null) {
      return {'ko': key, 'en': key, 'lo': key};
    }
    return legacyScalarToTripleForDisplay(t, uiLanguageCode);
  }

  /// v13.7: AI 슬롯 정리 — Pending/브리지 제거, **en·lo에 한글 금지**(복사 금지).
  static Map<String, String> _sanitizeAiTripleStrict(Map<String, String>? m) {
    final o = m ?? {};
    String clean(String v) {
      final s = v.trim();
      if (translationMapperIsLegacyPendingPhrase(s)) return '';
      if (translationMapperIsLegacyEnglishBridgePhrase(s)) return '';
      if (s == kQuickJobNeutralLineEn || s == kQuickJobNeutralLineLo) return '';
      return s;
    }

    var ko = clean(o['ko'] ?? '');
    var en = clean(o['en'] ?? '');
    var lo = clean(o['lo'] ?? '');
    if (translationMapperContainsHangul(en)) en = '';
    if (translationMapperContainsHangul(lo)) lo = '';
    return {'ko': ko, 'en': en, 'lo': lo};
  }

  static Future<Map<String, String>> _translateOneField({
    required String text,
    required String sourceLang,
  }) async {
    if (text.trim().isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    final src = _translationMapperLang2(sourceLang);
    try {
      Future<String?> toTarget(String target) async {
        if (src == target) return text;
        return _callTranslateApi(text: text, source: src, target: target);
      }

      final koText = src == 'ko' ? text : (await toTarget('ko')) ?? text;
      final enResult = src == 'en' ? text : (await toTarget('en'));
      final loResult = src == 'lo' ? text : (await toTarget('lo'));

      return {
        'ko': koText,
        'en': enResult ?? text,
        'lo': loResult ?? text,
      };
    } on _GeminiNoRetryException {
      rethrow;
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranslationMapper: 단일 필드 번역 예외 → 원문 트리플: $e');
        debugPrint('$st');
      }
      return {'ko': text, 'en': text, 'lo': text};
    }
  }

  static Future<String?> _callTranslateApi({
    required String text,
    required String source,
    required String target,
  }) async {
    try {
      final apiKey = _translateApiKeyValue();
      if (apiKey.isEmpty) {
        if (kDebugMode) {
          debugPrint('TranslationMapper: Translate API 키 없음 → 호출 생략');
        }
        return null;
      }
      final uri = Uri.parse('$_translateEndpoint?key=$apiKey');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': text,
              'source': source,
              'target': target,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final translations = data?['data']?['translations'] as List<dynamic>?;
        final translated = translations?.isNotEmpty == true
            ? translations!.first['translatedText'] as String?
            : null;
        if (kDebugMode) {
          debugPrint('TranslationMapper: 번역 성공 [$source→$target]: $translated');
        }
        return translated;
      }

      if (response.statusCode == 403 || response.statusCode == 429) {
        throw _GeminiNoRetryException(response.statusCode);
      }

      if (kDebugMode) {
        debugPrint('TranslationMapper: 번역 HTTP 에러: ${response.statusCode}');
      }
      _logHttpError(response);
      return null;
    } on _GeminiNoRetryException {
      rethrow;
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranslationMapper: 번역 호출 에러: $e');
        debugPrint('$st');
      }
      return null;
    }
  }

  /// 네 필드에 대해 [Translation API v2](https://translation.googleapis.com/language/translate/v2)
  /// 로 ko/en/lo 삼중 맵을 채운다. 각 HTTP 호출은 `_callTranslateApi`의 10초 타임아웃을 쓴다.
  /// 403/429는 재시도 없이 상위로 전달; 그 외 실패·예외 시 `null` (원문은
  /// [translateAllFieldsStrict] 후처리에서 보정).
  static Future<Map<String, Map<String, String>>?> _translateBatchAllFourFields(
    Map<String, String> originalData, {
    required String sourceLanguageCode,
  }) async {
    try {
      final result = <String, Map<String, String>>{};

      for (final entry in originalData.entries) {
        final fieldKey = entry.key;
        final raw = entry.value.trim();

        if (raw.isEmpty) {
          result[fieldKey] = {'ko': '', 'en': '', 'lo': ''};
          continue;
        }

        // GOOGLE_TRANSLATE_API_KEY + v2 엔드포인트 (_translateOneField → _callTranslateApi)
        final triple = await _translateOneField(
          text: raw,
          sourceLang: sourceLanguageCode,
        );

        result[fieldKey] = triple;
      }

      return result;
    } on _GeminiNoRetryException {
      rethrow;
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranslationMapper: 배치 번역 에러: $e');
        debugPrint('$st');
      }
      return null;
    }
  }

  static void _logHttpError(http.Response resp) {
    if (!kDebugMode) return;
    var detail = resp.body;
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['error'] != null) {
        detail = jsonEncode(j['error']);
      }
    } catch (_) {}
    debugPrint('TranslationMapper: HTTP ${resp.statusCode} — $detail');
  }
}

class _GeminiNoRetryException implements Exception {
  const _GeminiNoRetryException(this.statusCode);
  final int statusCode;
}


