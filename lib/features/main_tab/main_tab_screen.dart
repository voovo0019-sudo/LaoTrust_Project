// =============================================================================
// LT-10 [Navigation] 하단 탭 바(Home, Jobs, Chat, Profile) + 상태 보존(State Persistence)
// IndexedStack으로 4개 화면을 항상 유지하여 탭 전환 시 스크롤/입력 상태 유지.
// 디지털 캡슐 v1.5 / LT-04 일치. 한/영 주석 병기.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../home/home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.locale,
    required this.onLocaleChanged,
  });

  static const String routeName = '/main';

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            locale: widget.locale,
            onLocaleChanged: widget.onLocaleChanged,
          ),
          const JobsScreen(),
          const ChatScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: context.l10n('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.work), label: context.l10n('jobs')),
          BottomNavigationBarItem(icon: const Icon(Icons.chat), label: context.l10n('chat')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: context.l10n('profile')),
        ],
      ),
    );
  }
}
