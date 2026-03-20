// =============================================================================
// LT-08 미션04: 앱 전역 문자열 제공 — 언어 금고에서 로드한 맵을 트리에 주입 (지사 인계용 전략 주석)
// =============================================================================
// 역할: L10n.s(context, 'key') 형태로 현재 로케일의 문자열 반환.
// 키가 맵에 없으면 한국어 폴백 사용 → 시연 시 영어 코드명 노출 방지 (작전 무결성).
// =============================================================================

import 'package:flutter/material.dart';

/// JSON 로드 실패·웹 캐시 등으로 맵이 비어도 `quick_job_dyn_*` 키가 그대로 노출되지 않도록 한국어 폴백.
const Map<String, String> _kFallbackKo = {
  'quick_job_dyn_event': '행사',
  'quick_job_dyn_delivery': '배달',
  'quick_job_dyn_cleaning': '청소',
  'quick_job_dyn_repair': '수리',
  'quick_job_dyn_security': '경비',
  'quick_job_dyn_tutoring': '과외',
  'quick_job_dyn_beauty': '뷰티',
  'quick_job_dyn_photo': '사진',
  'quick_job_dyn_garden': '정원/외부관리',
  'quick_job_dyn_desc_order': '질서 유지',
  'status': '상태',
  'location': '장소',
  'salary': '급여',
  'detail': '업무 상세',
};

class AppLocalizations {
  const AppLocalizations._({required this.locale, required this.data});
  final Locale locale;
  final Map<String, String> data;

  static AppLocalizations? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppLocalizationsInherited>()?.data;
  }

  /// 번역 반환. 맵에 없으면 한국어 폴백으로 코드명 노출 방지.
  String s(String key) => data[key] ?? _kFallbackKo[key] ?? key;
}

/// 지사 인계용: context.l10n('key') — 번역 없으면 한국어 폴백, 코드명 노출 방지.
extension L10nContext on BuildContext {
  String l10n(String key) {
    final loc = AppLocalizations.of(this);
    if (loc != null) return loc.s(key);
    return _kFallbackKo[key] ?? key;
  }

  /// v6.3 directive alias: enforce `t('key')` usage in UI.
  String t(String key) => l10n(key);
}

class _AppLocalizationsInherited extends InheritedWidget {
  const _AppLocalizationsInherited({required this.data, required super.child});
  final AppLocalizations data;

  @override
  bool updateShouldNotify(_AppLocalizationsInherited old) =>
      old.data.locale != data.locale || old.data.data != data.data;
}

/// 위젯 트리에 언어팩 제공. MaterialApp builder에서 루트에 감싼다.
class AppLocalizationsScope extends StatelessWidget {
  const AppLocalizationsScope({
    super.key,
    required this.locale,
    required this.strings,
    required this.child,
  });
  final Locale locale;
  final Map<String, String> strings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AppLocalizationsInherited(
      data: AppLocalizations._(locale: locale, data: strings),
      child: child,
    );
  }
}
