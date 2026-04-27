// =============================================================================
// LaoTrust — ThemeProvider
// 앱 전역 테마 상태 관리 (light/dark)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme_service.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> setThemeMode(ThemeMode mode) async {
    await ThemeService.setThemeMode(mode);
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
