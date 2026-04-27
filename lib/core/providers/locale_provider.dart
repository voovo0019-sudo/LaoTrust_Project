// =============================================================================
// LaoTrust — LocaleProvider
// 앱 전역 언어 상태 관리 (ko/en/lo)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../locale_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ko');

  Future<void> setLocale(Locale locale) async {
    await saveLocale(locale);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
