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
  List<String> _quotedRequestIds = [];
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

  @override
  void initState() {
    super.initState();
    _categoriesReady = _loadExpertData();
  }

  /// 전문가 categories + quotedRequestIds 한 번에 로드
  Future<void> _loadExpertData() async {
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
      if (data != null) {
        if (data['categories'] is List) {
          _expertCategories = List<String>.from(data['categories']);
        }
        if (data[UserFields.quotedRequestIds] is List) {
          _quotedRequestIds =
              List<String>.from(data[UserFields.quotedRequestIds]);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = _langCode(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        title: Text(
          _t(context, 'expert_inbox_title'),
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
                      .doc(DefaultFirebaseOptions.currentPlatform.projectId)
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
                          _t(context, 'expert_inbox_empty'),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    final myUid = auth.currentUser?.uid ?? '';
                    var docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final categoryKey =
                          data['categoryKey'] as String? ?? '';
                      final requestUserId =
                          data[RequestFields.userId] as String? ?? '';
                      // ① 내가 올린 요청 제외 (손님 차단)
                      if (requestUserId == myUid) return false;
                      // ② 전문가 카테고리 없으면 아무것도 안 보임 (전문가 아닌 유저 차단)
                      if (_expertCategories.isEmpty) return false;
                      // ③ 내 담당 카테고리만
                      return _expertCategories.contains(categoryKey);
                    }).toList();
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          _t(context, 'expert_inbox_empty'),
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
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        final docId = docs[index].id;
                        final isQuoted = _quotedRequestIds.contains(docId);
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
                        final titleParts = rawTitle.split(' ? ');
                        final categoryTitle = titleParts.first.trim();
                        final subTypeTitle = titleParts.length > 1
                            ? titleParts.skip(1).join(' ? ').trim()
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
                                            padding: const EdgeInsets.only(
                                                top: 2),
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
                                  // 견적 발송 여부 기반 상태 배지
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isQuoted
                                              ? Colors.green
                                              : Colors.orange)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isQuoted
                                            ? Colors.green
                                            : Colors.orange,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isQuoted
                                          ? _t(context, 'expert_status_quoted')
                                          : _t(context, 'expert_status_new'),
                                      style: TextStyle(
                                        color: isQuoted
                                            ? Colors.green
                                            : Colors.orange,
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
