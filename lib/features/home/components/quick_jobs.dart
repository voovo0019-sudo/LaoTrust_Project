import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';
import '../../../core/firebase_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/firebase_service.dart';
import '../../profile/profile_screen.dart';
import '../quick_job_post_screen.dart';
import '../quick_job_title_catalog.dart';
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
  final List<Map<String, dynamic>> _localJobs = <Map<String, dynamic>>[];
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

  static const int _sampleBaseCreatedAt = 1;

  static final Map<String, String> _jobTitleValueToKey = {
    ...kQuickJobTitlePhraseToKey,
    '\uC2DD\uB2F9 \uC11C\uBC84': 'job_title_restaurant_server',
    '\uB2E8\uC21C \uB178\uBB34': 'job_title_simple_labor',
    '\uCE74\uD398 \uC54C\uBC14': 'job_title_cafe_part_time',
    '\uBC30\uB2EC \uB3C4\uC6B0\uBBF8': 'job_title_delivery_helper',
    '\uD589\uC0AC \uC2A4\uD0DC\uD504': 'job_title_event_staff',
    '\uBB3C\uB958 \uBCF4\uC870': 'job_title_logistics',
    '\uD310\uCD09 \uD64D\uBCF4': 'job_title_promotion',
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

  String _jobCardTitle(BuildContext context, Map<String, dynamic> job) {
    if (job.containsKey('titleKey')) {
      return context.t(job['titleKey']!.toString().trim());
    }
    final raw = (job['title']?.toString() ?? '').trim();
    if (raw.isEmpty) return '';
    final viaT = context.t(raw);
    if (viaT != raw) return viaT;
    return _localizedFromMaybeKey(context, raw, _jobTitleValueToKey);
  }

  String _jobCardDetail(BuildContext context, Map<String, dynamic> job) {
    if (job.containsKey('detailKey')) {
      return context.t(job['detailKey']!.toString().trim());
    }
    final raw = (job['detail']?.toString() ?? '').trim();
    if (raw.isEmpty) return '';
    final viaT = context.t(raw);
    if (viaT != raw) return viaT;
    final phraseKey = kQuickJobDetailPhraseToKey[raw];
    if (phraseKey != null) return context.t(phraseKey);
    return _localizedFromMaybeKey(context, raw, _jobDetailValueToKey);
  }

  static const Map<String, String> _jobLocValueToKey = {
    '\uBE44\uC5D4\uD2F0\uC548 \uC2DC\uCCAD \uC778\uADFC': 'location_near_vientiane_hall',
    '\uD0C0\uB77D\uAD11\uC7A5 \uADFC\uCC98': 'location_near_that_luang',
    '\uC2DC\uB0B4 \uC911\uC2EC\uAC00': 'location_downtown',
    '\uC2DC\uB0B4': 'location_downtown',
  };

  static const Map<String, String> _jobSalaryValueToKey = {
    '15,000 LAK/\uC2DC\uAC04': 'salary_15k_per_hour',
    '12,000 LAK/\uC2DC\uAC04': 'salary_12k_per_hour',
    '\uD611\uC758': 'salary_negotiable',
  };

  static final Map<String, String> _jobDetailValueToKey = {
    ...kQuickJobDetailPhraseToKey,
    '\uC2DD\uB2F9 \uC11C\uBC84': 'job_detail_restaurant_server',
    '\uB2E8\uC21C \uB178\uBB34': 'job_detail_simple_labor',
    '\uCE74\uD398 \uC54C\uBC14': 'job_detail_cafe_part_time',
    '\uD589\uC0AC \uC2A4\uD0DC\uD504': 'job_detail_event_staff',
    '\uBB3C\uB958 \uBCF4\uC870': 'job_detail_logistics',
    '\uD310\uCD09 \uD64D\uBCF4': 'job_detail_promotion',
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

  int _createdAtMillis(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  bool _isOwnJob(Map<String, dynamic> job) {
    if (job['isSample'] == true) return false;
    final docId = job['documentId']?.toString();
    if (docId == null || docId.isEmpty) return false;
    final ownerKey = employerIdForCurrentSession();
    if (ownerKey == null) return false;
    return job['employerId']?.toString() == ownerKey;
  }

  Future<void> _promptLoginRequired(BuildContext context) async {
    final goProfile = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(context.t('quick_job_login_required_title')),
        content: Text(context.t('quick_job_login_required_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.t('quick_job_dialog_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.t('quick_job_go_to_profile')),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (goProfile == true) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(
            openPhoneAuthOnStart: true,
            popToHomeOnAuthSuccess: true,
          ),
        ),
      );
    }
  }

  Future<void> _deleteJobAfterConfirm(BuildContext context, String documentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(context.t('quick_job_delete_confirm_title')),
        content: Text(context.t('quick_job_delete_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.t('quick_job_dialog_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.t('quick_job_delete_action')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await widget.firebaseService.deleteQuickJobDocument(documentId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('quick_job_save_failed'))),
        );
      }
    }
  }

  void _openEditJob(
    BuildContext context, {
    required Map<String, dynamic> job,
    required String title,
    required String location,
    required String salary,
    required String detail,
    required DateTime deadlineAt,
  }) {
    Navigator.pushNamed(
      context,
      quickJobPostRouteName,
      arguments: <String, dynamic>{
        'documentId': job['documentId'],
        'title': title,
        'location': location,
        'salary': salary,
        'detail': detail,
        'deadline': deadlineAt,
      },
    );
  }

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
    final raw = maybeKeyOrValue.toString().trim();
    if (raw.isEmpty) return '';
    final key = valueToKey[raw];
    return key == null ? raw : context.l10n(key);
  }

  String _localizedIfKeyOrRaw(BuildContext context, Object? maybeKeyOrValue) {
    if (maybeKeyOrValue == null) return '';
    final raw = maybeKeyOrValue.toString();
    // If it's a known translation key, localize it; otherwise use raw user-entered text.
    // (AppLocalizations returns key itself if missing, so this is safe.)
    final localized = context.l10n(raw);
    return localized == raw ? raw : localized;
  }

  void _showQuickJobDetailsDialog({
    required BuildContext context,
    required String title,
    required String location,
    required String salary,
    required String detail,
    required String tag,
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
              '${context.t('status')}: $tag',
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.t('location')}: $location',
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.t('salary')}: $salary',
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.t('detail')}: $detail',
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
        const SizedBox(height: 10),
        _buildPremiumPostCard(context),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: whitelistDisplayPhoneNotifier,
          builder: (context, _) {
            return StreamBuilder(
              stream: auth.authStateChanges(),
              builder: (context, __) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.firebaseService.getQuickJobs(),
                  builder: (context, snapshot) {
            final remote = snapshot.data ?? const <Map<String, dynamic>>[];

            final realJobs = <Map<String, dynamic>>[
              ..._localJobs.map((e) => {...e, 'isSample': false}),
              ...remote.map((e) => {...e, 'isSample': false}),
            ];

            realJobs.sort((a, b) {
              final aNum = _createdAtMillis(a['createdAt']);
              final bNum = _createdAtMillis(b['createdAt']);
              return bNum.compareTo(aNum);
            });

            final sampleJobs = _mockQuickJobs.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return <String, dynamic>{
                'titleKey': m['titleKey'],
                'locKey': m['locKey'],
                'salaryKey': m['salaryKey'],
                'detailKey': m['detailKey'],
                'isSample': true,
                'createdAt': _sampleBaseCreatedAt + i,
              };
            }).toList();

            final jobs = <Map<String, dynamic>>[
              ...realJobs,
              ...sampleJobs,
            ];
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
                      final bool isSample = job['isSample'] == true;
                      DateTime? deadlineAt;
                      if (job['deadlineAt'] != null) {
                        final t = job['deadlineAt'];
                        if (t is DateTime) {
                          deadlineAt = t;
                        } else if (t is Timestamp) {
                          deadlineAt = t.toDate();
                        } else if (t is int) {
                          deadlineAt = DateTime.fromMillisecondsSinceEpoch(t);
                        }
                      }
                      if (deadlineAt == null && isSample) {
                        deadlineAt = DateTime.now().add(Duration(hours: 2 + (index % 6) * 3));
                      } else {
                        deadlineAt ??= DateTime.now().add(Duration(hours: 2 + index * 3));
                      }
                      final DateTime deadlineResolved = deadlineAt;
                      final now = DateTime.now();
                      final remaining = deadlineResolved.difference(now);
                      const totalHours = 24.0;
                      final remainingHours = remaining.inMinutes / 60.0;
                      final progress = (remainingHours / totalHours).clamp(0.0, 1.0);
                      final title = _jobCardTitle(context, job);
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
                      final detail = _jobCardDetail(context, job);
                      final tag = _localizedIfKeyOrRaw(context, job['tag']);
                      final bool ownJob = _isOwnJob(job);

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
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
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
                              tag: tag,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(28.0),
                                        ),
                                        child: Text(
                                          tag,
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
                                      if (ownJob)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E3A8A), size: 20),
                                              tooltip: context.t('quick_job_edit_action'),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              onPressed: () => _openEditJob(
                                                context,
                                                job: job,
                                                title: title,
                                                location: location,
                                                salary: salary,
                                                detail: detail,
                                                deadlineAt: deadlineResolved,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFF1E3A8A), size: 20),
                                              tooltip: context.t('quick_job_delete_action'),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              onPressed: () {
                                                final id = job['documentId']?.toString();
                                                if (id != null && id.isNotEmpty) {
                                                  _deleteJobAfterConfirm(context, id);
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      else
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF1E3A8A),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 4,
                                            backgroundColor: Colors.grey.shade300,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          remaining.isNegative
                                              ? context.l10n('job_deadline_passed')
                                              : context.t('job_deadline_left').replaceAll('{h}', remainingHours.toStringAsFixed(0)),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                            fontFamily: 'Noto Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPremiumPostCard(BuildContext context) {
    return ListenableBuilder(
      listenable: whitelistDisplayPhoneNotifier,
      builder: (context, _) {
        return StreamBuilder(
          stream: auth.authStateChanges(),
          builder: (context, __) {
            return InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () async {
                await finalizeAppAuthState();
                if (!context.mounted) return;
                if (isFirebaseEnabled && !hasRecognizedUserSession) {
                  await _promptLoginRequired(context);
                  return;
                }
                final result = await Navigator.pushNamed(context, quickJobPostRouteName);
                if (!context.mounted) return;
                if (result is Map<String, dynamic> && result['_firebaseHandled'] == true) {
                  return;
                }
                if (result is Map<String, dynamic>) {
                  setState(() {
                    _localJobs.insert(0, {...result, 'isSample': false});
                  });
                }
              },
              child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.0),
          border: Border.all(color: const Color(0xFF1E3A8A), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF1E3A8A), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n('quick_job_post_card_title'),
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
          ],
        ),
              ),
            );
          },
        );
      },
    );
  }
}

