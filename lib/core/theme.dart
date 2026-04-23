// =============================================================================
// LT-10 AppTheme v2.0 - 글로벌 앱 수준 테마 고도화
// 인디고블루(#3F51B5) 기반 + 골드 포인트 + 그라디언트 버튼 + 세련된 카드
// Noto Sans + Noto Sans Lao (google_fonts) 폰트 유지
// =============================================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── 메인 컬러 팔레트 ──────────────────────────────────────────
  static const Color indigoBlue      = Color(0xFF3F51B5);
  static const Color indigoBlueLight = Color(0xFF5C6BC0);
  static const Color indigoBlueDark  = Color(0xFF303F9F);
  static const Color white           = Color(0xFFFFFFFF);

  // 골드 포인트 (동남아 감성 + 신뢰/프리미엄)
  static const Color gold            = Color(0xFFFFB300);
  static const Color goldLight       = Color(0xFFFFD54F);

  // 배경/서피스
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color onSurfaceLight  = Color(0xFF1A1A1A);
  static const Color backgroundDark  = Color(0xFF121212);
  static const Color surfaceDark     = Color(0xFF1E1E1E);
  static const Color onSurfaceDark   = Color(0xFFE8E8E8);

  // 그라디언트 정의
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5), Color(0xFF303F9F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 공통 그림자
  static List<BoxShadow> get cardShadow => [
    (const BoxShadow(
      color: Color(0xFF3F51B5),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    )).scale(0.08),
    const BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    const BoxShadow(
      color: Color(0x663F51B5),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // Noto Sans Lao fallback
  static List<String> get notoSansLaoFallback {
    final f = GoogleFonts.notoSansLao().fontFamily;
    return f == null ? const [] : [f];
  }

  static TextStyle get textStyleLaoPrimary => GoogleFonts.notoSansLao();

  // ── Light Theme ───────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: indigoBlue,
        onPrimary: white,
        secondary: gold,
        onSecondary: Color(0xFF1A1A1A),
        surface: surfaceLight,
        onSurface: onSurfaceLight,
        surfaceContainerHighest: Color(0xFFEEEEEE),
      ),
      scaffoldBackgroundColor: backgroundLight,

      // AppBar — 그라디언트 효과를 위해 flexibleSpace 사용 유도
      appBarTheme: const AppBarTheme(
        backgroundColor: indigoBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      // ElevatedButton — 그라디언트 느낌 + 그림자
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigoBlue,
          foregroundColor: white,
          elevation: 4,
          shadowColor: const Color(0x663F51B5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // OutlinedButton — 세련된 테두리
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: indigoBlue,
          side: const BorderSide(color: indigoBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: indigoBlue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card — 미세 그림자 + 둥근 곡률
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // InputDecoration — 세련된 텍스트필드
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: indigoBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF888888)),
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F2FF),
        selectedColor: indigoBlue,
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
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

  // ── Dark Theme ────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: indigoBlue,
        onPrimary: white,
        secondary: gold,
        onSecondary: Color(0xFF1A1A1A),
        surface: surfaceDark,
        onSurface: onSurfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: onSurfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurfaceDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigoBlue,
          foregroundColor: white,
          elevation: 4,
          shadowColor: const Color(0x663F51B5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: indigoBlue,
          side: const BorderSide(color: indigoBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: indigoBlue, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: indigoBlue,
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 1,
        space: 1,
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
