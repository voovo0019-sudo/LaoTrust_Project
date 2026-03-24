// =============================================================================
// v10.1 급구 알바: 저장/표시 변환 레이어 (TranslationMapper)
// DB에는 i18n 키 또는 __lt_literal__: 접두 + 원문만 둔다. 표시는 t() + 원문 폴백.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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

bool translationMapperContainsHangul(String s) =>
    RegExp(r'[\u3131-\uD79D]').hasMatch(s);

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

/// 급구 필드 4개 일괄 번역 → Firestore용 맵 리스트 [title, location, salary, detail].
class TranslationMapper {
  TranslationMapper._();

  /// Google AI Studio / generativelanguage REST에서 안정적으로 동작하는 Flash 모델.
  static const String _geminiModel = 'gemini-2.0-flash';
  static const String _geminiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const Duration _perFieldGeminiTimeout = Duration(seconds: 2);

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

  /// 단일 필드 폴백 (API 없음·실패). Pending 문구 없음.
  static Map<String, String> fallbackTripleForText(
    String raw,
    String sourceLanguageCode,
  ) {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    final src = _translationMapperLang2(sourceLanguageCode);
    final hasH = translationMapperContainsHangul(t);
    if (hasH) {
      return {
        'ko': t,
        'en': kQuickJobNeutralLineEn,
        'lo': kQuickJobNeutralLineLo,
      };
    }
    switch (src) {
      case 'en':
        return {
          'ko': kQuickJobNeutralLineKo,
          'en': t,
          'lo': kQuickJobNeutralLineLo,
        };
      case 'lo':
        return {
          'ko': kQuickJobNeutralLineKo,
          'en': kQuickJobNeutralLineEn,
          'lo': t,
        };
      default:
        return {
          'ko': t,
          'en': t,
          'lo': kQuickJobNeutralLineLo,
        };
    }
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

  /// v13.3: 제목·장소·급여·상세 각각 Gemini로 KO/EN/LO 맵 생성 (필드별 병렬 호출).
  ///
  /// [originalData] 키: `title`, `location`, `salary`, `detail`
  /// 결과: `{ "title": {"ko","en","lo"}, "location": {...}, ... }`
  static Future<Map<String, Map<String, String>>> translateAllFields(
    Map<String, String> originalData, {
    required String sourceLanguageCode,
  }) async {
    const keys = ['title', 'location', 'salary', 'detail'];
    if (_geminiKey.isEmpty) {
      return {
        for (final k in keys)
          k: fallbackTripleForText(originalData[k] ?? '', sourceLanguageCode),
      };
    }
    final list = await Future.wait(
      keys.map(
        (k) => _translateOneFieldToTriple(
          fieldKey: k,
          text: originalData[k] ?? '',
          sourceLanguageCode: sourceLanguageCode,
        ),
      ),
    );
    return {for (var i = 0; i < keys.length; i++) keys[i]: list[i]};
  }

  static Future<Map<String, String>> _translateOneFieldToTriple({
    required String fieldKey,
    required String text,
    required String sourceLanguageCode,
  }) async {
    final t = text.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    try {
      final got = await _geminiSingleFieldTriple(
        fieldKey: fieldKey,
        text: t,
        sourceLanguageCode: sourceLanguageCode,
      ).timeout(_perFieldGeminiTimeout);
      if (got != null) {
        final sanitized = _sanitizeTripleNoHangulEnLo(got);
        if (t.isNotEmpty &&
            (sanitized['ko'] ?? '').isEmpty &&
            (sanitized['en'] ?? '').isEmpty &&
            (sanitized['lo'] ?? '').isEmpty) {
          return fallbackTripleForText(t, sourceLanguageCode);
        }
        return sanitized;
      }
    } catch (_) {}
    return fallbackTripleForText(t, sourceLanguageCode);
  }

  /// 저장 직전 (리스트 순서): [title, location, salary, description] 맵.
  static Future<List<Map<String, String>>> translateAll({
    required String title,
    required String location,
    required String salary,
    required String detail,
    required String sourceLanguageCode,
  }) async {
    final m = await translateAllFields(
      {
        'title': title,
        'location': location,
        'salary': salary,
        'detail': detail,
      },
      sourceLanguageCode: sourceLanguageCode,
    );
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

  static Map<String, String> _sanitizeTripleNoHangulEnLo(Map<String, String>? m) {
    final o = m ?? {'ko': '', 'en': '', 'lo': ''};
    String stripPending(String slot, String v) {
      final s = v.trim();
      if (translationMapperIsLegacyPendingPhrase(s)) {
        switch (slot) {
          case 'en':
            return kQuickJobNeutralLineEn;
          case 'lo':
            return kQuickJobNeutralLineLo;
          default:
            return kQuickJobNeutralLineKo;
        }
      }
      return s;
    }

    var ko = stripPending('ko', o['ko'] ?? '');
    var en = stripPending('en', o['en'] ?? '');
    var lo = stripPending('lo', o['lo'] ?? '');
    if (translationMapperContainsHangul(en)) en = kQuickJobNeutralLineEn;
    if (translationMapperContainsHangul(lo)) lo = kQuickJobNeutralLineLo;
    return {'ko': ko, 'en': en, 'lo': lo};
  }

  static Future<Map<String, String>?> _geminiSingleFieldTriple({
    required String fieldKey,
    required String text,
    required String sourceLanguageCode,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiKey',
    );
    final prompt =
        'You translate a single job listing field for a multilingual app. '
        'Field name: ${jsonEncode(fieldKey)}. '
        'Return ONLY valid JSON (no markdown): {"ko":"","en":"","lo":""}. '
        'ko=Korean, en=English, lo=Lao script. '
        'Source locale hint: ${_translationMapperLang2(sourceLanguageCode)}.\n'
        'Text:\n${jsonEncode(text)}';
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
    });
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>?;
    final candidates = decoded?['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;
    final content = candidates.first as Map<String, dynamic>?;
    final parts = content?['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    final rawOut =
        (parts.first as Map<String, dynamic>)['text']?.toString() ?? '';
    final jsonStr = _translationMapperExtractJson(rawOut);
    if (jsonStr == null) return null;
    final root = jsonDecode(jsonStr) as Map<String, dynamic>?;
    if (root == null) return null;
    return {
      'ko': root['ko']?.toString().trim() ?? '',
      'en': root['en']?.toString().trim() ?? '',
      'lo': root['lo']?.toString().trim() ?? '',
    };
  }

  static String? _translationMapperExtractJson(String text) {
    var t = text.trim();
    if (t.contains('```')) {
      final i = t.indexOf('{');
      final j = t.lastIndexOf('}');
      if (i >= 0 && j > i) t = t.substring(i, j + 1);
    }
    final start = t.indexOf('{');
    final end = t.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return t.substring(start, end + 1);
  }
}
