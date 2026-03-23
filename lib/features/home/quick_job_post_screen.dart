// =============================================================================
// v1.3: 급구 알바 구인 등록 UI — [알바 구인+] 진입
// v7.5: 인증 가드, 위치 타임아웃, 수정 모드, Firestore 완료 후 즉시 복귀.
// 디자인: 곡률 28px, 로얄 네이비 #1E293B.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';
import '../../core/location_service.dart';
import '../../data/firestore_schema.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';

const String quickJobPostRouteName = '/quick-job-post';
const Color _royalNavy = Color(0xFF1E293B);

/// v10.2 Fail-Safe: 타임아웃 시 스낵바 문구 (지시서 원문).
const String kQuickJobSaveTimeoutSnackMessage = '통신이 원활하지 않으나 등록은 시도되었습니다';

class QuickJobPostScreen extends StatefulWidget {
  const QuickJobPostScreen({
    super.key,
    this.editDocumentId,
    this.initialTitle = '',
    this.initialLocation = '',
    this.initialSalary = '',
    this.initialDetail = '',
    this.initialDeadline,
  });

  final String? editDocumentId;
  final String initialTitle;
  final String initialLocation;
  final String initialSalary;
  final String initialDetail;
  final DateTime? initialDeadline;

  bool get isEditMode => editDocumentId != null && editDocumentId!.isNotEmpty;

  @override
  State<QuickJobPostScreen> createState() => _QuickJobPostScreenState();
}

class _QuickJobPostScreenState extends State<QuickJobPostScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _salaryController;
  late final TextEditingController _descriptionController;
  late DateTime _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _locationController = TextEditingController(text: widget.initialLocation);
    _salaryController = TextEditingController(text: widget.initialSalary);
    _descriptionController = TextEditingController(text: widget.initialDetail);
    _deadline = widget.initialDeadline ?? DateTime.now().add(const Duration(hours: 24));
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeAuthOnEntry());
  }

  Future<void> _primeAuthOnEntry() async {
    await finalizeAppAuthState();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showLoginRequiredDialog() async {
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
    if (!mounted) return;
    if (goProfile == true) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(
            openPhoneAuthOnStart: true,
            popToHomeOnAuthSuccess: true,
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    await finalizeAppAuthState();
    if (!mounted) return;
    if (isFirebaseEnabled && !hasRecognizedUserSession) {
      await _showLoginRequiredDialog();
      return;
    }

    setState(() => _saving = true);
    var success = false;
    var overlayShown = false;
    var timedOut = false;
    NavigatorState? rootNav;
    try {
      final title = _titleController.text.trim();
      final locText = _locationController.text.trim();
      final salary = _salaryController.text.trim();
      final detail = _descriptionController.text.trim();

      if (isFirebaseEnabled) {
        if (!mounted) return;
        rootNav = Navigator.of(context, rootNavigator: true);
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => PopScope(
            canPop: false,
            child: Material(
              type: MaterialType.transparency,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),
        );
        overlayShown = true;

        await Future<void>(() async {
          final (p, _) = await getUserLocationOrDefault();
          if (!mounted) return;
          final geo = GeoPoint(p.latitude, p.longitude);
          final sourceLang = Localizations.localeOf(context).languageCode;

          final bundled = await TranslationMapper.translateAllFields(
            {
              'title': title,
              'location': locText,
              'salary': salary,
              'detail': detail,
            },
            sourceLanguageCode: sourceLang,
          );

          final payload = <String, dynamic>{
            JobFields.titleI18n: bundled['title']!,
            JobFields.locationI18n: bundled['location']!,
            JobFields.salaryI18n: bundled['salary']!,
            JobFields.descriptionI18n: bundled['detail']!,
            JobFields.deadlineAt: Timestamp.fromDate(_deadline),
            JobFields.updatedAt: FieldValue.serverTimestamp(),
            JobFields.locationGeo: geo,
            JobFields.jobType: 'quick_job_tag_part_time',
          };

          if (widget.isEditMode) {
            await firestore.collection(kColJobs).doc(widget.editDocumentId).update(payload);
          } else {
            await firestore.collection(kColJobs).add({
              ...payload,
              JobFields.createdAt: FieldValue.serverTimestamp(),
              JobFields.employerId: employerIdForCurrentSession(),
            });
          }
        }).timeout(const Duration(seconds: 5));
        success = true;
      } else {
        success = true;
      }
    } on TimeoutException {
      timedOut = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('quick_job_save_failed'))),
        );
      }
    } finally {
      if (overlayShown) {
        rootNav?.pop();
      }
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;

    if (timedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(kQuickJobSaveTimeoutSnackMessage)),
      );
      Navigator.of(context, rootNavigator: true).pop(<String, dynamic>{'_firebaseHandled': true});
      return;
    }

    if (!success) return;
    final result =
        isFirebaseEnabled ? <String, dynamic>{'_firebaseHandled': true} : _buildOfflineResult();
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  Map<String, dynamic> _buildOfflineResult() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final title = _titleController.text.trim();
    final locText = _locationController.text.trim();
    final salary = _salaryController.text.trim();
    final detail = _descriptionController.text.trim();
    final sl = Localizations.localeOf(context).languageCode;
    final fb = TranslationMapper.fallbackAllFields(
      title.isEmpty ? context.l10n('quick_job_default_title') : title,
      locText.isEmpty ? context.l10n('quick_job_default_location') : locText,
      salary.isEmpty ? context.l10n('salary_negotiable') : salary,
      detail,
      sl,
    );
    return <String, dynamic>{
      'titleMap': fb[0],
      'locMap': fb[1],
      'salaryMap': fb[2],
      'detailMap': fb[3],
      'deadlineAt': _deadline,
      'createdAt': nowMs,
      'tag': 'quick_job_tag_part_time',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _royalNavy,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEditMode
              ? context.t('quick_job_post_edit_title')
              : context.l10n('quick_job_post_title'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(
              context.l10n('quick_job_field_title'),
              _titleController,
              hint: context.l10n('quick_job_title_hint'),
            ),
            const SizedBox(height: 16),
            _buildField(
              context.l10n('quick_job_field_location'),
              _locationController,
              hint: context.l10n('quick_job_location_hint'),
            ),
            const SizedBox(height: 16),
            _buildField(
              context.l10n('quick_job_field_salary'),
              _salaryController,
              hint: context.l10n('quick_job_salary_hint'),
            ),
            const SizedBox(height: 16),
            _buildField(
              context.l10n('quick_job_field_detail'),
              _descriptionController,
              hint: context.l10n('quick_job_detail_hint'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.l10n('quick_job_deadline_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _royalNavy,
                ),
              ),
              subtitle: Text(
                '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')} ${_deadline.hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null && mounted) {
                    setState(() => _deadline = DateTime(picked.year, picked.month, picked.day, _deadline.hour));
                  }
                },
                child: Text(context.l10n('quick_job_deadline_pick_date')),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.isEditMode
                          ? context.t('quick_job_post_save_edit')
                          : context.t('quick_job_post_submit'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _royalNavy,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
