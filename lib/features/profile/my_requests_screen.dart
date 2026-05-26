// =============================================================================
// MyRequestsScreen - 나의 신청현황 (독립 파일)
// 원본 분리 출처: profile_screen.dart에서 분리
// =============================================================================
import 'dart:async' show TimeoutException;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lao_trust/firebase_options.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';
import 'my_request_detail_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  static const String routePath = '/my_requests';

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _future;
  bool _isRetrying = false;

  // 기존 데이터 역방향 매핑 (category 영어 표시명 → categoryKey)
  static const Map<String, String> _englishToKey = {
    'Cleaning': 'expert_cleaning',
    'Moving': 'expert_moving',
    'Repair': 'expert_repair',
    'Interior': 'expert_interior',
    'Business': 'expert_business',
    'Beauty': 'expert_beauty',
    'Lessons': 'expert_tutoring',
    'Events': 'expert_events',
    'Vehicle': 'expert_vehicle',
    'Other': 'category_other',
  };

  @override
  void initState() {
    super.initState();
    _future = _loadMyRequests();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadMyRequests() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return const [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(DefaultFirebaseOptions.currentPlatform.projectId)
          .collection('public')
          .doc('data')
          .collection('requests')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.docs;
    } on TimeoutException catch (e) {
      debugPrint('[MyRequests] 타임아웃 에러: $e');
      return const [];
    } catch (e, stack) {
      debugPrint('[MyRequests] 조회 에러: $e');
      debugPrint('[MyRequests] 스택: $stack');
      return const [];
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _future = _loadMyRequests();
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isRetrying = false);
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  // categoryKey 또는 영어 표시명 → 현재 언어 기준 표시명 변환
  String _resolveCategoryName(String rawKey, BuildContext context) {
    // 1단계: rawKey가 이미 expert_* 형태면 바로 트리플맵에서 찾기
    final triple = kStaticUiTripleByMessageKey[rawKey];
    if (triple != null) {
      final locale = Localizations.localeOf(context).languageCode;
      return triple[locale] ?? triple['en'] ?? rawKey;
    }
    // 2단계: 영어 표시명(기존 데이터) → expert_* 키로 역방향 변환 후 재시도
    final mappedKey = _englishToKey[rawKey];
    if (mappedKey != null) {
      final triple2 = kStaticUiTripleByMessageKey[mappedKey];
      if (triple2 != null) {
        final locale = Localizations.localeOf(context).languageCode;
        return triple2[locale] ?? triple2['en'] ?? rawKey;
      }
    }
    // 3단계: l10n JSON fallback
    try {
      return context.l10n(rawKey);
    } catch (_) {
      return rawKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/main'),
        ),
        title: Text(context.l10n('profile_menu_my_requests')),
        actions: [
          IconButton(
            icon: _isRetrying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _retry,
          ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n('profile_my_requests_load_failed'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n('retry')),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n('profile_my_requests_empty')),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n('retry')),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              // categoryKey 우선, 없으면 category(영어 표시명) fallback
              final rawKey = (data['categoryKey'] ?? data['category'] ?? '').toString();
              final categoryName = rawKey.isNotEmpty
                  ? _resolveCategoryName(rawKey, context)
                  : context.l10n('request_complete_title');
              final rawStatus = (data['status'] ?? 'pending').toString();
              final createdAt = _formatDate(data['createdAt']);
              // wizardI18n.title 우선 표시
              final wizardI18n = data['wizardI18n'];
              String displayTitle = categoryName;
              if (wizardI18n is Map) {
                final title = wizardI18n['title'];
                if (title is Map) {
                  final locale = Localizations.localeOf(context).languageCode;
                  final localized = title[locale]?.toString() ?? title['ko']?.toString() ?? title['en']?.toString() ?? '';
                  if (localized.isNotEmpty) displayTitle = localized;
                }
              }

              final lang = Localizations.localeOf(context)
                      .languageCode
                      .toLowerCase()
                      .startsWith('ko')
                  ? 'ko'
                  : Localizations.localeOf(context)
                          .languageCode
                          .toLowerCase()
                          .startsWith('lo')
                      ? 'lo'
                      : 'en';
              String statusText(String key) =>
                  kStaticUiTripleByMessageKey[key]?[lang] ?? key;
              Color statusColor;
              String statusName;
              switch (rawStatus.toLowerCase()) {
                case 'accepted':
                  statusColor = const Color(0xFF4CAF50);
                  statusName = statusText('status_accepted');
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  statusName = statusText('status_rejected');
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  statusName = statusText('status_cancelled');
                  break;
                case 'completed':
                  statusColor = const Color(0xFF3F51B5);
                  statusName = statusText('status_completed');
                  break;
                default:
                  statusColor = const Color(0xFFFF9800);
                  statusName = statusText('status_pending');
              }

              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyRequestDetailScreen(
                        docId: docs[index].id,
                        data: data,
                      ),
                    ),
                  );
                  if (result == true) _retry();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 왼쪽 아이콘
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: Color(0xFF3F51B5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 중앙 텍스트
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Color(0xFF888888),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    createdAt,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 오른쪽 상태 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            statusName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
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
