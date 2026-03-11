// =============================================================================
// LT-08 미션04: 앱 전역 문자열 제공 — 언어 금고에서 로드한 맵을 트리에 주입 (지사 인계용 전략 주석)
// =============================================================================
// 역할: L10n.s(context, 'key') 형태로 현재 로케일의 문자열 반환.
// 키가 맵에 없으면 한국어 폴백 사용 → 시연 시 영어 코드명 노출 방지 (작전 무결성).
// =============================================================================

import 'package:flutter/material.dart';

/// 번역 키 미존재 시 사용할 한국어 폴백 (영어 코드명 노출 방지)
const Map<String, String> _kFallbackKo = {
  'sub_cleaning_move_in': '이사/입주',
  'sub_cleaning_commercial': '상업공간',
  'sub_cleaning_appliance': '가전청소',
  'sub_cleaning_bedding': '침구세척',
  'sub_cleaning_regular_visit': '정기 방문(주/월)',
  'sub_security_building': '건물·상가(장기)',
  'sub_security_site': '공사장·창고',
  'sub_security_vip': 'VIP 경호',
  'sub_security_event': '단기 행사 보안',
  'sub_delivery_food': '음식 배달',
  'sub_delivery_cargo': '소형 화물',
  'sub_delivery_mart': '마트 장보기 대행',
  'sub_beauty_general': '일반 뷰티/헬스',
  'sub_tutor_lang': '언어(한/라/영)',
  'sub_tutor_it': 'IT/코딩',
  'sub_tutor_music': '음악',
  'sub_photo_studio': '스튜디오 촬영',
  'sub_photo_event': '이벤트 촬영',
  'sub_event_catering': '케이터링',
  'sub_event_deco': '장식/데코',
  'sub_event_mc': '사회자',
  'sub_event_sound': '음향 장비 렌탈',
  'sub_garden_lawn': '잔디 깎기',
  'sub_garden_trim': '가지치기',
  'sub_garden_pest': '해충 및 살충 방역',
  'job_title_event_staff': '행사 스태프',
  'job_title_logistics': '물류 보조',
  'job_title_promotion': '판촉 홍보',
  'job_detail_event_staff': '행사 현장 스태프, 통역 보조 가능',
  'job_detail_logistics': '창고/물류 보조 작업',
  'job_detail_promotion': '판촉·홍보 알바',
  'job_detail_location': '위치',
  'job_detail_salary': '급여',
  'job_detail_description': '상세 내용',
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
  String l10n(String key) =>
      AppLocalizations.of(this)?.s(key) ?? _kFallbackKo[key] ?? key;
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
