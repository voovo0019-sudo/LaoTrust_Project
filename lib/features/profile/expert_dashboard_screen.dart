// =============================================================================
// LT-09 Feature: profile — 전문가 전용 대시보드 (수입·매칭 이력 뼈대)
// v1.3: 출동 준비 토글(Duty Toggle). OFF 시 Firestore lat/lng 즉시 null(잠복).
// Trust-first: Verified 카드. Firestore 연동 시 data/firestore_schema 참고. 한/영 주석.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../../core/verified_badge_service.dart';
import '../../core/location_service.dart';
import '../../services/expert_availability_service.dart';

const String expertDashboardRouteName = '/expert-dashboard';
const Color _royalNavy = Color(0xFF1E293B);

class ExpertDashboardScreen extends StatefulWidget {
  const ExpertDashboardScreen({super.key});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  bool _verified = false;
  bool _dutyOn = false;
  bool _dutyLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVerified();
  }

  Future<void> _loadVerified() async {
    final v = await isVerifiedBadgeActive();
    final duty = await getExpertDutyStatus();
    if (mounted) {
      setState(() {
        _verified = v;
        _dutyOn = duty;
      });
    }
  }

  Future<void> _toggleDuty(bool value) async {
    setState(() => _dutyLoading = true);
    try {
      if (value) {
        final (loc, _) = await getUserLocationOrDefault();
        await setExpertDuty(true, lat: loc.latitude, lng: loc.longitude);
        if (mounted) {
          setState(() => _dutyOn = true);
        }
      } else {
        await setExpertDuty(false);
        if (mounted) {
          setState(() => _dutyOn = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dutyOn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가용성 설정에 실패했습니다. 위치 권한을 확인하세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _dutyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _royalNavy,
        foregroundColor: Colors.white,
        title: Text(context.l10n('expert_dashboard_title')),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVerified,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDutyToggleCard(context),
              const SizedBox(height: 16),
              _buildVerifiedCard(context, theme, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, context.l10n('expert_dashboard_income_section')),
              const SizedBox(height: 8),
              _buildPlaceholderCard(colorScheme, context.l10n('expert_dashboard_total_income'), context.l10n('expert_dashboard_usd_zero'), Icons.account_balance_wallet),
              const SizedBox(height: 16),
              _buildSectionTitle(theme, context.l10n('expert_dashboard_matching_section')),
              const SizedBox(height: 8),
              _buildPlaceholderCard(colorScheme, context.l10n('expert_dashboard_month_matching'), context.l10n('expert_dashboard_count_zero'), Icons.handshake),
              const SizedBox(height: 8),
              _buildPlaceholderCard(colorScheme, context.l10n('expert_dashboard_total_completed'), context.l10n('expert_dashboard_count_zero'), Icons.check_circle_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDutyToggleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _royalNavy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: _royalNavy, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '지금 의뢰 받기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _royalNavy),
                ),
                const SizedBox(height: 2),
                Text(
                  _dutyOn ? '고객이 나를 찾을 수 있어요' : 'OFF 시 위치 잠복·리스트에서 숨김',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (_dutyLoading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(
              value: _dutyOn,
              onChanged: _toggleDuty,
              activeTrackColor: _royalNavy.withValues(alpha: 0.5),
              activeThumbColor: _royalNavy,
            ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCard(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    _verified ? context.l10n('expert_dashboard_verified_label') : context.l10n('expert_dashboard_apply_label'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _verified
                        ? context.l10n('expert_dashboard_badge_hint')
                        : context.l10n('expert_dashboard_badge_todo'),
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
