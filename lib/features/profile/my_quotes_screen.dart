import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';
import '../../data/firestore_schema.dart';
import '../../services/firebase_service.dart';

const Color _kRoyalBlue = Color(0xFF1E3A8A);

class MyQuotesScreen extends StatefulWidget {
  const MyQuotesScreen({super.key});

  @override
  State<MyQuotesScreen> createState() => _MyQuotesScreenState();
}

class _MyQuotesScreenState extends State<MyQuotesScreen> {
  String _langCode() {
    final raw = Localizations.localeOf(context).languageCode.toLowerCase();
    if (raw.startsWith('ko')) return 'ko';
    if (raw.startsWith('lo')) return 'lo';
    return 'en';
  }

  String _t(String key) {
    final lang = _langCode();
    return kStaticUiTripleByMessageKey[key]?[lang] ?? key;
  }

  Color _statusColor(String status) {
    switch (status) {
      case kQuoteStatusAccepted:
        return Colors.green;
      case kQuoteStatusRejected:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case kQuoteStatusAccepted:
        return _t('client_quote_accepted');
      case kQuoteStatusRejected:
        return _t('client_quote_rejected');
      default:
        return _t('client_quote_pending');
    }
  }

  Future<void> _acceptQuote(Map<String, dynamic> quoteData, String quoteId) async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection(kColQuotes)
          .doc(quoteId)
          .update({
            QuoteFields.status: kQuoteStatusAccepted,
            QuoteFields.statusUpdatedAt: FieldValue.serverTimestamp(),
          });
      final requestTitleI18n = Map<String, dynamic>.from(
          quoteData[QuoteFields.requestTitleI18n] as Map? ??
              {'ko': '', 'en': '', 'lo': ''});
      await FirebaseService().createServiceChatRoom(
        requestId: quoteData[QuoteFields.requestId] as String? ?? '',
        requestTitleI18n: requestTitleI18n,
        clientId: uid,
        expertId: quoteData[QuoteFields.expertId] as String? ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('client_quote_accept_done'))),
      );
      context.push('/chat');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('quote_send_failed'))),
      );
    }
  }

  Future<void> _showExpertPhone(String expertId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(kColUsers)
          .doc(expertId)
          .get()
          .timeout(const Duration(seconds: 5));
      final phone = doc.data()?[UserFields.phone] as String? ?? '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📞 $phone')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _kRoyalBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _t('my_quotes_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: Text(_t('inbox_login_required_title'))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _t('my_quotes_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(kColQuotes)
            .where(QuoteFields.clientId, isEqualTo: uid)
            .orderBy(QuoteFields.createdAt, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                _t('client_quotes_empty'),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final quoteId = docs[index].id;
              final lang = _langCode();
              final status = data[QuoteFields.status] as String? ?? kQuoteStatusPending;
              final message = data[QuoteFields.message] as String? ?? '';
              final price = data[QuoteFields.price] as String?;
              final duration = data[QuoteFields.estimatedDuration] as String?;
              final titleMap = data[QuoteFields.requestTitleI18n] as Map<String, dynamic>?;
              final title = titleMap?[lang]?.toString() ?? titleMap?['ko']?.toString() ?? '';
              final expertId = data[QuoteFields.expertId] as String? ?? '';
              final createdAt = data[QuoteFields.createdAt];
              String dateStr = '';
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 + 상태 배지
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kRoyalBlue,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _statusColor(status), width: 1),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 가격 (있을 때만)
                      if (price != null && price.isNotEmpty)
                        Text(
                          '💰 $price USD',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      // 소요시간 (있을 때만)
                      if (duration != null && duration.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '⏱ $duration',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // 메시지
                      Text(
                        message,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      // 날짜
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      // 대기 중 버튼
                      if (status == kQuoteStatusPending) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kRoyalBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: Text(_t('client_chat_with_expert')),
                            onPressed: () => _acceptQuote(data, quoteId),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 전화 연결 비활성 + 잠금 멘트
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade400,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: const Icon(Icons.lock_outline, size: 16),
                            label: Text(_t('client_call_expert')),
                            onPressed: null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            _t('quote_call_locked'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      // 수락됨 버튼
                      ] else if (status == kQuoteStatusAccepted) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: Text(_t('client_chat_with_expert')),
                                onPressed: () => context.push('/chat'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kRoyalBlue,
                                  side: const BorderSide(color: _kRoyalBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                icon: const Icon(Icons.phone_outlined, size: 16),
                                label: Text(_t('client_call_expert')),
                                onPressed: () => _showExpertPhone(expertId),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
