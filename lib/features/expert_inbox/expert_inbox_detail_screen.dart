import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/translation_mapper.dart';

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

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('laotrust-web')
          .collection('public')
          .doc('data')
          .collection('requests')
          .doc(widget.docId)
          .update({'status': status});
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndUpdate(String status) async {
    final confirmKey =
        status == 'accepted' ? 'inbox_accept_confirm' : 'inbox_reject_confirm';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Text(_t(confirmKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t('inbox_confirm_no')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRoyalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t('inbox_confirm_yes')),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus(status);
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
  Widget build(BuildContext context) {
    final data = widget.data;
    final lang = _langCode();
    final status = data['status'] as String? ?? 'pending';
    final wizardI18n = data['wizardI18n'] as Map<String, dynamic>?;

    String getI18n(String field) {
      final map = wizardI18n?[field] as Map<String, dynamic>?;
      return map?[lang] as String? ?? data[field]?.toString() ?? '';
    }

    final location = data['location'] as Map<String, dynamic>?;
    final locationStr = location?['landmark'] as String? ?? '';
    final schedule = data['schedule'] as Map<String, dynamic>?;
    final scheduleStr =
        schedule != null ? '${schedule['date'] ?? ''} ${schedule['time'] ?? ''}' : '';
    final memo = data['memo'] as String? ?? '';
    final photos = data['photos'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        title: Text(
          _t('inbox_detail_title'),
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
                  _infoRow(_t('inbox_category'), getI18n('title')),
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
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () => _confirmAndUpdate('rejected'),
                            child: Text(
                              _t('inbox_btn_reject'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kRoyalBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () => _confirmAndUpdate('accepted'),
                            child: Text(
                              _t('inbox_btn_accept'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        status == 'accepted'
                            ? _t('inbox_status_accepted')
                            : _t('inbox_status_rejected'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: status == 'accepted' ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
