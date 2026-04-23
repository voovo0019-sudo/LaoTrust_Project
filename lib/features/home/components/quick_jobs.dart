import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/app_localizations.dart';
import '../../../core/firebase_service.dart';
import '../../../core/quick_job_triple_map_builder.dart';
import '../../../core/theme.dart';
import '../../../core/translation_mapper.dart';
import '../../../data/firestore_schema.dart';
import '../../../services/auth_service.dart';
import '../../../services/firebase_service.dart';
import '../../profile/profile_screen.dart';
import '../quick_job_post_screen.dart';
import 'section_title_style.dart';

/// v13.9: 급구 표시는 [pickQuickJobI18nForDisplay](힐링 포함) — EN/LO 한글 숨김 유지.
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
  Stream<List<Map<String, dynamic>>>? _jobsStream;

  Future<List<Map<String, dynamic>>>? _quickJobsCachedFuture;
  String _quickJobsCachedAuthKey = '\u0000';

  @override
  void initState() {
    super.initState();
    _jobsStream = widget.firebaseService.watchQuickJobs();
  }

  // ignore: unused_element
  Future<List<Map<String, dynamic>>> _quickJobsFutureForCurrentAuth() {
    final key = auth.currentUser?.uid ?? '';
    if (_quickJobsCachedFuture == null || _quickJobsCachedAuthKey != key) {
      _quickJobsCachedAuthKey = key;
      _quickJobsCachedFuture = widget.firebaseService.getQuickJobs();
    }
    return _quickJobsCachedFuture!;
  }

  void _invalidateQuickJobsRemoteCache() {
    _quickJobsCachedFuture = null;
    _quickJobsCachedAuthKey = '\u0000';
  }

  /// 라오 문자(ລາວ) 포함 시 Noto Sans Lao 폴백.
  TextStyle _qjTextStyle({
    double fontSize = 13,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Noto Sans',
      fontFamilyFallback: AppTheme.notoSansLaoFallback,
      letterSpacing: 0.1,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

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

  /// Zero-Pending: String·오염 맵을 읽는 즉시 heal → Pending/한글 슬롯 오염 차단.
  Map<String, dynamic> _healedTripleForDisplay(dynamic field) {
    return Map<String, dynamic>.from(healQuickJobI18nField(field));
  }

  String _displayJobTitle(BuildContext context, Map<String, dynamic> job) {
    if (job['titleKey'] != null) {
      return context.t(job['titleKey']!.toString().trim());
    }
    final lang = Localizations.localeOf(context).languageCode;
    final tm = job['titleMap'] ?? job[JobFields.titleI18n];
    if (tm != null) {
      return pickQuickJobI18nForDisplay(_healedTripleForDisplay(tm), lang, context);
    }
    final raw = (job['title']?.toString() ?? '').trim();
    if (raw.isEmpty) return '';
    return pickQuickJobI18nForDisplay(
      TranslationMapper.legacyTitleScalarToDisplayTriple(raw, lang),
      lang,
      context,
    );
  }

  String _displayJobLocation(BuildContext context, Map<String, dynamic> job) {
    if (job['locKey'] != null) {
      return context.l10n(job['locKey']!.toString());
    }
    final lang = Localizations.localeOf(context).languageCode;
    final m = job['locMap'] ?? job[JobFields.locationI18n];
    if (m != null) {
      return pickQuickJobI18nForDisplay(_healedTripleForDisplay(m), lang, context);
    }
    final raw = (job['loc']?.toString() ?? '').trim();
    if (raw.isEmpty) return '';
    return pickQuickJobI18nForDisplay(
      TranslationMapper.legacyLocationScalarToDisplayTriple(raw, lang),
      lang,
      context,
    );
  }

  String _displayJobSalary(BuildContext context, Map<String, dynamic> job) {
    if (job['salaryKey'] != null) {
      return context.l10n(job['salaryKey']!.toString());
    }
    final lang = Localizations.localeOf(context).languageCode;
    final m = job['salaryMap'] ?? job[JobFields.salaryI18n];
    if (m != null) {
      return pickQuickJobI18nForDisplay(_healedTripleForDisplay(m), lang, context);
    }
    final raw = (job['salary']?.toString() ?? '').trim();
    if (raw.isEmpty) return '';
    return pickQuickJobI18nForDisplay(
      TranslationMapper.legacySalaryScalarToDisplayTriple(raw, lang),
      lang,
      context,
    );
  }

  String _displayJobDetail(BuildContext context, Map<String, dynamic> job) {
    if (job['detailKey'] != null) {
      return context.t(job['detailKey']!.toString().trim());
    }
    final lang = Localizations.localeOf(context).languageCode;
    final m = job['detailMap'] ?? job[JobFields.descriptionI18n];
    if (m != null) {
      return pickQuickJobI18nForDisplay(_healedTripleForDisplay(m), lang, context);
    }
    final raw = (job['detail']?.toString() ?? '').trim();
    if (raw.isEmpty) return '';
    return pickQuickJobI18nForDisplay(
      TranslationMapper.legacyDetailScalarToDisplayTriple(raw, lang),
      lang,
      context,
    );
  }

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
      setPostLoginRedirect(quickJobPostRouteName);
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
      if (context.mounted) {
        _invalidateQuickJobsRemoteCache();
        setState(() {});
      }
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

  String _localizedIfKeyOrRaw(BuildContext context, Object? maybeKeyOrValue) {
    if (maybeKeyOrValue == null) return '';
    final raw = maybeKeyOrValue.toString();
    // If it's a known translation key, localize it; otherwise use raw user-entered text.
    // (AppLocalizations returns key itself if missing, so this is safe.)
    final localized = context.l10n(raw);
    return localized == raw ? raw : localized;
  }

  /// 상세 모달: Pending 문구 대신 ko·en 등 안전한 표시값.
  String _safeDisplay(dynamic fieldValue, String currentLang) {
    if (fieldValue == null) return '';

    if (fieldValue is Map) {
      final localized = fieldValue[currentLang]?.toString().trim() ?? '';
      if (localized.isNotEmpty) return localized;
      final ko = fieldValue['ko']?.toString().trim() ?? '';
      if (ko.isNotEmpty) return ko;
      final en = fieldValue['en']?.toString().trim() ?? '';
      return en;
    }

    final s = fieldValue.toString().trim();
    if (s.isEmpty) return '';
    if (s.toLowerCase().contains('pending')) return '';
    return s;
  }

  void _showQuickJobDetailsDialog({
    required BuildContext context,
    required Map<String, dynamic> job,
    required String tag,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final lang = Localizations.localeOf(ctx).languageCode;
        final titleLine = job['titleKey'] != null
            ? ctx.t(job['titleKey']!.toString().trim())
            : _safeDisplay(job['titleMap'] ?? job[JobFields.titleI18n] ?? job['title'], lang);
        final locationLine = job['locKey'] != null
            ? ctx.l10n(job['locKey']!.toString())
            : _safeDisplay(job['locMap'] ?? job[JobFields.locationI18n] ?? job['loc'], lang);
        final salaryLine = job['salaryKey'] != null
            ? ctx.l10n(job['salaryKey']!.toString())
            : _safeDisplay(job['salaryMap'] ?? job[JobFields.salaryI18n] ?? job['salary'], lang);
        final detailLine = job['detailKey'] != null
            ? ctx.t(job['detailKey']!.toString().trim())
            : _safeDisplay(job['detailMap'] ?? job[JobFields.descriptionI18n] ?? job['detail'], lang);
        return AlertDialog(
          title: Text(
            titleLine,
            style: lang.toLowerCase().startsWith('lo')
                ? TextStyle(
                    fontFamily: AppTheme.textStyleLaoPrimary.fontFamily,
                    letterSpacing: 0.1,
                  )
                : _qjTextStyle(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${ctx.t('status')}: $tag',
                style: lang.toLowerCase().startsWith('lo')
                    ? TextStyle(
                        fontFamily: AppTheme.textStyleLaoPrimary.fontFamily,
                        letterSpacing: 0.1,
                      )
                    : _qjTextStyle(),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctx.t('location')}: $locationLine',
                style: lang.toLowerCase().startsWith('lo')
                    ? TextStyle(
                        fontFamily: AppTheme.textStyleLaoPrimary.fontFamily,
                        letterSpacing: 0.1,
                      )
                    : _qjTextStyle(),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctx.t('salary')}: $salaryLine',
                style: lang.toLowerCase().startsWith('lo')
                    ? TextStyle(
                        fontFamily: AppTheme.textStyleLaoPrimary.fontFamily,
                        letterSpacing: 0.1,
                      )
                    : _qjTextStyle(),
              ),
              const SizedBox(height: 8),
              Text(
                '${ctx.t('detail')}: $detailLine',
                style: lang.toLowerCase().startsWith('lo')
                    ? TextStyle(
                        fontFamily: AppTheme.textStyleLaoPrimary.fontFamily,
                        letterSpacing: 0.1,
                      )
                    : _qjTextStyle(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n('confirm')),
            ),
          ],
        );
      },
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
        StreamBuilder(
          stream: auth.authStateChanges(),
          builder: (context, __) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _jobsStream,
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
                      final title = _displayJobTitle(context, job);
                      final location = _displayJobLocation(context, job);
                      final salary = _displayJobSalary(context, job);
                      final detail = _displayJobDetail(context, job);
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
                              job: job,
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
                                          style: _qjTextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E3A8A),
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
                                          style: _qjTextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
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
                                          style: _qjTextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
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
            ),
      ],
    );
  }

  Widget _buildPremiumPostCard(BuildContext context) {
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
              await Future.delayed(const Duration(milliseconds: 3000));
              if (!context.mounted) return;
              _invalidateQuickJobsRemoteCache();
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 1000));
              if (!context.mounted) return;
              _invalidateQuickJobsRemoteCache();
              setState(() {});
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
  }
}

