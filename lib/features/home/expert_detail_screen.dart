// =============================================================================
// LaoTrust 전문가 상세 페이지 v2.0
// A: 위저드 연결 / B: bio + 태그 / C: 리뷰 섹션
// =============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/translation_mapper.dart';
import '../universal_wizard/universal_wizard_screen.dart';

const Color _kRoyalBlue = Color(0xFF1E3A8A);
const Color _kRoyalNavy = Color(0xFF1E293B);
const Color _kMekongGold = Color(0xFFF5B731);

class ExpertDetailScreen extends StatelessWidget {
  const ExpertDetailScreen({
    super.key,
    required this.expertId,
    required this.data,
  });

  final String expertId;
  final Map<String, dynamic> data;

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
  Widget build(BuildContext context) {
    final lang = _langCode(context);
    final name =
        (data['name_$lang'] as String?) ?? (data['name_ko'] as String?) ?? 'Expert';
    final category = data['category'] as String? ?? '';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final isVerified = data['isVerified'] as bool? ?? false;
    final isAvailable = data['isAvailable'] as bool? ?? false;
    final bio = (data['bio_$lang'] as String?) ??
        (data['bio_en'] as String?) ??
        (data['bio_ko'] as String?) ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _kRoyalBlue,
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _kRoyalBlue.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person,
                      color: _kRoyalBlue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kRoyalNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n(category.isNotEmpty ? category : 'expert_repair'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kRoyalBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kRoyalBlue),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  color: _kRoyalBlue, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _t(context, 'expert_verified_badge'),
                                style: const TextStyle(
                                  color: _kRoyalBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isVerified) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAvailable ? Colors.green : Colors.grey,
                          ),
                        ),
                        child: Text(
                          isAvailable
                              ? _t(context, 'expert_status_available')
                              : _t(context, 'expert_status_unavailable'),
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // B: bio 섹션
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 평점 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: _kMekongGold, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _kRoyalNavy,
                        ),
                      ),
                      Text(
                        _t(context, 'expert_rating_label'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // C: 리뷰 섹션
            Text(
              _t(context, 'expert_reviews_title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kRoyalNavy,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('experts')
                  .doc(expertId)
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _kRoyalBlue,
                      strokeWidth: 2,
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      _t(context, 'expert_reviews_empty'),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final reviewer = (d['reviewer_$lang'] as String?) ??
                        (d['reviewer_en'] as String?) ??
                        (d['reviewer_ko'] as String?) ??
                        '';
                    final comment = (d['comment_$lang'] as String?) ??
                        (d['comment_en'] as String?) ??
                        (d['comment_ko'] as String?) ??
                        '';
                    final reviewRating = (d['rating'] as num?)?.toDouble() ?? 5.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                reviewer,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _kRoyalNavy,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  reviewRating.round(),
                                  (_) => const Icon(
                                    Icons.star_rounded,
                                    color: _kMekongGold,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            // A: 서비스 신청 → 위저드 연결
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    UniversalWizardScreen.routeName,
                    arguments: <String, dynamic>{
                      'categoryKey': category.isNotEmpty ? category : 'expert_repair',
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRoyalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  _t(context, 'expert_request_service'),
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
