// =============================================================================
// LT-08 미션04: 언어 금고 — 로케일 저장/복원 및 JSON 경로 (지사 인계용 전략 주석)
// =============================================================================
// 역할: 한국어(ko), 영어(en), 라오어(lo) 3개국어 코드와 assets 경로 관리.
// 버튼 하나로 스위칭 시 이 서비스로 저장하고, 앱에서 locale 재적용 후 문자열 재로드.
// 지사 인계 시: 새 언어 추가 시 supportedLocales와 여기 경로만 추가하면 됨.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyLocale = 'laotrust_locale';

/// 지원 로케일: 한국어, 영어, 라오어.
const List<Locale> supportedLocales = [
  Locale('ko'),
  Locale('en'),
  Locale('lo'),
];

/// 저장된 로케일 복원. 없으면 [Locale('ko')].
Future<Locale> getSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_keyLocale) ?? 'ko';
  return Locale(code);
}

/// 로케일 저장. 스위칭 시 호출.
Future<void> saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyLocale, locale.languageCode);
}

/// assets/i18n/{code}.json 경로. 지사 인계 시 JSON 키 추가는 동일 파일에 키만 추가.
String localeToAssetPath(String languageCode) {
  return 'assets/i18n/$languageCode.json';
}

/// 해당 로케일의 언어팩(Map) 로드. 실패 시 빈 맵 반환.
Future<Map<String, String>> loadStringsForLocale(Locale locale) async {
  try {
    final path = localeToAssetPath(locale.languageCode);
    final json = await rootBundle.loadString(path);
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  } catch (_) {
    return {};
  }
}
