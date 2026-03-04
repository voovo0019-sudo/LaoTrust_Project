// =============================================================================
// LT-04 Home Dashboard · 70:30 레이아웃 + Apply 버튼
// 상단 70% 그리드 서비스, 하단 30% 급구 알바 + 적용 버튼. 인디고 블루 테마.
// =============================================================================

import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../features/request_flow/request_flow_screen.dart';
import '../services/firebase_service.dart';

final FirebaseService _firebaseService = FirebaseService();

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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firebaseService.getExpertServices(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              context.l10n('no_data_yet'),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              context.l10n('no_data_yet'),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      return GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: list.map<Widget>((e) {
                          final icon = _iconFromString(e['icon'] as String?);
                          final label = _labelFromExpertDoc(e, context);
                          final category = (e['category'] as String?) ?? label;
                          return _ServiceIcon(
                            icon: icon,
                            label: label,
                            onTap: () => _openRequestFlow(context, category: category),
                          );
                        }).toList(),
                      );
                    },
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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firebaseService.getQuickJobs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              context.l10n('no_data_yet'),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              context.l10n('no_data_yet'),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      return _QuickJobCardsSection(
                        colorScheme: colorScheme,
                        firebaseItems: list,
                      );
                    },
                  ),
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

IconData _iconFromString(String? name) {
  switch (name?.toLowerCase()) {
    case 'cleaning_services_outlined':
      return Icons.cleaning_services_outlined;
    case 'shield':
      return Icons.shield;
    case 'build':
      return Icons.build;
    case 'delivery_dining':
      return Icons.delivery_dining;
    case 'brush':
      return Icons.brush;
    case 'school':
      return Icons.school;
    case 'photo_camera':
      return Icons.photo_camera;
    case 'emoji_events':
      return Icons.emoji_events;
    default:
      return Icons.category;
  }
}

String _labelFromExpertDoc(Map<String, dynamic> doc, BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'lo' && doc['label_lo'] != null) return doc['label_lo'] as String;
  if (locale == 'ko' && doc['label_ko'] != null) return doc['label_ko'] as String;
  if (doc['label'] != null) return doc['label'] as String;
  final key = doc['labelKey'] as String?;
  if (key != null) return context.l10n(key);
  return doc['label_ko'] as String? ?? doc['label_lo'] as String? ?? '';
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

/// 급구 알바 가로 스크롤 리스트 — PC/모바일 동일 동작 (Firebase 실시간 연동)
class _QuickJobCardsSection extends StatelessWidget {
  const _QuickJobCardsSection({
    required this.colorScheme,
    this.firebaseItems,
  });
  final ColorScheme colorScheme;
  final List<Map<String, dynamic>>? firebaseItems;

  static const List<Map<String, dynamic>> _cards = [
    {'titleKey': 'job_title_restaurant_server', 'locationKey': 'location_near_vientiane_hall', 'salaryKey': 'salary_15k_per_hour', 'urgent': true},
    {'titleKey': 'job_title_simple_labor', 'locationKey': 'location_near_that_luang', 'salaryKey': 'salary_negotiable', 'urgent': false},
    {'titleKey': 'job_title_delivery_helper', 'locationKey': 'location_downtown', 'salaryKey': 'salary_12k_per_hour', 'urgent': true},
  ];

  @override
  Widget build(BuildContext context) {
    final items = firebaseItems ?? _cards;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Builder(
              builder: (context) {
                final c = items[i];
                final isFromFirebase = firebaseItems != null;
                return _QuickJobCard(
                  titleKey: c['titleKey'] as String?,
                  locationKey: c['locationKey'] as String?,
                  salaryKey: c['salaryKey'] as String?,
                  title: isFromFirebase ? (c['title'] as String?) : null,
                  location: isFromFirebase ? (c['location'] as String?) : null,
                  salary: isFromFirebase ? (c['salary'] as String?) : null,
                  isUrgent: (c['urgent'] as bool?) ?? false,
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

/// 알바몬 스타일 카드 — 전체 너비, 높이 내용 기반, 3줄+ 허용, 라오어 여유 패딩 (Firebase 직렬 표시 지원)
class _QuickJobCard extends StatelessWidget {
  const _QuickJobCard({
    this.titleKey,
    this.locationKey,
    this.salaryKey,
    this.title,
    this.location,
    this.salary,
    required this.isUrgent,
    required this.onTap,
  });
  final String? titleKey;
  final String? locationKey;
  final String? salaryKey;
  final String? title;
  final String? location;
  final String? salary;
  final bool isUrgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLao = Localizations.localeOf(context).languageCode == 'lo';
    final padding = isLao ? 12.0 : 10.0;
    const double cardWidth = 200.0;
    const double cardHeight = 120.0;
    final displayTitle = title ?? (titleKey != null ? context.l10n(titleKey!) : '');
    final displayLocation = location ?? (locationKey != null ? context.l10n(locationKey!) : '');
    final displaySalary = salary ?? (salaryKey != null ? context.l10n(salaryKey!) : '');

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        displayLocation,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displaySalary,
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
