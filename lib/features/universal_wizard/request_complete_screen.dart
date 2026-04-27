// =============================================================================
// LaoTrust — 신청완료 화면
// radarProvider로 레이더 트리거 전송
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translation_mapper.dart';
import '../../core/providers/radar_provider.dart';
import '../main_tab/main_tab_screen.dart';

const String requestCompleteRouteName = '/request-complete';

class RequestCompleteScreen extends ConsumerWidget {
  const RequestCompleteScreen({
    super.key,
    required this.receiptNo,
  });

  static const String routeName = '/request-complete';
  final String receiptNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode
            .toLowerCase()
            .startsWith('ko')
        ? 'ko'
        : Localizations.localeOf(context).languageCode
                .toLowerCase()
                .startsWith('lo')
            ? 'lo'
            : 'en';
    String t(String key) => kStaticUiTripleByMessageKey[key]?[lang] ?? key;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B5BDB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF3B5BDB),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                t('request_success_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                t('request_success_message'),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B5BDB).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      t('request_success_receipt'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      receiptNo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B5BDB),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t('request_success_contact_time'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/profile',
                      (route) => route.isFirst,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B5BDB),
                    side: const BorderSide(color: Color(0xFF3B5BDB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    t('request_success_view_history'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // 1. 먼저 홈으로 이동 (home_screen 빌드 시작)
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      MainTabScreen.routeName,
                      (route) => false,
                    );
                    // 2. home_screen 빌드 완료 후 레이더 트리거
                    await Future.delayed(const Duration(milliseconds: 300));
                    ref.read(radarProvider.notifier).trigger();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5BDB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    t('request_success_home'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
