// =============================================================================
// LT-10 하단 탭 바: Chat (4단 고정 메뉴). LT-04 화면 정의서 일치.
// 매칭/견적 메시지 목록. 상태 보존을 위해 MainTabScreen의 IndexedStack 자식으로 유지.
// 한/영 주석 병기.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  static const String routeName = '/chat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n('chat')),
      ),
      body: Center(
        child: Text(
          '매칭·견적 메시지 목록 (뼈대)',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
