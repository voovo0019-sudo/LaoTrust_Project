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
            nameKey: 'chat_sample_name_1',
            messageKey: 'chat_sample_message_1',
            timeKey: 'chat_sample_time_1',
            unreadCount: 2,
            onTap: () => _showEnterChatDialog(context, nameKey: 'chat_sample_name_1'),
          ),
          _ChatTile(
            nameKey: 'chat_sample_name_2',
            messageKey: 'chat_sample_message_2',
            timeKey: 'chat_sample_time_2',
            unreadCount: 0,
            onTap: () => _showEnterChatDialog(context, nameKey: 'chat_sample_name_2'),
          ),
          _ChatTile(
            nameKey: 'chat_sample_name_3',
            messageKey: 'chat_sample_message_3',
            timeKey: 'chat_sample_time_3',
            unreadCount: 1,
            onTap: () => _showEnterChatDialog(context, nameKey: 'chat_sample_name_3'),
          ),
        ],
      ),
    );
  }

  void _showEnterChatDialog(BuildContext context, {required String nameKey}) {
    final name = context.l10n(nameKey);
    final message = context.l10n('chat_enter_message').replaceAll('{name}', name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.nameKey,
    required this.messageKey,
    required this.timeKey,
    required this.unreadCount,
    required this.onTap,
  });
  final String nameKey;
  final String messageKey;
  final String timeKey;
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
          context.l10n(nameKey),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          context.l10n(messageKey),
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
              context.l10n(timeKey),
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
