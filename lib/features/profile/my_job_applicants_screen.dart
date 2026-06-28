// =============================================================================
// 내 공고 지원자 목록 화면 — Phase 1-2
// 구인자가 본인 공고에 달린 지원자를 확인하는 화면
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/theme.dart';
import '../../data/firestore_schema.dart';
import '../../services/firebase_service.dart';

class MyJobApplicantsScreen extends ConsumerWidget {
  const MyJobApplicantsScreen({
    super.key,
    this.jobId,
    this.jobTitle,
  });
  final String? jobId;
  final String? jobTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: Text((jobId != null && jobId!.isNotEmpty)
              ? (jobTitle ?? context.l10n('my_job_posts'))
              : context.l10n('my_job_posts')),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            context.l10n('login_required'),
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    final stream = (jobId != null && jobId!.isNotEmpty)
        ? FirebaseService().watchJobApplicants(jobId!)
        : FirebaseService().watchMyPostedJobs(currentUser.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Text((jobId != null && jobId!.isNotEmpty)
            ? (jobTitle ?? context.l10n('my_job_posts'))
            : context.l10n('my_job_posts')),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final applications = snapshot.data ?? [];
          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n('no_applicants'),
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = applications[index];

              // 지원자 목록 모드
              if (jobId != null && jobId!.isNotEmpty) {
                return _ApplicantCard(app: item);
              }

              // 공고 목록 모드
              final lang = Localizations.localeOf(context).languageCode;
              final titleI18n = Map<String, dynamic>.from(
                  item[JobFields.titleI18n] as Map? ?? {});
              final jobTitleText = titleI18n[lang]?.toString().isNotEmpty == true
                  ? titleI18n[lang].toString()
                  : titleI18n['en']?.toString() ?? '';
              final deadlineAt = item['deadlineAt'];
              String deadlineStr = '';
              if (deadlineAt is Timestamp) {
                final dt = deadlineAt.toDate();
                deadlineStr =
                    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    final docId = item['documentId']?.toString() ?? '';
                    if (docId.isNotEmpty) {
                      context.push(
                        '/my_job_applicants',
                        extra: {
                          'jobId': docId,
                          'jobTitle': jobTitleText,
                        },
                      );
                    }
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                    child: const Icon(Icons.work_outline,
                        color: Color(0xFF1E3A8A), size: 22),
                  ),
                  title: Text(
                    jobTitleText.isNotEmpty ? jobTitleText : '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: deadlineStr.isNotEmpty
                      ? Text(
                          '${context.l10n('deadline_label')}: $deadlineStr',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        )
                      : null,
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n('job_status_open'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends StatefulWidget {
  const _ApplicantCard({required this.app});
  final Map<String, dynamic> app;

  @override
  State<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends State<_ApplicantCard> {
  bool _updating = false;

  Future<void> _updateStatus(String newStatus) async {
    final documentId = widget.app['documentId']?.toString() ?? '';
    final jobId = widget.app['jobId']?.toString() ?? '';
    final jobTitleI18n = Map<String, dynamic>.from(
        widget.app['jobTitleI18n'] as Map? ?? {'ko': '', 'en': '', 'lo': ''});
    final employerId = widget.app['employerId']?.toString() ?? '';
    final applicantId = widget.app['applicantId']?.toString() ?? '';

    if (documentId.isEmpty || _updating) return;
    setState(() => _updating = true);
    try {
      // 1. 지원 상태 업데이트
      await FirebaseFirestore.instance
          .collection(kColApplications)
          .doc(documentId)
          .update({ApplicationFields.status: newStatus});

      // 2. 수락 시 채팅방 자동 생성
      if (newStatus == kAppStatusAccepted &&
          jobId.isNotEmpty &&
          employerId.isNotEmpty &&
          applicantId.isNotEmpty) {
        await FirebaseService().createChatRoom(
          jobId: jobId,
          jobTitleI18n: jobTitleI18n,
          employerId: employerId,
          applicantId: applicantId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n('status_update_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final titleI18n = widget.app['jobTitleI18n'] as Map<String, dynamic>? ?? {};
    final jobTitle = titleI18n[lang]?.toString().isNotEmpty == true
        ? titleI18n[lang].toString()
        : titleI18n['en']?.toString() ?? '';
    final status = widget.app['status']?.toString() ?? kAppStatusPending;
    final createdAtRaw = widget.app['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is int && createdAtRaw > 0) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    }
    final dateStr = createdAt != null
        ? '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontFamilyFallback: AppTheme.notoSansLaoFallback,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.l10n('applied_at')}: $dateStr',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status, context: context),
            ],
          ),
          if (status == kAppStatusPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _updating ? null : () => _updateStatus(kAppStatusRejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF991B1B),
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(context.l10n('reject_button')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updating ? null : () => _updateStatus(kAppStatusAccepted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(context.l10n('accept_button')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.context});
  final String status;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case kAppStatusAccepted:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = context.l10n('applicant_status_accepted');
        break;
      case kAppStatusRejected:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = context.l10n('applicant_status_rejected');
        break;
      default:
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        label = context.l10n('applicant_status_pending');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
