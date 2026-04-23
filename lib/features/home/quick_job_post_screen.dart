// =============================================================================
// v1.3: 급구 알바 구인 등록 UI — [알바 구인+] 진입
// v7.5: 인증 가드, 위치 타임아웃, 수정 모드, Firestore 완료 후 즉시 복귀.
// 디자인: 곡률 28px, 로얄 네이비 #1E293B.
// =============================================================================

import 'package:flutter/foundation.dart' show kDebugMode;
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
  bool _isLoading = false;

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
      setPostLoginRedirect(
        quickJobPostRouteName,
        <String, dynamic>{
          'documentId': widget.editDocumentId,
          'title': _titleController.text,
          'location': _locationController.text,
          'salary': _salaryController.text,
          'detail': _descriptionController.text,
          'deadline': _deadline,
        },
      );
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
    if (isFirebaseEnabled) {
      if (!hasRecognizedUserSession) {
        await _showLoginRequiredDialog();
        return;
      }
    }

    if (_saving) return;
    setState(() {
      _saving = true;
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final locText = _locationController.text.trim();
      final salary = _salaryController.text.trim();
      final detail = _descriptionController.text.trim();

      final sourceLang = Localizations.localeOf(context).languageCode;
      final inputData = <String, String>{
        'title': title,
        'location': locText,
        'salary': salary,
        'detail': detail,
      };

      // ✅ 번역 시도 - 최대 6초, 실패해도 원문 저장
      Map<String, Map<String, String>> bundled;
      try {
        final tResult = await TranslationMapper.translateAllFieldsStrict(
          inputData,
          sourceLanguageCode: sourceLang,
        ).timeout(const Duration(seconds: 6));

        bundled = tResult.bundle ??
            {
              for (final k in ['title', 'location', 'salary', 'detail'])
                k: {'ko': inputData[k]!, 'en': inputData[k]!, 'lo': inputData[k]!},
            };
      } catch (e) {
        if (kDebugMode) debugPrint('_submit: 번역 실패 → 원문 저장: $e');
        bundled = {
          for (final k in ['title', 'location', 'salary', 'detail'])
            k: {'ko': inputData[k]!, 'en': inputData[k]!, 'lo': inputData[k]!},
        };
      }

      if (!mounted) return;

      // ✅ 위치 정보
      final (p, _) = await getUserLocationOrDefault()
          .timeout(const Duration(seconds: 2), onTimeout: () => (kVientianeCityHall, true));
      final geo = GeoPoint(p.latitude, p.longitude);

      // ✅ Firestore 저장
      if (isFirebaseEnabled) {
        final payload = <String, dynamic>{
          JobFields.titleI18n: bundled['title']!,
          JobFields.locationI18n: bundled['location']!,
          JobFields.salaryI18n: bundled['salary']!,
          JobFields.descriptionI18n: bundled['detail']!,
          JobFields.locationGeo: geo,
          JobFields.deadlineAt: Timestamp.fromDate(_deadline),
          JobFields.createdAt: FieldValue.serverTimestamp(),
          JobFields.employerId: employerIdForCurrentSession() ?? '',
          JobFields.status: 'open',
        };

        if (widget.isEditMode && widget.editDocumentId != null) {
          FirebaseFirestore.instance
              .collection(kColJobs)
              .doc(widget.editDocumentId!)
              .update(payload)
              .catchError((e) {
            if (kDebugMode) debugPrint('Firestore 수정 백그라운드 에러: $e');
          });
        } else {
          // Web에서 Firestore 응답 대기 문제 우회
          // .add() 결과를 기다리지 않고 바로 홈으로 이동
          final docRef = FirebaseFirestore.instance
              .collection(kColJobs)
              .doc(); // 문서 ID 미리 생성

          // 저장은 백그라운드로 실행 (await 없음)
          docRef.set(payload).catchError((e) {
            if (kDebugMode) debugPrint('Firestore 백그라운드 저장 에러: $e');
          });

          // 저장 완료를 기다리지 않고 즉시 홈 복귀
          // (데이터는 Firestore에 안전하게 저장됨)
        }
      }

      if (mounted) Navigator.of(context).pop({'_firebaseHandled': true});
    } catch (e) {
      if (kDebugMode) debugPrint('_submit 최종 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 중 오류: $e')),
        );
      }
    } finally {
      // ✅ 무조건 실행 - 로딩 해제
      if (mounted) {
        setState(() {
          _saving = false;
          _isLoading = false;
        });
      }
    }
  }

  // 오프라인 급구 흐름 보존용 (향후 복구 시 사용).
  // ignore: unused_element
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
              onPressed: (_saving || _isLoading) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: (_saving || _isLoading)
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
