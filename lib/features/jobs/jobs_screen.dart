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
  String? _selectedRegion;
  String? _selectedType;

  final List<Map<String, String>> _jobList = [
    {'title': '식당 서버', 'location': '비엔티안 시청 인근', 'salary': '15,000 LAK/시간', 'type': '서비스'},
    {'title': '단순 노무', 'location': '타락광장 근처', 'salary': '협의', 'type': '노무'},
    {'title': '카페 알바', 'location': '시내 중심가', 'salary': '12,000 LAK/시간', 'type': '서비스'},
    {'title': '배달 도우미', 'location': '시내', 'salary': '협의', 'type': '배달'},
  ];

  List<Map<String, String>> get _filteredJobs {
    var list = _jobList;
    if (_selectedRegion != null) {
      list = list.where((j) => j['location']?.contains(_selectedRegion ?? '') ?? false).toList();
      if (list.isEmpty) list = _jobList;
    }
    if (_selectedType != null) {
      list = list.where((j) => j['type'] == _selectedType).toList();
      if (list.isEmpty) list = _jobList;
    }
    return list.isEmpty ? _jobList : list;
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
                value: _selectedRegion,
                options: const ['비엔티안', '시내', '타락광장'],
                onSelected: (v) => setState(() => _selectedRegion = v),
              ),
              const SizedBox(width: 12),
              _FilterChip(
                label: context.l10n('job_filter_type'),
                value: _selectedType,
                options: const ['서비스', '노무', '배달'],
                onSelected: (v) => setState(() => _selectedType = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._filteredJobs.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JobCard(
                  title: job['title']!,
                  location: job['location']!,
                  salary: job['salary']!,
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
              for (final opt in options)
                FilterChip(
                  label: Text(opt),
                  selected: value == opt,
                  onSelected: (_) => onSelected(value == opt ? null : opt),
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
              Text(salary, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF1E3A8A))),
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
