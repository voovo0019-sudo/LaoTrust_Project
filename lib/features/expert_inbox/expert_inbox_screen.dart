import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/translation_mapper.dart';
import 'expert_inbox_detail_screen.dart';

const Color _kRoyalBlue = Color(0xFF1E3A8A);

class ExpertInboxScreen extends StatelessWidget {
  const ExpertInboxScreen({super.key});

  String _langCode(BuildContext context) {
    final raw = Localizations.localeOf(context).languageCode.toLowerCase();
    if (raw.startsWith('ko')) return 'ko';
    if (raw.startsWith('lo')) return 'lo';
    return 'en';
  }

  String _t(BuildContext context, String key) {
    final lang = _langCode(context);
    return kStaticUiTripleByMessageKey[key]?[lang] ?? key;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'accepted':
        return _t(context, 'inbox_status_accepted');
      case 'rejected':
        return _t(context, 'inbox_status_rejected');
      default:
        return _t(context, 'inbox_status_pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _langCode(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        title: Text(
          _t(context, 'inbox_title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artifacts')
            .doc('laotrust-web')
            .collection('public')
            .doc('data')
            .collection('requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                _t(context, 'inbox_empty'),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final status = data['status'] as String? ?? 'pending';
              final category = data['category'] as String? ?? '';
              final createdAt = data['createdAt'];
              String dateStr = '';
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                dateStr =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              }
              final wizardI18n = data['wizardI18n'] as Map<String, dynamic>?;
              final titleMap = wizardI18n?['title'] as Map<String, dynamic>?;
              final displayTitle = titleMap?[lang] as String? ?? category;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpertInboxDetailScreen(
                          docId: docId,
                          data: data,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _kRoyalBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inbox_rounded,
                            color: _kRoyalBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _kRoyalBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _statusColor(status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _statusLabel(context, status),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
