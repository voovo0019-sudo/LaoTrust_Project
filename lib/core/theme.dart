// =============================================================================
// LT-10 디지털 캡슐 v1.5 · 인디고 블루(#3F51B5) 전역 테마
// lib/core/theme.dart — 핵심 테마 엔진. 한/영 주석 병기.
// Noto Sans + Noto Sans Lao (google_fonts) — 라오 문자 폴백.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 전역 고정 Primary (LT-10 명시) / Global primary color
class AppTheme {
  static const Color indigoBlue = Color(0xFF3F51B5);
  static const Color indigoBlueLight = Color(0xFF5C6BC0);

  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE8E8E8);

  /// google_fonts가 등록한 Noto Sans Lao 패밀리명 (하드코딩 대신 폰트 로더와 일치).
  static List<String> get notoSansLaoFallback {
    final f = GoogleFonts.notoSansLao().fontFamily;
    return f == null ? const [] : [f];
  }

  /// 라오 UI 모드용: Noto Sans Lao를 본문에 우선 적용할 때 사용.
  static TextStyle get textStyleLaoPrimary => GoogleFonts.notoSansLao();

  /// 라이트: #3F51B5 전역 고정 / Light theme
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: indigoBlue,
        onPrimary: white,
        surface: surfaceLight,
        onSurface: onSurfaceLight,
        surfaceContainerHighest: Color(0xFFEEEEEE),
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: indigoBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
    );
    final sans = GoogleFonts.notoSans().fontFamily!;
    final sansLao = GoogleFonts.notoSansLao().fontFamily!;
    return base.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme).apply(
        fontFamily: sans,
        fontFamilyFallback: [sansLao],
      ),
    );
  }

  /// 다크: #3F51B5 Primary 유지 / Dark theme
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
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
    final sans = GoogleFonts.notoSans().fontFamily!;
    final sansLao = GoogleFonts.notoSansLao().fontFamily!;
    return base.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme).apply(
        fontFamily: sans,
        fontFamilyFallback: [sansLao],
      ),
    );
  }
}
