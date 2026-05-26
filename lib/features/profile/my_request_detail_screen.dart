// =============================================================================
// MyRequestDetailScreen - 고객용 신청 상세 화면 v2.0
// 전문가용 거절하기/수락하기 버튼 없음. 고객 전용.
// =============================================================================
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/translation_mapper.dart';
import 'package:lao_trust/firebase_options.dart';

class MyRequestDetailScreen extends StatefulWidget {
  const MyRequestDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  final String docId;
  final Map<String, dynamic> data;

  @override
  State<MyRequestDetailScreen> createState() => _MyRequestDetailScreenState();
}

class _MyRequestDetailScreenState extends State<MyRequestDetailScreen> {
  bool _isCancelling = false;
  StreamSubscription<DocumentSnapshot>? _subscription;
  Map<String, dynamic>? _liveData;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(DefaultFirebaseOptions.currentPlatform.projectId)
        .collection('public')
        .doc('data')
        .collection('requests')
        .doc(widget.docId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (snap.exists) {
        setState(() {
          _liveData = snap.data() as Map<String, dynamic>;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

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

  // 카테고리 번역 (영문 → 현재 언어)
  String _resolveCategory(Map<String, dynamic> data) {
    final lang = _langCode();
    // 1순위: categoryKey로 Triple-Map 조회
    final categoryKey = data['categoryKey']?.toString() ?? '';
    if (categoryKey.isNotEmpty) {
      final triple = kStaticUiTripleByMessageKey[categoryKey];
      if (triple != null) return triple[lang] ?? triple['en'] ?? categoryKey;
    }
    // 2순위: wizardI18n.category
    final wizardI18n = data['wizardI18n'];
    if (wizardI18n is Map) {
      final cat = wizardI18n['category'];
      if (cat is Map) return cat[lang]?.toString() ?? cat['ko']?.toString() ?? cat['en']?.toString() ?? '';
      if (cat is String && cat.isNotEmpty) return cat;
    }
    // 3순위: category 영문 → 키 매핑
    final englishToKey = {
      'Cleaning': 'expert_cleaning',
      'Moving': 'expert_moving',
      'Repair': 'expert_repair',
      'Interior': 'expert_interior',
      'Business': 'expert_business',
      'Beauty': 'expert_beauty',
      'Lessons': 'expert_tutoring',
      'Events': 'expert_events',
      'Vehicle': 'expert_vehicle',
    };
    final rawCat = data['category']?.toString() ?? '';
    final mappedKey = englishToKey[rawCat];
    if (mappedKey != null) {
      final triple = kStaticUiTripleByMessageKey[mappedKey];
      if (triple != null) return triple[lang] ?? triple['en'] ?? rawCat;
    }
    return rawCat;
  }

  // 희망일시 파싱 (Map → 보기 좋은 문자열)
  String _resolveSchedule(Map<String, dynamic> data) {
    final schedule = data['schedule'];
    if (schedule is Map) {
      final date = schedule['date']?.toString() ?? '';
      final time = schedule['time']?.toString() ?? '';
      final isUrgent = schedule['isUrgent'];
      String result = '';
      if (date.isNotEmpty) result += date;
      if (time.isNotEmpty) result += ' $time';
      if (isUrgent == true) result += ' ⚡';
      return result.isNotEmpty ? result : '-';
    }
    // wizardI18n.schedule
    final lang = _langCode();
    final wizardI18n = data['wizardI18n'];
    if (wizardI18n is Map) {
      final sch = wizardI18n['schedule'];
      if (sch is Map) {
        return sch[lang]?.toString() ?? sch['ko']?.toString() ?? sch['en']?.toString() ?? '-';
      }
    }
    return schedule?.toString() ?? '-';
  }

  String _resolveLocation(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>?;
    if (location == null) return '-';
    final lang = _langCode();
    final wizardI18n = data['wizardI18n'];
    if (wizardI18n is Map) {
      final loc = wizardI18n['location'];
      if (loc is Map) {
        final translated = loc[lang]?.toString() ?? loc['ko']?.toString() ?? loc['en']?.toString() ?? '';
        if (translated.isNotEmpty) return translated;
      }
    }
    final landmark = location['landmark']?.toString() ?? '';
    final fromLandmark = location['fromLandmark']?.toString() ?? '';
    final toLandmark = location['toLandmark']?.toString() ?? '';
    if (fromLandmark.isNotEmpty && toLandmark.isNotEmpty) {
      return '$fromLandmark → $toLandmark';
    }
    return landmark.isNotEmpty ? landmark : '-';
  }

  // 상세내용 (wizardI18n.detail 우선)
  String _resolveDetail(Map<String, dynamic> data) {
    final lang = _langCode();
    final wizardI18n = data['wizardI18n'];
    if (wizardI18n is Map) {
      final detail = wizardI18n['detail'];
      if (detail is Map) {
        return detail[lang]?.toString() ?? detail['ko']?.toString() ?? detail['en']?.toString() ?? '-';
      }
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return data['detail']?.toString() ?? '-';
  }

  // 상태 번역
  String _resolveStatus(String status) {
    final statusToKey = {
      'pending': 'status_pending',
      'accepted': 'status_accepted',
      'in_progress': 'status_in_progress',
      'completed': 'status_completed',
      'cancelled': 'status_cancelled',
    };
    final key = statusToKey[status.toLowerCase()];
    if (key != null) {
      final triple = kStaticUiTripleByMessageKey[key];
      if (triple != null) return triple[_langCode()] ?? triple['en'] ?? status;
    }
    return status;
  }

  Widget _buildMatchedExpertCard(Map<String, dynamic> data) {
    final acceptedBy = data['acceptedBy'];
    if (acceptedBy is! Map) return const SizedBox.shrink();
    final name = acceptedBy['name']?.toString() ?? '';
    final email = acceptedBy['email']?.toString() ?? '';
    final acceptedAt = acceptedBy['acceptedAt']?.toString() ?? '';
    String timeStr = '';
    if (acceptedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(acceptedAt).toLocal();
        timeStr =
            '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        timeStr = acceptedAt;
      }
    }
    return Card(
      elevation: 0,
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user,
                    color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 6),
                Text(
                  _t('matched_expert_title'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (name.isNotEmpty)
              _InfoRow(
                label: _t('matched_expert_name'),
                value: name,
                icon: Icons.person_outline,
              ),
            if (email.isNotEmpty)
              _InfoRow(
                label: _t('matched_expert_contact'),
                value: email,
                icon: Icons.email_outlined,
              ),
            if (timeStr.isNotEmpty)
              _InfoRow(
                label: _t('matched_at'),
                value: timeStr,
                icon: Icons.access_time,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(_t('my_request_cancel_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t('inbox_confirm_no')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t('my_request_cancel_btn')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isCancelling = true);
    try {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(DefaultFirebaseOptions.currentPlatform.projectId)
          .collection('public')
          .doc('data')
          .collection('requests')
          .doc(widget.docId)
          .update({'status': 'cancelled'});
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('error_update_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _liveData ?? widget.data;
    final status = (data['status'] ?? 'pending').toString();
    final photos = data['photos'];
    final photoUrls = photos is List
        ? photos.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final category = _resolveCategory(data);
    final schedule = _resolveSchedule(data);
    final detail = _resolveDetail(data);
    final location = _resolveLocation(data);
    final memoI18n = data['memoI18n'];
    final lang = _langCode();
    String memo = '';
    if (memoI18n is Map) {
      memo = memoI18n[lang]?.toString() ??
          memoI18n['ko']?.toString() ??
          memoI18n['en']?.toString() ??
          '';
    }
    if (memo.isEmpty) memo = data['memo']?.toString() ?? '';
    final statusText = _resolveStatus(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        title: Text(_t('my_request_detail_title')),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 상태 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 본문 카드
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 매칭된 전문가 카드 (accepted 상태일 때만 노출)
                  if (status == 'accepted') ...[
                    _buildMatchedExpertCard(data),
                    const SizedBox(height: 12),
                  ],
                  // 상세 정보 카드
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(label: _t('schedule_label'), value: schedule, icon: Icons.calendar_today),
                          _InfoRow(label: _t('detail_label'), value: detail, icon: Icons.description_outlined),
                          _InfoRow(label: _t('location_label'), value: location, icon: Icons.location_on_outlined),
                          _InfoRow(
                            label: _t('memo_label'),
                            value: memo.isNotEmpty ? memo : _t('no_memo'),
                            icon: Icons.note_outlined,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 사진 카드
                  if (photoUrls.isNotEmpty) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_library_outlined,
                                    size: 18, color: Color(0xFF3F51B5)),
                                const SizedBox(width: 8),
                                Text(
                                  _t('photos_label'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3F51B5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: photoUrls.map((url) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 버튼 영역
                  Row(
                    children: [
                      // 닫기 버튼 (항상 표시)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3F51B5),
                            side: const BorderSide(color: Color(0xFF3F51B5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(_t('close_btn')),
                        ),
                      ),
                      // 신청 취소 버튼 (pending 상태일 때만)
                      if (status == 'pending') ...[
                        const SizedBox(width: 12),
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
                            onPressed: _isCancelling ? null : _cancelRequest,
                            child: _isCancelling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Text(_t('my_request_cancel_btn')),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3F51B5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        if (!isLast) const Divider(height: 24),
        if (isLast) const SizedBox(height: 4),
      ],
    );
  }
}
