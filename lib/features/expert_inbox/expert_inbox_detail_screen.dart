import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/translation_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/firestore_schema.dart';

const Color _kRoyalBlue = Color(0xFF1E3A8A);

class ExpertInboxDetailScreen extends StatefulWidget {
  const ExpertInboxDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  final String docId;
  final Map<String, dynamic> data;

  @override
  State<ExpertInboxDetailScreen> createState() => _ExpertInboxDetailScreenState();
}

class _ExpertInboxDetailScreenState extends State<ExpertInboxDetailScreen> {
  bool _isLoading = false;

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

  bool _quoteSent = false;

  Future<void> _checkQuoteAlreadySent() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection(kColQuotes)
          .where(QuoteFields.requestId, isEqualTo: widget.docId)
          .where(QuoteFields.expertId, isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _quoteSent = snap.docs.isNotEmpty);
      }
    } catch (_) {}
  }

  Future<void> _sendQuote({
    required String message,
    String? price,
    String? estimatedDuration,
  }) async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('no uid');
      final data = widget.data;
      final clientId = data[RequestFields.userId] as String? ?? '';
      final categoryKey = data['categoryKey'] as String? ?? '';
      final wizardI18n = data['wizardI18n'] as Map<String, dynamic>?;
      final titleMap = wizardI18n?['title'] as Map<String, dynamic>? ??
          {'ko': categoryKey, 'en': categoryKey, 'lo': categoryKey};
      await FirebaseFirestore.instance
          .collection(kColQuotes)
          .add({
            QuoteFields.requestId: widget.docId,
            QuoteFields.requestTitleI18n: titleMap,
            QuoteFields.categoryKey: categoryKey,
            QuoteFields.expertId: uid,
            QuoteFields.clientId: clientId,
            QuoteFields.price: price?.isNotEmpty == true ? price : null,
            QuoteFields.currency: 'USD',
            QuoteFields.estimatedDuration:
                estimatedDuration?.isNotEmpty == true
                    ? estimatedDuration
                    : null,
            QuoteFields.message: message,
            QuoteFields.status: kQuoteStatusPending,
            QuoteFields.createdAt: FieldValue.serverTimestamp(),
          });

      // 역참조 배열 업데이트 — 목록 화면 상태 표시용
      await FirebaseFirestore.instance
          .collection(kColUsers)
          .doc(uid)
          .update({
            UserFields.quotedRequestIds: FieldValue.arrayUnion([widget.docId]),
          });

      if (mounted) {
        setState(() => _quoteSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('quote_sent'))),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('quote_send_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQuoteBottomSheet() {
    if (_quoteSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('quote_already_sent'))),
      );
      return;
    }
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final messageController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('quote_btn_send'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kRoyalBlue,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _t('quote_price_label'),
                hintText: _t('quote_price_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: _t('quote_duration_label'),
                hintText: _t('quote_duration_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _t('quote_message_label'),
                hintText: _t('quote_message_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRoyalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  final msg = messageController.text.trim();
                  if (msg.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_t('quote_message_hint')),
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  _sendQuote(
                    message: msg,
                    price: priceController.text.trim(),
                    estimatedDuration: durationController.text.trim(),
                  );
                },
                child: Text(
                  _t('quote_btn_send'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkQuoteAlreadySent();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final lang = _langCode();
    final wizardI18n = data['wizardI18n'] as Map<String, dynamic>?;

    String getI18n(String field) {
      final map = wizardI18n?[field] as Map<String, dynamic>?;
      return map?[lang] as String? ?? data[field]?.toString() ?? '';
    }

    final rawTitle = getI18n('title');
    final titleParts = rawTitle.split(' · ');
    final categoryTitle = titleParts.first.trim();
    final subTypeTitle = titleParts.length > 1
        ? titleParts.skip(1).join(' · ').trim()
        : '';

    final location = data['location'] as Map<String, dynamic>?;
    String locationStr = '';
    if (wizardI18n != null) {
      final loc = wizardI18n['location'];
      if (loc is Map) {
        locationStr = loc[lang]?.toString() ??
            loc['ko']?.toString() ??
            loc['en']?.toString() ??
            '';
      }
    }
    if (locationStr.isEmpty) {
      locationStr = location?['landmark']?.toString() ?? '';
      final fromLandmark = location?['fromLandmark']?.toString() ?? '';
      final toLandmark = location?['toLandmark']?.toString() ?? '';
      if (fromLandmark.isNotEmpty && toLandmark.isNotEmpty) {
        locationStr = '$fromLandmark → $toLandmark';
      }
    }
    final schedule = data['schedule'] as Map<String, dynamic>?;
    final scheduleStr =
        schedule != null ? '${schedule['date'] ?? ''} ${schedule['time'] ?? ''}' : '';
    final detail = getI18n('detail');
    final memoI18n = data['memoI18n'];
    String memo = '';
    if (memoI18n is Map) {
      memo = memoI18n[lang]?.toString() ??
          memoI18n['ko']?.toString() ??
          memoI18n['en']?.toString() ??
          '';
    }
    if (memo.isEmpty) memo = data['memo']?.toString() ?? '';
    final photos = data['photos'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        title: Text(
          categoryTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kRoyalBlue,
                        ),
                      ),
                      if (subTypeTitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subTypeTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 24),
                  _infoRow(_t('inbox_detail'), detail),
                  _infoRow(_t('inbox_location'), locationStr),
                  _infoRow(_t('inbox_schedule'), scheduleStr),
                  if (memo.isNotEmpty) _infoRow(_t('inbox_memo'), memo),
                  if (photos.isNotEmpty) ...[
                    Text(
                      _t('inbox_photos'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photos[i].toString(),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _quoteSent ? Colors.grey : _kRoyalBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed:
                          _quoteSent ? null : _showQuoteBottomSheet,
                      child: Text(
                        _quoteSent
                            ? _t('quote_already_sent')
                            : _t('quote_btn_send'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
