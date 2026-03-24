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

bool _loSlotDisplayable(String lo) {
  final t = lo.trim();
  if (t.isEmpty || quickJobStringContainsHangul(t)) return false;
  return translationMapperHasLaoScript(t) || TranslationMapper.looksLikeLatinSalaryLine(t);
}

/// UI 표시: v13.7 라오/영어 모드에서 **한글 미노출** 우선.
String pickQuickJobI18nLine(
  Map<String, dynamic>? m,
  String localeLanguageCode,
) {
  if (m == null || m.isEmpty) return '';
  final lang = _lang2(localeLanguageCode);
  if (lang == 'ko') {
    var v = (m['ko'] ?? m['en'] ?? m['lo'] ?? '').toString().trim();
    if (v.isEmpty) return '';
    if (translationMapperIsLegacyPendingPhrase(v) ||
        translationMapperIsLegacyEnglishBridgePhrase(v)) {
      v = (m['en'] ?? m['lo'] ?? m['ko'] ?? '').toString().trim();
    }
    return v;
  }
  if (lang == 'lo') {
    final lo = (m['lo'] ?? '').toString().trim();
    if (_loSlotDisplayable(lo)) return lo;
    final en = (m['en'] ?? '').toString().trim();
    if (en.isNotEmpty && !quickJobStringContainsHangul(en)) return en;
    return TranslationMapper.neutralCaptionForLangCode('lo');
  }
  final en = (m['en'] ?? '').toString().trim();
  if (en.isNotEmpty && !quickJobStringContainsHangul(en)) return en;
  final lo = (m['lo'] ?? '').toString().trim();
  if (_loSlotDisplayable(lo)) return lo;
  return TranslationMapper.neutralCaptionForLangCode('en');
}

/// 카드/모달용: i18n 키는 [t]로 풀고, v13.7 EN/LO에서 한글 숨김.
String pickQuickJobI18nForDisplay(
  Map<String, dynamic>? m,
  String localeLanguageCode,
  BuildContext context,
) {
  if (m == null || m.isEmpty) return '';
  final lang = _lang2(localeLanguageCode);
  if (lang == 'ko') {
    var raw = (m['ko'] ?? m['en'] ?? m['lo'] ?? '').toString().trim();
    if (raw.isEmpty) return '';
    if (translationMapperIsLegacyPendingPhrase(raw) ||
        translationMapperIsLegacyEnglishBridgePhrase(raw)) {
      raw = (m['en'] ?? m['lo'] ?? m['ko'] ?? '').toString().trim();
    }
    if (raw.isEmpty) return '';
    return quickJobLooksLikeI18nStorageKey(raw) ? context.t(raw) : raw;
  }
  if (lang == 'lo') {
    final lo = (m['lo'] ?? '').toString().trim();
    if (_loSlotDisplayable(lo)) {
      final v = quickJobLooksLikeI18nStorageKey(lo) ? context.t(lo) : lo;
      if (!quickJobStringContainsHangul(v)) return v;
    }
    final en = (m['en'] ?? '').toString().trim();
    if (en.isNotEmpty && !quickJobStringContainsHangul(en)) {
      return quickJobLooksLikeI18nStorageKey(en) ? context.t(en) : en;
    }
    return TranslationMapper.neutralCaptionForLangCode('lo');
  }
  final en = (m['en'] ?? '').toString().trim();
  if (en.isNotEmpty && !quickJobStringContainsHangul(en)) {
    return quickJobLooksLikeI18nStorageKey(en) ? context.t(en) : en;
  }
  final lo = (m['lo'] ?? '').toString().trim();
  if (_loSlotDisplayable(lo)) {
    final v = quickJobLooksLikeI18nStorageKey(lo) ? context.t(lo) : lo;
    if (!quickJobStringContainsHangul(v)) return v;
  }
  return TranslationMapper.neutralCaptionForLangCode('en');
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
  var ko = (m['ko'] ?? '').trim();
  var en = (m['en'] ?? '').trim();
  var lo = (m['lo'] ?? '').trim();

  bool badEn(String s) =>
      translationMapperIsLegacyPendingPhrase(s) ||
      translationMapperIsLegacyEnglishBridgePhrase(s) ||
      s == kQuickJobNeutralLineEn;
  bool badLo(String s) =>
      translationMapperIsLegacyPendingPhrase(s) ||
      translationMapperIsLegacyEnglishBridgePhrase(s) ||
      s == kQuickJobNeutralLineLo;

  if (badEn(en) && ko.isNotEmpty) en = ko;
  if (badLo(lo) && ko.isNotEmpty) lo = ko;
  if (badEn(en) && en.isEmpty && lo.isNotEmpty) en = lo;
  if (badLo(lo) && lo.isEmpty && en.isNotEmpty) lo = en;
  if (quickJobStringContainsHangul(lo) && en.isNotEmpty && !quickJobStringContainsHangul(en)) {
    lo = en;
  }
  if (quickJobStringContainsHangul(en) && lo.isNotEmpty && !quickJobStringContainsHangul(lo)) {
    en = lo;
  }
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
