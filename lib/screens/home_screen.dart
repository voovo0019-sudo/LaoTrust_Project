// =============================================================================
// LT-04 Home Dashboard · 70:30 레이아웃 + Apply 버튼
// 상단 70% 그리드 서비스, 하단 30% 급구 알바 + 적용 버튼. 인디고 블루 테마.
// =============================================================================

import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../features/request_flow/request_flow_screen.dart';

/// 홈 화면: 70:30 동선. 상단 70% 전문가 서비스 그리드, 하단 30% 급구 알바 + 적용 버튼.
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
                PopupMenuItem(value: const Locale('ko'), child: Text(context.l10n('lang_ko'))),
                PopupMenuItem(value: const Locale('en'), child: Text(context.l10n('lang_en'))),
                PopupMenuItem(value: const Locale('lo'), child: Text(context.l10n('lang_lo'))),
              ],
            ),
          if (onThemeModeChanged != null)
            IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                onThemeModeChanged!(
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 검색 + 전문가 서비스
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(context),
                  const SizedBox(height: 28),
                  Text(
                    context.l10n('section_expert_headline'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n('section_expert_services'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // 1행: 청소, 경비, 수리, 배달
                      _ServiceIcon(
                        icon: Icons.cleaning_services_outlined,
                        label: context.l10n('expert_cleaning'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_cleaning')),
                      ),
                      _ServiceIcon(
                        icon: Icons.shield,
                        label: context.l10n('expert_security'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_security')),
                      ),
                      _ServiceIcon(
                        icon: Icons.build,
                        label: context.l10n('expert_repair'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_repair')),
                      ),
                      _ServiceIcon(
                        icon: Icons.delivery_dining,
                        label: context.l10n('expert_delivery'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_delivery')),
                      ),
                      // 2행: 뷰티, 과외, 사진, 이벤트
                      _ServiceIcon(
                        icon: Icons.brush,
                        label: context.l10n('expert_beauty'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_beauty')),
                      ),
                      _ServiceIcon(
                        icon: Icons.school,
                        label: context.l10n('expert_tutoring'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_tutoring')),
                      ),
                      _ServiceIcon(
                        icon: Icons.photo_camera,
                        label: context.l10n('expert_photo'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_photo')),
                      ),
                      _ServiceIcon(
                        icon: Icons.emoji_events,
                        label: context.l10n('expert_event'),
                        onTap: () => _openRequestFlow(context, category: context.l10n('expert_event')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 하단: 급구 알바 + 적용 버튼 (네비게이션 바 바로 위)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n('section_quick_jobs'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _QuickJobCardsSection(colorScheme: colorScheme),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(context.l10n('apply')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

/// 숨고 스타일 세련된 카테고리 아이콘 — 아이콘 크기·간격 조정, 화이트 & 인디고 블루
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
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        highlightColor: colorScheme.primary.withValues(alpha: 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
              child: Icon(icon, color: Colors.blue, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 급구 알바 가로 스크롤 리스트 — PC/모바일 동일 동작
class _QuickJobCardsSection extends StatelessWidget {
  const _QuickJobCardsSection({required this.colorScheme});
  final ColorScheme colorScheme;

  static const List<Map<String, dynamic>> _cards = [
    {'titleKey': 'job_title_restaurant_server', 'locationKey': 'location_near_vientiane_hall', 'salaryKey': 'salary_15k_per_hour', 'urgent': true},
    {'titleKey': 'job_title_simple_labor', 'locationKey': 'location_near_that_luang', 'salaryKey': 'salary_negotiable', 'urgent': false},
    {'titleKey': 'job_title_delivery_helper', 'locationKey': 'location_downtown', 'salaryKey': 'salary_12k_per_hour', 'urgent': true},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < _cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Builder(
              builder: (context) {
                final c = _cards[i];
                return _QuickJobCard(
                  titleKey: c['titleKey']! as String,
                  locationKey: c['locationKey']! as String,
                  salaryKey: c['salaryKey']! as String,
                  isUrgent: c['urgent']! as bool,
                  onTap: () {},
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// 알바몬 스타일 카드 — 전체 너비, 높이 내용 기반, 3줄+ 허용, 라오어 여유 패딩
class _QuickJobCard extends StatelessWidget {
  const _QuickJobCard({
    required this.titleKey,
    required this.locationKey,
    required this.salaryKey,
    required this.isUrgent,
    required this.onTap,
  });
  final String titleKey;
  final String locationKey;
  final String salaryKey;
  final bool isUrgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLao = Localizations.localeOf(context).languageCode == 'lo';
    final padding = isLao ? 12.0 : 10.0;
    // 슬림 카드: 고정 가로 200, 세로 120 (박스 다이어트)
    const double cardWidth = 200.0;
    const double cardHeight = 120.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: ClipRect(
          child: Container(
            width: cardWidth,
            height: cardHeight,
            padding: EdgeInsets.fromLTRB(padding, padding, padding, padding),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 + 급구 태그 (한 줄, 넘치면 ellipsis)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n(titleKey),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n('tag_deadline_soon'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // 위치 (한 줄)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.l10n(locationKey),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 급여 + 화살표 (한 줄)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n(salaryKey),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: colorScheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
