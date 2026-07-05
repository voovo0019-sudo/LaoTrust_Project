// =============================================================================
// LaoTrust 채팅 목록 화면 — 실제 Firestore 실시간 스트림 연결
// 참여 중인 1:1 채팅방 목록 표시. 읽지 않은 메시지 뱃지 포함.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/providers/providers.dart';
import '../../core/theme.dart';
import '../../data/firestore_schema.dart';
import '../../services/firebase_service.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});
  static const String routeName = '/chat';
  static const Color _appBarBlue = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarBlue,
          foregroundColor: Colors.white,
          title: Text(context.l10n('chat')),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            context.l10n('login_required'),
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    final stream = FirebaseService().watchMyChatRooms(currentUser.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _appBarBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(currentTabProvider.notifier).goHome();
            }
          },
        ),
        title: Text(context.l10n('chat')),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final chatRooms = snapshot.data ?? [];
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n('no_chat_rooms'),
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chatRooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              return _ChatRoomTile(
                room: room,
                myUid: currentUser.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({required this.room, required this.myUid});
  final Map<String, dynamic> room;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final chatType = room['chatType']?.toString() ?? 'job';
    final titleI18n = Map<String, dynamic>.from(
        chatType == 'service_request'
            ? (room['requestTitleI18n'] as Map? ?? {})
            : (room['jobTitleI18n'] as Map? ?? {}));
    final jobTitle = titleI18n[lang]?.toString().isNotEmpty == true
        ? titleI18n[lang].toString()
        : titleI18n['en']?.toString() ?? '';
    final lastMessage = room['lastMessage']?.toString() ?? '';
    final lastMessageAtMs = room['lastMessageAt'] as int? ?? 0;
    final lastMessageAt = lastMessageAtMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastMessageAtMs)
        : null;
    final timeStr = lastMessageAt != null
        ? '${lastMessageAt.hour.toString().padLeft(2, '0')}:${lastMessageAt.minute.toString().padLeft(2, '0')}'
        : '';
    final chatId = room['chatId']?.toString() ?? '';
    final unreadCount = (room[ChatFields.unreadCountKey(myUid)] as int? ?? 0);
    final hasUnread = unreadCount > 0;
    final String otherUid;
    if (chatType == 'service_request') {
      final clientId = room['clientId']?.toString() ?? '';
      final expertId = room['expertId']?.toString() ?? '';
      otherUid = (myUid == clientId) ? expertId : clientId;
    } else {
      final employerId = room['employerId']?.toString() ?? '';
      final applicantId = room['applicantId']?.toString() ?? '';
      otherUid = (myUid == employerId) ? applicantId : employerId;
    }

    return GestureDetector(
      onTap: () {
        if (chatId.isNotEmpty) {
          context.push(
            '/chat_room',
            extra: {
              'chatId': chatId,
              'jobTitle': jobTitle,
              'myUid': myUid,
              'otherUid': otherUid,
            },
          );
        }
      },
      child: Container(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Color(0xFF1E3A8A), size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: TextStyle(
                    fontFamilyFallback: AppTheme.notoSansLaoFallback,
                    fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 15,
                    color: hasUnread
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (hasUnread)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            lastMessage.isEmpty
                ? context.l10n('chat_no_message_yet')
                : lastMessage,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
