// =============================================================================
// LT-10 [일자리 탭] 라오스 전역의 실시간 일자리 · 지역/직종 필터 + 채용 공고 리스트
// 다국어(KR/LA/EN) 실시간 변환. 유지: 하단 내비에서 진입.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  static const String routeName = '/jobs';

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const Color _appBarBlue = Color(0xFF1E3A8A);
  String? _selectedRegionKey;
  String? _selectedTypeKey;

  // 지역/직종/일자리 정보를 모두 번역 키로 관리하여 다국어 100% 적용.
  static const List<String> _regionKeys = [
    'location_near_vientiane_hall',
    'location_downtown',
    'location_near_that_luang',
  ];

  static const List<String> _typeKeys = [
    'job_type_service',
    'job_type_labor',
    'job_type_delivery',
  ];

  final List<Map<String, String>> _jobList = [
    {
      'titleKey': 'job_title_restaurant_server',
      'locationKey': 'location_near_vientiane_hall',
      'salaryKey': 'salary_15k_per_hour',
      'typeKey': 'job_type_service',
    },
    {
      'titleKey': 'job_title_simple_labor',
      'locationKey': 'location_near_that_luang',
      'salaryKey': 'salary_negotiable',
      'typeKey': 'job_type_labor',
    },
    {
      'titleKey': 'job_title_cafe_part_time',
      'locationKey': 'location_downtown',
      'salaryKey': 'salary_12k_per_hour',
      'typeKey': 'job_type_service',
    },
    {
      'titleKey': 'job_title_delivery_helper',
      'locationKey': 'location_downtown',
      'salaryKey': 'salary_negotiable',
      'typeKey': 'job_type_delivery',
    },
  ];

  List<Map<String, String>> get _filteredJobs {
    var list = _jobList;
    if (_selectedRegionKey != null) {
      list = list.where((j) => j['locationKey'] == _selectedRegionKey).toList();
    }
    if (_selectedTypeKey != null) {
      list = list.where((j) => j['typeKey'] == _selectedTypeKey).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _appBarBlue,
        foregroundColor: Colors.white,
        title: Text(context.l10n('jobs')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n('jobs_header'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterChip(
                label: context.l10n('job_filter_region'),
                value: _selectedRegionKey,
                options: _regionKeys,
                onSelected: (v) => setState(() => _selectedRegionKey = v),
              ),
              const SizedBox(width: 12),
              _FilterChip(
                label: context.l10n('job_filter_type'),
                value: _selectedTypeKey,
                options: _typeKeys,
                onSelected: (v) => setState(() => _selectedTypeKey = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._filteredJobs.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JobCard(
                  titleKey: job['titleKey']!,
                  locationKey: job['locationKey']!,
                  salaryKey: job['salaryKey']!,
                  onTap: () {},
                  onApply: () {},
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final optKey in options)
                FilterChip(
                  label: Text(context.l10n(optKey)),
                  selected: value == optKey,
                  onSelected: (_) => onSelected(value == optKey ? null : optKey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.titleKey,
    required this.locationKey,
    required this.salaryKey,
    required this.onTap,
    required this.onApply,
  });
  final String titleKey;
  final String locationKey;
  final String salaryKey;
  final VoidCallback onTap;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(titleKey),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(context.l10n(locationKey), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(context.l10n(salaryKey), style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(context.l10n('job_apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
