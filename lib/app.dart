// =============================================================================
// LaoTrust App v2.0 - GoRouter 기반
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async' show Completer;
import 'core/theme.dart';
import 'core/locale_service.dart';
import 'core/app_localizations.dart';
import 'core/providers/providers.dart';
import 'features/main_tab/main_tab_screen.dart';
import 'features/request_flow/request_flow_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/my_requests_screen.dart';
import 'features/profile/login_screen.dart';
import 'features/profile/bcel_onepay_screen.dart';
import 'features/profile/expert_dashboard_screen.dart';
import 'features/profile/partner_support_center_screen.dart';
import 'features/universal_wizard/universal_wizard_screen.dart';
import 'features/universal_wizard/request_complete_screen.dart';
import 'features/home/quick_job_post_screen.dart';
import 'features/home/expert_detail_screen.dart';
import 'features/expert_inbox/expert_inbox_screen.dart';
import 'features/expert_inbox/expert_inbox_detail_screen.dart';

final _router = GoRouter(
  initialLocation: '/main',
  routes: [
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainTabScreen(),
    ),
    GoRoute(
      path: '/request_flow',
      builder: (context, state) => const RequestFlowScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/my_requests',
      builder: (context, state) => const MyRequestsScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/bcel_onepay',
      builder: (context, state) => const BcelOnepayScreen(),
    ),
    GoRoute(
      path: '/expert_dashboard',
      builder: (context, state) => const ExpertDashboardScreen(),
    ),
    GoRoute(
      path: '/partner_support',
      builder: (context, state) => const PartnerSupportCenterScreen(),
    ),
    GoRoute(
      path: '/quick_job_post',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null || args.isEmpty) {
          return const QuickJobPostScreen();
        }
        return QuickJobPostScreen(
          editDocumentId: args['documentId'] as String?,
          initialTitle: args['title'] as String? ?? '',
          initialLocation: args['location'] as String? ?? '',
          initialSalary: args['salary'] as String? ?? '',
          initialDetail: args['detail'] as String? ?? '',
          initialDeadline: args['deadline'] as DateTime?,
        );
      },
    ),
    GoRoute(
      path: '/wizard',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return UniversalWizardScreen(
          categoryKey: args?['categoryKey'] as String? ?? 'expert_repair',
          initialSubTypeId: args?['initialSubTypeId'] as String?,
          initialSubTypeLabel: args?['initialSubTypeLabel'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/request_complete',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return RequestCompleteScreen(
          receiptNo: args?['receiptNo'] as String? ?? 'LT-000000',
          saveCompleter: args?['saveCompleter'] as Completer<void>?,
        );
      },
    ),
    GoRoute(
      path: '/expert_detail',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return ExpertDetailScreen(
          expertId: args?['expertId'] as String? ?? '',
          data: args?['data'] as Map<String, dynamic>? ?? {},
        );
      },
    ),
    GoRoute(
      path: '/expert_inbox_detail',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return ExpertInboxDetailScreen(
          docId: args?['docId'] as String? ?? '',
          data: args?['data'] as Map<String, dynamic>? ?? {},
        );
      },
    ),
    GoRoute(
      path: '/expert_inbox',
      builder: (context, state) => const ExpertInboxScreen(),
    ),
  ],
);

class LaoTrustApp extends ConsumerWidget {
  const LaoTrustApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return FutureBuilder<Map<String, String>>(
      future: loadStringsForLocale(locale),
      builder: (context, snapshot) {
        final strings = snapshot.data ?? {};
        return MaterialApp.router(
          title: 'LaoTrust',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.light,
          themeMode: themeMode,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return AppLocalizationsScope(
              locale: locale,
              strings: strings,
              child: child!,
            );
          },
          routerConfig: _router,
        );
      },
    );
  }
}
