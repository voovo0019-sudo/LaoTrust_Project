import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';
import '../../../core/firebase_service.dart';

/// 상단 환영 배너: 로그인/화이트리스트 전화번호에서 뒷자리 4개를 추출하는 0019 엔진.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: ListenableBuilder(
        listenable: whitelistDisplayPhoneNotifier,
        builder: (context, _) {
          return StreamBuilder(
            stream: auth.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final phone = user?.phoneNumber ?? whitelistDisplayPhoneNotifier.value ?? '';
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
          );
        },
      ),
    );
  }
}

