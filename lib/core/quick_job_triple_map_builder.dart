// =============================================================================
// v10.8 급구 알바: KO/EN/LO Triple-Map + AI(선택) + No-Korean(en/lo) 정책
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_localizations.dart';

/// AI 실패·미설정 시 EN/LO에 쓰는 공용 영어 (지시서 v10.6/v10.8).
const String kQuickJobPendingTranslationEn = 'Pending translation';

const Duration _kAiTimeout = Duration(seconds: 2);

const String _kGeminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

bool quickJobStringContainsHangul(String s) =>
    RegExp(r'[\u3131-\uD79D]').hasMatch(s);

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

/// UI 표시: [m]에서 현재 언어 값 선택. EN/LO 모드에서 한글 생노출 차단.
String pickQuickJobI18nLine(
  Map<String, dynamic>? m,
  String localeLanguageCode,
) {
  if (m == null || m.isEmpty) return '';
  final lang = _lang2(localeLanguageCode);
  String v = (m[lang] ?? m['en'] ?? m['ko'] ?? m['lo'] ?? '').toString().trim();
  if (v.isEmpty) return '';
  if (lang == 'ko') return v;
  if (quickJobStringContainsHangul(v)) {
    return kQuickJobPendingTranslationEn;
  }
  return v;
}

/// 카드/모달용: 맵 값이 i18n 키면 [t]로 풀고, EN/LO에서 결과에 한글이 남으면 Pending.
String pickQuickJobI18nForDisplay(
  Map<String, dynamic>? m,
  String localeLanguageCode,
  BuildContext context,
) {
  if (m == null || m.isEmpty) return '';
  final lang = _lang2(localeLanguageCode);
  var raw = (m[lang] ?? m['en'] ?? m['ko'] ?? m['lo'] ?? '').toString().trim();
  if (raw.isEmpty) return '';
  var v = quickJobLooksLikeI18nStorageKey(raw) ? context.t(raw) : raw;
  if (lang == 'ko') return v;
  if (quickJobStringContainsHangul(v)) return kQuickJobPendingTranslationEn;
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

/// Fetch 직후: Firestore 값 → 항상 {ko,en,lo} (레거시 String·Map 힐링).
Map<String, String> healQuickJobI18nField(dynamic field) {
  if (field == null) {
    return {'ko': '', 'en': '', 'lo': ''};
  }
  if (field is Map) {
    return _sanitizeTripleStatic(_normalizeIncomingMap(field));
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
  final hasH = quickJobStringContainsHangul(text);
  return {
    'ko': text,
    'en': hasH ? kQuickJobPendingTranslationEn : text,
    'lo': hasH ? kQuickJobPendingTranslationEn : text,
  };
}

Map<String, String> _sanitizeTripleStatic(Map<String, String> m) {
  final ko = m['ko'] ?? '';
  var en = m['en'] ?? '';
  var lo = m['lo'] ?? '';
  if (quickJobStringContainsHangul(en)) en = kQuickJobPendingTranslationEn;
  if (quickJobStringContainsHangul(lo)) lo = kQuickJobPendingTranslationEn;
  return {'ko': ko, 'en': en, 'lo': lo};
}

/// 저장 시: 원문 + 앱 언어 소스 → KO/EN/LO 맵 (2초 AI → 실패 시 정책 폴백).
class QuickJobTripleMapBuilder {
  QuickJobTripleMapBuilder._();

  /// 오프라인·즉시용: AI 없이 v10.8 No-Korean 정책 폴백만 적용.
  static Map<String, String> policyTripleFallback(String raw, String sourceLanguageCode) {
    final t = raw.trim();
    if (t.isEmpty) return {'ko': '', 'en': '', 'lo': ''};
    return _policyFallback(t, _lang2(sourceLanguageCode));
  }

  static Future<Map<String, String>> build(
    String raw, {
    required String sourceLanguageCode,
  }) async {
    final t = raw.trim();
    if (t.isEmpty) {
      return {'ko': '', 'en': '', 'lo': ''};
    }
    final src = _lang2(sourceLanguageCode);

    if (_kGeminiKey.isEmpty) {
      return _policyFallback(t, src);
    }
    try {
      final ai = await _geminiTripleJson(t).timeout(_kAiTimeout);
      if (ai != null) {
        return _sanitizeTripleStatic(ai);
      }
    } catch (_) {}
    return _policyFallback(t, src);
  }

  static Map<String, String> _policyFallback(String t, String sourceLang) {
    final hasH = quickJobStringContainsHangul(t);
    if (hasH) {
      return {
        'ko': t,
        'en': kQuickJobPendingTranslationEn,
        'lo': kQuickJobPendingTranslationEn,
      };
    }
    switch (sourceLang) {
      case 'en':
        return {
          'ko': kQuickJobPendingTranslationEn,
          'en': t,
          'lo': kQuickJobPendingTranslationEn,
        };
      case 'lo':
        return {
          'ko': kQuickJobPendingTranslationEn,
          'en': kQuickJobPendingTranslationEn,
          'lo': t,
        };
      default:
        return {
          'ko': t,
          'en': t,
          'lo': kQuickJobPendingTranslationEn,
        };
    }
  }

  static Future<Map<String, String>?> _geminiTripleJson(String userText) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_kGeminiKey',
    );
    final prompt =
        'You translate short job listing snippets. Return ONLY valid JSON with keys ko,en,lo (strings). '
        'ko=Korean, en=English, lo=Lao script. No markdown, no explanation.\n'
        'Input:\n${jsonEncode(userText)}';
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
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
    final text = (parts.first as Map<String, dynamic>)['text']?.toString() ?? '';
    final jsonStr = _extractJsonObject(text);
    if (jsonStr == null) return null;
    final map = jsonDecode(jsonStr) as Map<String, dynamic>?;
    if (map == null) return null;
    return _normalizeIncomingMap(map);
  }

  static String? _extractJsonObject(String text) {
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
