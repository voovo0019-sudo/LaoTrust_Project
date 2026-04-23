import 'package:flutter/material.dart';
import '../../../core/app_localizations.dart';
import '../../../core/firebase_service.dart';

/// 환영 배너: Firebase Phone Auth 기반 - 화이트리스트 완전 제거
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
          final phone = user?.phoneNumber ?? '';
          final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length < 4) return const SizedBox.shrink();
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
        },
      ),
    );
  }
}
