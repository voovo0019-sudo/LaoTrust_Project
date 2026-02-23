// =============================================================================
// LT-10 [30% Jobs] 지도와 연동된 급구 알바 카드 노출 (LT-04 Job Board)
// 위치 기반(GeoPoint) 구조. 지도 전환 버튼·카드 클릭 시 상세. 한/영 주석 병기.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});
  static const String routeName = '/jobs';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n('jobs')),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: '지도 보기 / Map view',
            onPressed: () {
              // TODO: 지도 화면 전환 (GeoPoint 연동)
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n('section_quick_jobs'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _JobCard(
            title: '식당 서버',
            location: '비엔티안 시청 인근',
            salary: '15,000 LAK/시간',
            onTap: () {},
            onApply: () {},
          ),
          const SizedBox(height: 8),
          _JobCard(
            title: '단순 노무',
            location: '타락광장 근처',
            salary: '협의',
            onTap: () {},
            onApply: () {},
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.title,
    required this.location,
    required this.salary,
    required this.onTap,
    required this.onApply,
  });
  final String title;
  final String location;
  final String salary;
  final VoidCallback onTap;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(location, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(salary, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onApply,
                  child: const Text('지원하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
