// =============================================================================
// LT-08 미션04: 앱 전역 문자열 제공 — 언어 금고에서 로드한 맵을 트리에 주입 (지사 인계용 전략 주석)
// =============================================================================
// 역할: L10n.s(context, 'key') 형태로 현재 로케일의 문자열 반환. 키 없으면 키 그대로 반환.
// 지사 인계 시: 새 화면 추가 시 ko/en/lo.json에 동일 키로 문자열만 추가하면 됨.
// =============================================================================

import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations._({required this.locale, required this.data});
  final Locale locale;
  final Map<String, String> data;

  static AppLocalizations? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppLocalizationsInherited>()?.data;
  }

  String s(String key) => data[key] ?? key;
}

/// 지사 인계용: context.l10n('key') 로 간단 호출.
extension L10nContext on BuildContext {
  String l10n(String key) => AppLocalizations.of(this)?.s(key) ?? key;
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
