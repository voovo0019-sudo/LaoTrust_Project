// =============================================================================
// LaoTrust 1:1 채팅방 화면
// 실시간 메시지 송수신 + 읽음 처리 + 메시지별 "번역 보기" 기능.
// 원문은 절대 지우지 않고, 번역 결과를 추가로 표시 (카카오톡/라인 방식).
// 모든 텍스트 ko/en/lo Triple-Map 준수. 하드코딩 0개.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/translation_mapper.dart';
import '../../services/firebase_service.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.jobTitle,
    required this.myUid,
  });

  final String chatId;
  final String jobTitle;
  final String myUid;

  static const String routeName = '/chat_room';

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  // 메시지별 번역 표시 상태 관리 (messageId → 번역된 텍스트, null이면 아직 번역 안 함)
  final Map<String, String?> _translatedCache = {};
  // 메시지별 번역 보기 ON/OFF 상태
  final Map<String, bool> _showTranslated = {};
  // 메시지별 번역 진행 중 여부
  final Map<String, bool> _translating = {};

  @override
  void initState() {
    super.initState();
    FirebaseService().markMessagesAsRead(
      chatId: widget.chatId,
      myUid: widget.myUid,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      await FirebaseService().sendMessage(
        chatId: widget.chatId,
        senderId: widget.myUid,
        text: text,
      );
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// 번역 보기 버튼 탭 처리.
  /// 캐시에 있으면 바로 토글, 없으면 API 호출 후 캐시 저장(메모리+Firestore).
  Future<void> _onToggleTranslate({
    required String messageId,
    required String text,
    required Map<String, dynamic> existingCache,
  }) async {
    // 이미 번역 보기 상태면 → 끄기만 함 (재호출 없음)
    if (_showTranslated[messageId] == true) {
      setState(() => _showTranslated[messageId] = false);
      return;
    }

    final lang = Localizations.localeOf(context).languageCode;

    // 1. 메모리 캐시 확인
    if (_translatedCache[messageId] != null) {
      setState(() => _showTranslated[messageId] = true);
      return;
    }

    // 2. Firestore 캐시 확인
    final firestoreCached = existingCache[lang]?.toString();
    if (firestoreCached != null && firestoreCached.isNotEmpty) {
      setState(() {
        _translatedCache[messageId] = firestoreCached;
        _showTranslated[messageId] = true;
      });
      return;
    }

    // 3. 캐시 없음 → API 호출
    setState(() => _translating[messageId] = true);
    final result = await TranslationMapper.translateChatMessage(
      text: text,
      targetLangCode: lang,
    );
    if (!mounted) return;
    setState(() {
      _translating[messageId] = false;
      if (result != null && result.isNotEmpty) {
        _translatedCache[messageId] = result;
        _showTranslated[messageId] = true;
        // Firestore에 비동기 캐시 저장 (실패해도 화면엔 영향 없음)
        FirebaseService().cacheTranslatedMessage(
          chatId: widget.chatId,
          messageId: messageId,
          langCode: lang,
          translatedText: result,
        );
      } else {
        // 번역 실패 → 스낵바 안내, 원문은 그대로 유지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n('chat_translate_fail'))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseService().watchMessages(widget.chatId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(
          widget.jobTitle.isNotEmpty
              ? widget.jobTitle
              : context.l10n('chat_room_title'),
          style: TextStyle(
            fontFamilyFallback: AppTheme.notoSansLaoFallback,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1E3A8A)),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n('chat_no_message_yet'),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final messageId = msg['messageId']?.toString() ?? '';
                    final isMe =
                        msg['senderId']?.toString() == widget.myUid;
                    final text = msg['text']?.toString() ?? '';
                    final imageUrl =
                        msg['imageUrl']?.toString() ?? '';
                    final isRead = msg['isRead'] as bool? ?? false;
                    final createdAtMs =
                        msg['createdAt'] as int? ?? 0;
                    final createdAt = createdAtMs > 0
                        ? DateTime.fromMillisecondsSinceEpoch(
                            createdAtMs)
                        : null;
                    final timeStr = createdAt != null
                        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                        : '';
                    final translatedCacheMap =
                        (msg['translatedTextCache'] as Map<String, dynamic>?) ??
                            <String, dynamic>{};

                    return _MessageBubble(
                      text: text,
                      imageUrl: imageUrl,
                      isMe: isMe,
                      isRead: isRead,
                      timeStr: timeStr,
                      readLabel: context.l10n('chat_read'),
                      translatedText: _translatedCache[messageId],
                      showTranslated:
                          _showTranslated[messageId] ?? false,
                      isTranslating: _translating[messageId] ?? false,
                      translateLabel: context.l10n('chat_translate'),
                      translatingLabel:
                          context.l10n('chat_translating'),
                      showOriginalLabel:
                          context.l10n('chat_show_original'),
                      onTranslateTap: text.isEmpty
                          ? null
                          : () => _onToggleTranslate(
                                messageId: messageId,
                                text: text,
                                existingCache: translatedCacheMap,
                              ),
                    );
                  },
                );
              },
            ),
          ),

          // ── 입력창 ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: context.l10n('chat_hint'),
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.imageUrl,
    required this.isMe,
    required this.isRead,
    required this.timeStr,
    required this.readLabel,
    required this.translatedText,
    required this.showTranslated,
    required this.isTranslating,
    required this.translateLabel,
    required this.translatingLabel,
    required this.showOriginalLabel,
    required this.onTranslateTap,
  });

  final String text;
  final String imageUrl;
  final bool isMe;
  final bool isRead;
  final String timeStr;
  final String readLabel;
  final String? translatedText;
  final bool showTranslated;
  final bool isTranslating;
  final String translateLabel;
  final String translatingLabel;
  final String showOriginalLabel;
  final VoidCallback? onTranslateTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              child: const Icon(Icons.person,
                  color: Color(0xFF1E3A8A), size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.grey),
                  ),
                ),
              if (text.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF1E3A8A)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 원문 (항상 표시)
                      Text(
                        text,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                      ),
                      // 번역 결과 (showTranslated=true일 때만 추가 표시)
                      if (showTranslated && translatedText != null) ...[
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          child: Divider(
                            height: 1,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.shade300,
                          ),
                        ),
                        Text(
                          translatedText!,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF475569),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      // 번역 보기/원문 보기 버튼
                      if (onTranslateTap != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: GestureDetector(
                            onTap: isTranslating ? null : onTranslateTap,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isTranslating)
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1E3A8A),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.translate,
                                    size: 12,
                                    color: isMe
                                        ? Colors.white
                                            .withValues(alpha: 0.8)
                                        : const Color(0xFF1E3A8A),
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  isTranslating
                                      ? translatingLabel
                                      : (showTranslated
                                          ? showOriginalLabel
                                          : translateLabel),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white
                                            .withValues(alpha: 0.8)
                                        : const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMe) ...[
                    Text(
                      isRead ? readLabel : '1',
                      style: TextStyle(
                        fontSize: 10,
                        color: isRead
                            ? Colors.grey.shade400
                            : const Color(0xFF1E3A8A),
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
