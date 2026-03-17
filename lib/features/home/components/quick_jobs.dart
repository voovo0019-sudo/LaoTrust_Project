import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';
import '../../../services/firebase_service.dart';
import 'section_title_style.dart';

class QuickJobsSection extends StatefulWidget {
  const QuickJobsSection({
    super.key,
    required this.firebaseService,
  });

  final FirebaseService firebaseService;

  @override
  State<QuickJobsSection> createState() => _QuickJobsSectionState();
}

class _QuickJobsSectionState extends State<QuickJobsSection> {
  static const List<Map<String, String>> _mockQuickJobs = [
    {
      'titleKey': 'job_title_restaurant_server',
      'locKey': 'location_near_vientiane_hall',
      'salaryKey': 'salary_15k_per_hour',
      'detailKey': 'job_detail_restaurant_server',
    },
    {
      'titleKey': 'job_title_simple_labor',
      'locKey': 'location_near_that_luang',
      'salaryKey': 'salary_negotiable',
      'detailKey': 'job_detail_simple_labor',
    },
    {
      'titleKey': 'job_title_cafe_part_time',
      'locKey': 'location_downtown',
      'salaryKey': 'salary_12k_per_hour',
      'detailKey': 'job_detail_cafe_part_time',
    },
    {
      'titleKey': 'job_title_event_staff',
      'locKey': 'location_downtown',
      'salaryKey': 'salary_negotiable',
      'detailKey': 'job_detail_event_staff',
    },
    {
      'titleKey': 'job_title_logistics',
      'locKey': 'location_near_that_luang',
      'salaryKey': 'salary_15k_per_hour',
      'detailKey': 'job_detail_logistics',
    },
    {
      'titleKey': 'job_title_promotion',
      'locKey': 'location_downtown',
      'salaryKey': 'salary_12k_per_hour',
      'detailKey': 'job_detail_promotion',
    },
  ];

  static const Map<String, String> _jobTitleValueToKey = {
    '식당 서버': 'job_title_restaurant_server',
    '단순 노무': 'job_title_simple_labor',
    '카페 알바': 'job_title_cafe_part_time',
    '배달 도우미': 'job_title_delivery_helper',
    '행사 스태프': 'job_title_event_staff',
    '물류 보조': 'job_title_logistics',
    '판촉 홍보': 'job_title_promotion',
    'Restaurant Server': 'job_title_restaurant_server',
    'Simple Labor': 'job_title_simple_labor',
    'Cafe Part-time': 'job_title_cafe_part_time',
    'Event Staff': 'job_title_event_staff',
    'Logistics Assistant': 'job_title_logistics',
    'Promotion': 'job_title_promotion',
    'ພະນັກງານຮ້ານອາຫານ': 'job_title_restaurant_server',
    'ແຮງງານທົ່ວໄປ': 'job_title_simple_labor',
    'ວຽກພາດໄທມ໌ຮ້ານກາເຟ': 'job_title_cafe_part_time',
    'ພະນັກງານງານອີເວັນ': 'job_title_event_staff',
    'ຊ່ວຍວຽກຂົນສົ່ງ': 'job_title_logistics',
    'ຕະຫຼາດ/ໂຄສະນາ': 'job_title_promotion',
  };

  static const Map<String, String> _jobLocValueToKey = {
    '비엔티안 시청 인근': 'location_near_vientiane_hall',
    '타락광장 근처': 'location_near_that_luang',
    '시내 중심가': 'location_downtown',
    '시내': 'location_downtown',
  };

  static const Map<String, String> _jobSalaryValueToKey = {
    '15,000 LAK/시간': 'salary_15k_per_hour',
    '12,000 LAK/시간': 'salary_12k_per_hour',
    '협의': 'salary_negotiable',
  };

  static const Map<String, String> _jobDetailValueToKey = {
    '식당 서버': 'job_detail_restaurant_server',
    '단순 노무': 'job_detail_simple_labor',
    '카페 알바': 'job_detail_cafe_part_time',
    '행사 스태프': 'job_detail_event_staff',
    '물류 보조': 'job_detail_logistics',
    '판촉 홍보': 'job_detail_promotion',
    'Restaurant Server': 'job_detail_restaurant_server',
    'Simple Labor': 'job_detail_simple_labor',
    'Cafe Part-time': 'job_detail_cafe_part_time',
    'Event Staff': 'job_detail_event_staff',
    'Logistics Assistant': 'job_detail_logistics',
    'Promotion': 'job_detail_promotion',
    'ພະນັກງານຮ້ານອາຫານ': 'job_detail_restaurant_server',
    'ແຮງງານທົ່ວໄປ': 'job_detail_simple_labor',
    'ວຽກພາດໄທມ໌ຮ້ານກາເຟ': 'job_detail_cafe_part_time',
    'ພະນັກງານງານອີເວັນ': 'job_detail_event_staff',
    'ຊ່ວຍວຽກຂົນສົ່ງ': 'job_detail_logistics',
    'ຕະຫຼາດ/ໂຄສະນາ': 'job_detail_promotion',
  };

  final PageController _pageController = PageController(viewportFraction: 0.48);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _localizedFromMaybeKey(
    BuildContext context,
    Object? maybeKeyOrValue,
    Map<String, String> valueToKey,
  ) {
    if (maybeKeyOrValue == null) return '';
    final raw = maybeKeyOrValue.toString();
    final key = valueToKey[raw];
    return key == null ? raw : context.l10n(key);
  }

  void _showQuickJobDetailsDialog({
    required BuildContext context,
    required String title,
    required String location,
    required String salary,
    required String detail,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Noto Sans',
            letterSpacing: 0.1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.l10n('job_detail_location')}: $location',
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.l10n('job_detail_salary')}: $salary',
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.l10n('job_detail_description')}: $detail',
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            context.l10n('section_quick_jobs'),
            style: kHomeSectionTitleTextStyle,
          ),
        ),
        const SizedBox(height: 6),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.firebaseService.getQuickJobs(),
          builder: (context, snapshot) {
            final List<Map<String, dynamic>> jobs;
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              jobs = snapshot.data!;
            } else {
              jobs = _mockQuickJobs
                  .map(
                    (m) => {
                      'titleKey': m['titleKey'],
                      'locKey': m['locKey'],
                      'salaryKey': m['salaryKey'],
                      'detailKey': m['detailKey'],
                    },
                  )
                  .toList();
            }
            return Column(
              children: [
                SizedBox(
                  height: 78,
                  child: PageView.builder(
                    controller: _pageController,
                    padEnds: false,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final title = job.containsKey('titleKey')
                          ? context.l10n(job['titleKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(
                              context,
                              job['title'],
                              _jobTitleValueToKey,
                            );
                      final location = job.containsKey('locKey')
                          ? context.l10n(job['locKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(
                              context,
                              job['loc'],
                              _jobLocValueToKey,
                            );
                      final salary = job.containsKey('salaryKey')
                          ? context.l10n(job['salaryKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(
                              context,
                              job['salary'],
                              _jobSalaryValueToKey,
                            );
                      final detail = job.containsKey('detailKey')
                          ? context.l10n(job['detailKey']?.toString() ?? '')
                          : _localizedFromMaybeKey(
                              context,
                              title,
                              _jobDetailValueToKey,
                            );

                      return AnimatedScale(
                        scale: _currentPage == index ? 1.0 : 0.96,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28.0),
                            onTap: () => _showQuickJobDetailsDialog(
                              context: context,
                              title: title,
                              location: location,
                              salary: salary,
                              detail: detail,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(28.0),
                                  ),
                                  child: Text(
                                    context.l10n('tag_deadline_soon'),
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      fontFamily: 'Noto Sans',
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'Noto Sans',
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF1E3A8A),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    jobs.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentPage = index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(28.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

