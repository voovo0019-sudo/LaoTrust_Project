// =============================================================================
// LT-10 메인탭 v2.0 - Riverpod 기반 (GoRouter 호환)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../home/components/custom_bottom_nav.dart';
import '../../core/providers/providers.dart';

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({super.key});

  static const String routeName = '/main';

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    // ignore: unused_local_variable
    final _ = themeMode;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            locale: locale,
            onLocaleChanged: (l) => ref.read(localeProvider.notifier).setLocale(l),
          ),
          const JobsScreen(),
          const ChatScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onIndexChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
