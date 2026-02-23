import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LT-08 미션01: 다크 모드를 기본 옵션으로 준비.
/// 테마 모드(라이트/다크/시스템) 저장·복원. 지사 인계용 주석 유지.
class ThemeService {
  static const String _keyThemeMode = 'laotrust_theme_mode';

  /// 저장된 테마 모드 복원. 미저장 시 [ThemeMode.dark] 반환(기본 옵션).
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyThemeMode);
    if (index == null) return ThemeMode.dark;
    if (index == 0) return ThemeMode.light;
    if (index == 1) return ThemeMode.dark;
    return ThemeMode.system;
  }

  /// 테마 모드 저장.
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final index = mode == ThemeMode.light
        ? 0
        : mode == ThemeMode.dark
            ? 1
            : 2;
    await prefs.setInt(_keyThemeMode, index);
  }
}
