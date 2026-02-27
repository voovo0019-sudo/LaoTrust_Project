// =============================================================================
import 'package:flutter_localizations/flutter_localizations.dart';
// LT-10 라오트러스트 앱 루트 · Firebase 연동 및 하이브리드 아키텍처
// Indigo Blue #3F51B5 전역 고정. 하단 탭(Home, Jobs, Chat, Profile) + 상태 보존.
// 한/영 주석 병기.
// =============================================================================

import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/theme_service.dart';
import 'core/locale_service.dart';
import 'core/app_localizations.dart';
import 'features/main_tab/main_tab_screen.dart';
import 'features/request_flow/request_flow_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/bcel_onepay_screen.dart';
import 'features/profile/expert_dashboard_screen.dart';

class LaoTrustApp extends StatefulWidget {
  const LaoTrustApp({super.key});

  @override
  State<LaoTrustApp> createState() => _LaoTrustAppState();
}

class _LaoTrustAppState extends State<LaoTrustApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('ko');
  Map<String, String> _strings = {};

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLocaleAndStrings();
  }

  Future<void> _loadThemeMode() async {
    final mode = await ThemeService.getThemeMode();
    if (mounted) setState(() => _themeMode = mode);
  }

  Future<void> _loadLocaleAndStrings() async {
    final locale = await getSavedLocale();
    final strings = await loadStringsForLocale(locale);
    if (mounted) {
      setState(() {
      _locale = locale;
      _strings = strings;
    });
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    ThemeService.setThemeMode(mode);
  }

  Future<void> _setLocale(Locale locale) async {
    if (_locale == locale) return;
    await saveLocale(locale);
    final strings = await loadStringsForLocale(locale);
    if (mounted) {
      setState(() {
      _locale = locale;
      _strings = strings;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaoTrust',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: _locale,
      supportedLocales: supportedLocales,
      // 여기에 75번 줄 바로 아래에 붙여넣으세요!
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return AppLocalizationsScope(
          locale: _locale,
          strings: _strings,
          child: child!,
        );
      },
      initialRoute: MainTabScreen.routeName,
      routes: {
        MainTabScreen.routeName: (_) => MainTabScreen(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
              locale: _locale,
              onLocaleChanged: _setLocale,
            ),
        RequestFlowScreen.routeName: (_) => const RequestFlowScreen(),
        profileRouteName: (_) => const ProfileScreen(),
        bcelOnepayRouteName: (_) => const BcelOnepayScreen(),
        expertDashboardRouteName: (_) => const ExpertDashboardScreen(),
      },
    );
  }
}
