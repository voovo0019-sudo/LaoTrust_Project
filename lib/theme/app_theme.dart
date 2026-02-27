import 'package:flutter/material.dart';

/// 🏛️ LaoTrust 전용 화이트-블루 테마 엔진 (Constitution v2.0 반영)
class AppTheme {
  // 핵심 색상 정의
  static const Color indigoBlue = Color(0xFF3F51B5); // 신뢰의 인디고 블루
  static const Color white = Color(0xFFFFFFFF);     // 깨끗한 배경 화이트

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, 
      primaryColor: indigoBlue,
      scaffoldBackgroundColor: white, // 배경 무조건 화이트
      
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: indigoBlue,
        elevation: 0,
        centerTitle: true,
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: indigoBlue,
        brightness: Brightness.light,
        surface: white,
      ),
    );
  }

  // 핵심: 다크 모드 요청이 와도 'light' 테마를 반환하여 화이트 유지!
  static ThemeData get dark => light; 
}