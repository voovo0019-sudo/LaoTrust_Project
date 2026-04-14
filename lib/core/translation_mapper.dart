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

