// =============================================================================
// LT-09 Feature: profile — 전문가 전용 대시보드 (수입·매칭 이력 뼈대)
// Trust-first: Verified 카드. Firestore 연동 시 data/firestore_schema 참고. 한/영 주석.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/verified_badge_service.dart';

const String expertDashboardRouteName = '/expert-dashboard';

class ExpertDashboardScreen extends StatefulWidget {
  const ExpertDashboardScreen({super.key});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _loadVerified();
  }

  Future<void> _loadVerified() async {
    final v = await isVerifiedBadgeActive();
    if (mounted) setState(() => _verified = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전문가 대시보드'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVerified,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVerifiedCard(theme, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, '수입 요약'),
              const SizedBox(height: 8),
              _buildPlaceholderCard(colorScheme, '총 수입', '0.00 USD', Icons.account_balance_wallet),
              const SizedBox(height: 16),
              _buildSectionTitle(theme, '매칭 이력'),
              const SizedBox(height: 8),
              _buildPlaceholderCard(colorScheme, '이번 달 매칭', '0건', Icons.handshake),
              const SizedBox(height: 8),
              _buildPlaceholderCard(colorScheme, '전체 완료 건수', '0건', Icons.check_circle_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _verified ? Icons.verified : Icons.verified_outlined,
              size: 40,
              color: _verified ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _verified ? 'Verified 전문가' : '인증 신청하기',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _verified
                        ? '파란 배지가 프로필에 표시됩니다.'
                        : '4.5 USD 결제 후 배지를 받을 수 있습니다.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPlaceholderCard(ColorScheme colorScheme, String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
      ),
    );
  }
}
