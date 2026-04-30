// =============================================================================
// MyRequestsScreen - 나의 신청현황 (독립 파일)
// 원본 분리 출처: profile_screen.dart에서 분리
// =============================================================================
import 'dart:async' show TimeoutException;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';

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

  // status 영어값 → 번역키 매핑
  static const Map<String, String> _statusToKey = {
    'pending': 'status_pending',
    'in_progress': 'status_in_progress',
    'completed': 'status_completed',
    'cancelled': 'status_cancelled',
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
          .collectionGroup('requests')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10));
      final docs = snapshot.docs;

      return docs;
    } on TimeoutException catch (_) {
      return const [];
    } catch (_) {
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

  // location 텍스트 추출 (현재 언어 기준)
  // 우선순위: wizardI18n.location[locale] → location.landmark → '-'
  String _extractLocationText(dynamic location, dynamic wizardI18n, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    // 1단계: wizardI18n.location에서 현재 언어 텍스트 찾기
    if (wizardI18n is Map) {
      final i18nLocation = wizardI18n['location'];
      if (i18nLocation is Map) {
        final localized = i18nLocation[locale]?.toString() ?? '';
        if (localized.isNotEmpty) return localized;
        // fallback: 영어
        final en = i18nLocation['en']?.toString() ?? '';
        if (en.isNotEmpty) return en;
      }
    }

    // 2단계: location Map에서 추출
    if (location is Map) {
      final landmark = location['landmark']?.toString() ?? '';
      if (landmark.isNotEmpty) return landmark;
      final from = location['from']?.toString() ?? '';
      final to = location['to']?.toString() ?? '';
      if (from.isNotEmpty && to.isNotEmpty) return '$from → $to';
      if (from.isNotEmpty) return from;
    }
    if (location is String && location.isNotEmpty) return location;
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

  // status 영어값 → 현재 언어 기준 표시명 변환
  String _resolveStatusName(String rawStatus, BuildContext context) {
    final key = _statusToKey[rawStatus.toLowerCase()];
    if (key != null) {
      final triple = kStaticUiTripleByMessageKey[key];
      if (triple != null) {
        final locale = Localizations.localeOf(context).languageCode;
        return triple[locale] ?? triple['en'] ?? rawStatus;
      }
      try {
        return context.l10n(key);
      } catch (_) {}
    }
    return rawStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
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
              final statusName = _resolveStatusName(rawStatus, context);
              final locationText = _extractLocationText(
                data['location'],
                data['wizardI18n'],
                context,
              );
              final createdAt = _formatDate(data['createdAt']);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(categoryName),
                  subtitle: Text('$locationText\n$createdAt'),
                  trailing: Text(
                    statusName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
