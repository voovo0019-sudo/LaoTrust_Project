// =============================================================================
// LoginScreen: /login 라우트 → Google 로그인 팝업 직접 실행
// Phone Auth 제거 후 Google signInWithPopup 방식으로 전환
// =============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/google_auth_service.dart';
import '../../core/translation_mapper.dart';

const String loginScreenRouteName = '/login';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 빌드 직후 Google 로그인 팝업 자동 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      try {
        final credential = await signInWithGoogle();
        if (!context.mounted) return;
        if (credential != null) {
          context.go('/');
        } else {
          if (context.mounted) context.go('/');
        }
      } catch (e) {
        if (context.mounted) context.go('/');
      }
    });

    final lang = Localizations.localeOf(context).languageCode
        .startsWith('ko') ? 'ko'
        : Localizations.localeOf(context).languageCode
            .startsWith('lo') ? 'lo' : 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF1E3A8A),
            ),
            const SizedBox(height: 24),
            Text(
              kStaticUiTripleByMessageKey['google_login_loading']?[lang]
                  ?? '로그인 중...',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
