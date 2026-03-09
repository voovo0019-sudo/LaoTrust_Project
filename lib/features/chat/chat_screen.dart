// =============================================================================
// LT-10 [채팅 탭] 전문가와 1:1 상담 · 최근 대화 목록 + 안 읽은 메시지 인디케이터
// 다국어(KR/LA/EN) 실시간 변환. 유지: 하단 내비에서 진입.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  static const String routeName = '/chat';

  static const Color _appBarBlue = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _appBarBlue,
        foregroundColor: Colors.white,
        title: Text(context.l10n('chat')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n('chat_header'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _ChatTile(
            name: '에어컨 수리 전문가',
            lastMessage: '견적 보내드렸습니다.',
            time: '10:32',
            unreadCount: 2,
            onTap: () {},
          ),
          _ChatTile(
            name: '배관 수리 김철수',
            lastMessage: '내일 오전 가능합니다.',
            time: '어제',
            unreadCount: 0,
            onTap: () {},
          ),
          _ChatTile(
            name: '전기 점검 서비스',
            lastMessage: '사진 확인했습니다.',
            time: '월',
            unreadCount: 1,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
