// =============================================================================
// LT-04 Home Dashboard · LT-09 Feature: home (70:30 진입점)
// LT-11 핵심: 70% 그리드(섀도우+인디고) + 30% 급구 알바 가로 스크롤.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';
import '../request_flow/request_flow_screen.dart';

/// 홈 화면: 메인 대시보드 (LT-04). 70:30 동선. LT-11 신뢰 포인트(섀도우·인디고) 적용.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.themeMode = ThemeMode.dark,
    this.onThemeModeChanged,
    this.locale = const Locale('ko'),
    this.onLocaleChanged,
  });
  static const String routeName = '/';

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final Locale locale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n('app_title')),
        actions: [
          if (onLocaleChanged != null)
            PopupMenuButton<Locale>(
              icon: const Icon(Icons.language),
              tooltip: context.l10n('language'),
              onSelected: onLocaleChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(value: Locale('ko'), child: Text('한국어')),
                const PopupMenuItem(value: Locale('en'), child: Text('English')),
                const PopupMenuItem(value: Locale('lo'), child: Text('ພາສາລາວ')),
              ],
            ),
          if (onThemeModeChanged != null)
            IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                onThemeModeChanged!(
                  themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 24),
            Text(
              context.l10n('section_expert_services'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _ServiceIcon(
                  icon: Icons.ac_unit,
                  label: context.l10n('service_ac'),
                  onTap: () => _openRequestFlow(context, category: context.l10n('service_ac')),
                ),
                _ServiceIcon(
                  icon: Icons.build,
                  label: context.l10n('service_household'),
                  onTap: () => _openRequestFlow(context, category: context.l10n('service_household')),
                ),
                _ServiceIcon(
                  icon: Icons.electrical_services,
                  label: context.l10n('service_electric'),
                  onTap: () => _openRequestFlow(context, category: context.l10n('service_electric')),
                ),
                _ServiceIcon(
                  icon: Icons.plumbing,
                  label: context.l10n('service_plumbing'),
                  onTap: () => _openRequestFlow(context, category: context.l10n('service_plumbing')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n('section_quick_jobs'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _QuickJobCardsSection(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n('search_placeholder'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openRequestFlow(BuildContext context, {required String category}) {
    Navigator.pushNamed(
      context,
      RequestFlowScreen.routeName,
      arguments: RequestFlowArgs(category: category),
    );
  }
}

/// LT-11: 신뢰 포인트 — 섀도우 + 인디고 블루 (디지털 캡슐 v1.5)
class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// LT-11: 30% 급구 알바 — 가로 스크롤 카드, 섀도우 + 인디고
class _QuickJobCardsSection extends StatelessWidget {
  const _QuickJobCardsSection({required this.colorScheme});
  final ColorScheme colorScheme;

  static const List<Map<String, String>> _cards = [
    {'title': '식당 서버', 'location': '비엔티안 시청 인근', 'salary': '15,000 LAK/시간'},
    {'title': '단순 노무', 'location': '타락광장 근처', 'salary': '협의'},
    {'title': '배달 도우미', 'location': '시내 중심가', 'salary': '12,000 LAK/시간'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = _cards[index];
          return _QuickJobCard(
            title: c['title']!,
            location: c['location']!,
            salary: c['salary']!,
            onTap: () {},
          );
        },
      ),
    );
  }
}

/// LT-11: 카드 섀도우 + 인디고 포인트
class _QuickJobCard extends StatelessWidget {
  const _QuickJobCard({
    required this.title,
    required this.location,
    required this.salary,
    required this.onTap,
  });
  final String title;
  final String location;
  final String salary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$location · $salary',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
