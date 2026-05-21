import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';
import '../../data/firestore_schema.dart';
import '../../firebase_options.dart';

const Color _kRoyalBlue = Color(0xFF1E3A8A);

class ExpertInboxScreen extends StatefulWidget {
  const ExpertInboxScreen({super.key});

  @override
  State<ExpertInboxScreen> createState() => _ExpertInboxScreenState();
}

class _ExpertInboxScreenState extends State<ExpertInboxScreen> {
  List<String> _expertCategories = [];
  late Future<void> _categoriesReady;

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
  void initState() {
    super.initState();
    _categoriesReady = _loadExpertCategories();
  }

  /// 전문가 등록 categories 로드. 실패·오프라인 시 빈 배열 → 전체 표시(하위 호환).
  Future<void> _loadExpertCategories() async {
    try {
      if (!isFirebaseEnabled) return;
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      final doc = await firestore
          .collection(kColUsers)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final data = doc.data();
      if (data != null && data['categories'] is List) {
        _expertCategories = List<String>.from(data['categories']);
      }
    } catch (_) {
      // 로드 실패 시 _expertCategories 비어 있음 → 전체 표시
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
      body: !isFirebaseEnabled || !hasRecognizedUserSession
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 64,
                      color: _kRoyalBlue.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _t(context, 'inbox_login_required_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _t(context, 'inbox_login_required_desc'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRoyalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: Text(_t(context, 'inbox_login_btn')),
                      onPressed: () => context.push('/login'),
                    ),
                  ],
                ),
              ),
            )
          : FutureBuilder<void>(
              future: _categoriesReady,
              builder: (context, catSnapshot) {
                if (catSnapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('artifacts')
                      .doc(
                          DefaultFirebaseOptions.currentPlatform.projectId)
                      .collection('public')
                      .doc('data')
                      .collection('requests')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
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
                    var docs = snapshot.data!.docs;
                    if (_expertCategories.isNotEmpty) {
                      docs = docs.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final categoryKey =
                            data['categoryKey'] as String? ?? '';
                        return _expertCategories.contains(categoryKey);
                      }).toList();
                    }
                    if (docs.isEmpty) {
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
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data()
                            as Map<String, dynamic>;
                        final docId = docs[index].id;
                        final status =
                            data['status'] as String? ?? 'pending';
                        final categoryKey =
                            data['categoryKey'] as String? ?? '';
                        final createdAt = data['createdAt'];
                        String dateStr = '';
                        if (createdAt is Timestamp) {
                          final dt = createdAt.toDate();
                          dateStr =
                              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                        }
                        final wizardI18n =
                            data['wizardI18n'] as Map<String, dynamic>?;
                        final titleMap =
                            wizardI18n?['title'] as Map<String, dynamic>?;
                        final rawTitle = titleMap?[lang] as String? ??
                            _t(context,
                                'cat_${categoryKey.replaceAll('expert_', '')}');
                        final titleParts = rawTitle.split(' · ');
                        final categoryTitle = titleParts.first.trim();
                        final subTypeTitle = titleParts.length > 1
                            ? titleParts.skip(1).join(' · ').trim()
                            : '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.push(
                                '/expert_inbox_detail',
                                extra: <String, dynamic>{
                                  'docId': docId,
                                  'data': data,
                                },
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
                                      color: _kRoyalBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inbox_rounded,
                                      color: _kRoyalBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: _kRoyalBlue,
                                          ),
                                        ),
                                        if (subTypeTitle.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                              subTypeTitle,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
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
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
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
                );
              },
            ),
    );
  }
}
