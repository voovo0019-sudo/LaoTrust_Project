// =============================================================================
// LT-09 Feature: profile — 내 정보 관리, [포인트/결제], [나의 신청 현황], [고객센터]
// Trust-first: Verified 상태 표시. 유지: 하단 내비에서 진입.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/verified_badge_service.dart';
import 'bcel_onepay_screen.dart';
import 'expert_dashboard_screen.dart';

const String profileRouteName = '/profile';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text(context.l10n('profile')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n('profile_header'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileHeader(theme, colorScheme),
          const SizedBox(height: 20),
          _buildMenuTile(
            context,
            icon: Icons.account_balance_wallet,
            title: context.l10n('profile_menu_payment'),
            subtitle: '포인트 충전 및 결제 수단 등록',
            onTap: () => Navigator.pushNamed(context, bcelOnepayRouteName).then((_) => _loadVerified()),
          ),
          _buildMenuTile(
            context,
            icon: Icons.assignment,
            title: context.l10n('profile_menu_my_requests'),
            subtitle: '신청한 서비스 진행 현황',
            onTap: () {},
          ),
          _buildMenuTile(
            context,
            icon: Icons.support_agent,
            title: context.l10n('profile_menu_customer_service'),
            subtitle: '문의 및 도움말',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            context,
            icon: Icons.verified,
            title: context.l10n('verified_badge_apply'),
            subtitle: _verified ? '인증 완료' : '4.5 USD 결제 후 파란 배지 활성화',
            onTap: _verified ? null : () => Navigator.pushNamed(context, bcelOnepayRouteName).then((_) => _loadVerified()),
          ),
          _buildMenuTile(
            context,
            icon: Icons.dashboard,
            title: context.l10n('expert_dashboard'),
            subtitle: '수입·매칭 이력 보기',
            onTap: () => Navigator.pushNamed(context, expertDashboardRouteName),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 36, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '사용자',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_verified) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.verified, size: 22, color: colorScheme.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _verified ? 'Verified 전문가' : '인증 전',
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

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
