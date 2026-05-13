import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import '../../../core/firebase_service.dart';

/// 환영 메시지: Phone Auth + Google 로그인 모두 지원
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
      child: StreamBuilder(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return const SizedBox.shrink();

          // Phone 로그인: 마지막 4자리
          final phone = user.phoneNumber ?? '';
          final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length >= 4) {
            final last4 = digits.substring(digits.length - 4);
            final text = context.l10n('welcome_message_prefix') +
                last4 +
                context.l10n('welcome_message_suffix');
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Sans',
                  letterSpacing: 0.1,
                ),
              ),
            );
          }

          // Google 로그인: displayName 또는 email 앞부분
          final displayName = user.displayName?.trim() ?? '';
          final email = user.email ?? '';
          final emailPrefix = email.contains('@') ? email.split('@').first : email;
          final name = displayName.isNotEmpty
              ? displayName
              : (emailPrefix.isNotEmpty ? emailPrefix : '');

          if (name.isEmpty) return const SizedBox.shrink();

          final text = context.l10n('welcome_message_prefix') +
              name +
              context.l10n('welcome_message_suffix');
          return Align(
            alignment: Alignment.centerRight,
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
          );
        },
      ),
    );
  }
}
