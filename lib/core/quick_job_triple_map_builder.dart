// =============================================================================
// v12.0 급구 알바: 맵 힐링·UI 픽 (AI·translateAll은 translation_mapper.dart)
// =============================================================================

import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'translation_mapper.dart';

bool quickJobStringContainsHangul(String s) => translationMapperContainsHangul(s);

bool quickJobLooksLikeI18nStorageKey(String s) {
  final t = s.trim();
  return t.startsWith('quick_job_') ||
      t.startsWith('job_') ||
      t.startsWith('location_') ||
      t.startsWith('salary_');
}

String _lang2(String? code) {
  if (code == null || code.isEmpty) return 'en';
  final c = code.toLowerCase();
  if (c.startsWith('ko')) return 'ko';
  if (c.startsWith('lo')) return 'lo';
  return 'en';
}

/// UI 표시: [m]에서 현재 언어 값 선택. EN/LO에서 한글·레거시 Pending 금지.
String pickQuickJobI18nLine(
  Map<String, dynamic>? m,
  String localeLanguageCode,
) {
  if (m == null || m.isEmpty) return '';
  final lang = _lang2(localeLanguageCode);
  String v = (m[lang] ?? m['en'] ?? m['ko'] ?? m['lo'] ?? '').toString().trim();
  if (v.isEmpty) return '';
  if (translationMapperIsLegacyPendingPhrase(v)) {
    return TranslationMapper.neutralCaptionForLangCode(lang);
  }
  if (lang == 'ko') return v;
  if (quickJobStringContainsHangul(v)) {
    return TranslationMapper.neutralCaptionForLangCode(lang);
  }
  return v;
}

/// 카드/모달용: i18n 키는 [t]로 풀고, EN/LO에서 한글·Pending 미노출.
String pickQuickJobI18nForDisplay(
  Map<String, dynamic>? m,
  String localeLanguageCode,
  BuildContext context,
) {
  if (m == null || m.isEmpty) return '';
  final lang = _lang2(localeLanguageCode);
  var raw = (m[lang] ?? m['en'] ?? m['ko'] ?? m['lo'] ?? '').toString().trim();
  if (raw.isEmpty) return '';
  if (translationMapperIsLegacyPendingPhrase(raw)) {
    return TranslationMapper.neutralCaptionForLangCode(lang);
  }
  var v = quickJobLooksLikeI18nStorageKey(raw) ? context.t(raw) : raw;
  if (translationMapperIsLegacyPendingPhrase(v)) {
    return TranslationMapper.neutralCaptionForLangCode(lang);
  }
  if (lang == 'ko') return v;
  if (quickJobStringContainsHangul(v)) {
    return TranslationMapper.neutralCaptionForLangCode(lang);
  }
  return v;
}

Map<String, String> _normalizeIncomingMap(dynamic raw) {
  final out = <String, String>{'ko': '', 'en': '', 'lo': ''};
  if (raw is! Map) return out;
  for (final e in raw.entries) {
    final k = e.key.toString().toLowerCase();
    if (k == 'ko' || k == 'en' || k == 'lo') {
      out[k] = e.value?.toString().trim() ?? '';
    }
  }
  return out;
}

Map<String, String> _sanitizeStoredTriple(Map<String, String> m) {
  var ko = m['ko'] ?? '';
  var en = m['en'] ?? '';
  var lo = m['lo'] ?? '';
  if (translationMapperIsLegacyPendingPhrase(en)) en = kQuickJobNeutralLineEn;
  if (translationMapperIsLegacyPendingPhrase(lo)) lo = kQuickJobNeutralLineLo;
  if (quickJobStringContainsHangul(en)) en = kQuickJobNeutralLineEn;
  if (quickJobStringContainsHangul(lo)) lo = kQuickJobNeutralLineLo;
  return {'ko': ko, 'en': en, 'lo': lo};
}

/// Fetch 직후: Firestore 값 → {ko,en,lo} (레거시 String·Map·Pending 문구 힐링).
Map<String, String> healQuickJobI18nField(dynamic field) {
  if (field == null) {
    return {'ko': '', 'en': '', 'lo': ''};
  }
  if (field is Map) {
    return _sanitizeStoredTriple(_normalizeIncomingMap(field));
  }
  final s = field.toString().trim();
  if (s.isEmpty) {
    return {'ko': '', 'en': '', 'lo': ''};
  }
  const p = '__lt_literal__:';
  final text = s.startsWith(p) ? s.substring(p.length) : s;

  if (quickJobLooksLikeI18nStorageKey(text)) {
    return {'ko': text, 'en': text, 'lo': text};
  }
  return TranslationMapper.fallbackTripleForText(text, 'ko');
}

/// 오프라인 등: [TranslationMapper.fallbackTripleForText] 별칭.
class QuickJobTripleMapBuilder {
  QuickJobTripleMapBuilder._();

  static Map<String, String> policyTripleFallback(
    String raw,
    String sourceLanguageCode,
  ) =>
      TranslationMapper.fallbackTripleForText(raw, sourceLanguageCode);
}
