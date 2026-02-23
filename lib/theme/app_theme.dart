import 'package:flutter/material.dart';

/// LT-10 디지털 캡슐 v1.5 · 인디고 블루(#3F51B5) 전역 테마 고정
/// Global Indigo Blue theme engine. 한/영 주석 병기.
class AppTheme {
  /// 전역 고정 Primary (LT-10 명시) / Global primary color
  static const Color indigoBlue = Color(0xFF3F51B5);
  static const Color indigoBlueLight = Color(0xFF5C6BC0);

  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE8E8E8);

  /// 라이트: #3F51B5 전역 고정 / Light theme
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: indigoBlue,
        onPrimary: white,
        surface: surfaceLight,
        onSurface: onSurfaceLight,
        surfaceContainerHighest: const Color(0xFFEEEEEE),
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: indigoBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  /// 다크: #3F51B5 Primary 유지 / Dark theme
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: indigoBlue,
        onPrimary: white,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: onSurfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
