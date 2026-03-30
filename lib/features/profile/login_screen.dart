// =============================================================================
// v7.9 로그인 전용 진입 — [ProfileScreen] 전화 인증 시트를 즉시 연다.
// v1.4: 보류된 [setPostLoginRedirect] 목적지 유지, 홈 강제 pop 비활성.
// =============================================================================

import 'package:flutter/material.dart';
import 'profile_screen.dart';

const String loginScreenRouteName = '/login';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(
      openPhoneAuthOnStart: true,
      // 홈으로 강제 이동 중단 — [schedulePostLoginNavigationAfterAuth]가
      // 보류 리다이렉트(있으면)로 목적지 보냄.
      popToHomeOnAuthSuccess: false,
      // 진입 시 보류 리다이렉트를 비우지 않음 — 구인 등록 등 복귀용.
      discardPendingPostLoginRedirect: false,
    );
  }
}
