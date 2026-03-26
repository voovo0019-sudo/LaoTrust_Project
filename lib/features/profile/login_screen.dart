// =============================================================================
// v7.9 로그인 전용 진입 — [ProfileScreen] 전화 인증 시트를 즉시 연다.
// 인증 성공 시 [ProfileScreen.popToHomeOnAuthSuccess]로 홈(루트)까지 복귀.
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
      popToHomeOnAuthSuccess: true,
      discardPendingPostLoginRedirect: true,
    );
  }
}
