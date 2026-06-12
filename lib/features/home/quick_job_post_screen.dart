// =============================================================================
// v1.3: 급구 알바 구인 등록 UI — [알바 구인+] 진입
// v7.5: 인증 가드, 위치 타임아웃, 수정 모드, Firestore 완료 후 즉시 복귀.
// 디자인: 곡률 28px, 로얄 네이비 #1E293B.
// =============================================================================

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/translation_mapper.dart';
import '../../core/location_service.dart';
import '../../data/firestore_schema.dart';
import '../../services/auth_service.dart';

const String quickJobPostRouteName = '/quick-job-post';
const Color _royalNavy = Color(0xFF1E293B);
const Color _royalBlue = Color(0xFF1E3A8A);
const Color _bgGray = Color(0xFFF8FAFC);

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
  String? _selectedJobType;

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
        '/quick_job_post',
        <String, dynamic>{
          'documentId': widget.editDocumentId,
          'title': _titleController.text,
          'location': _locationController.text,
          'salary': _salaryController.text,
          'detail': _descriptionController.text,
          'deadline': _deadline,
        },
      );
      context.push('/login');
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
      final selectedType = _selectedJobType ?? 'other';
      final isOtherJob = selectedType == 'other';
      final title = isOtherJob ? _titleController.text.trim() : '';
      final locText = _locationController.text.trim();
      final salary = _salaryController.text.trim();
      final detail = _descriptionController.text.trim();

      final sourceLang = Localizations.localeOf(context).languageCode;
      final inputData = <String, String>{
        if (isOtherJob) 'title': title,
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
              for (final k in inputData.keys)
                k: {'ko': inputData[k]!, 'en': inputData[k]!, 'lo': inputData[k]!},
            };
      } catch (e) {
        if (kDebugMode) debugPrint('_submit: 번역 실패 → 원문 저장: $e');
        bundled = {
          for (final k in inputData.keys)
            k: {'ko': inputData[k]!, 'en': inputData[k]!, 'lo': inputData[k]!},
        };
      }

      if (!isOtherJob) {
        final catalogEntry = kQuickJobCatalog[selectedType];
        bundled['title'] = catalogEntry != null
            ? Map<String, String>.from(catalogEntry)
            : {'ko': selectedType, 'en': selectedType, 'lo': selectedType};
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
          JobFields.jobType: selectedType,
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
          final docRef = FirebaseFirestore.instance
              .collection(kColJobs)
              .doc();
          try {
            await docRef.set(payload)
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            if (kDebugMode) debugPrint('Firestore 저장 오류: $e');
          }
          if (mounted) {
            final localEntry = <String, dynamic>{
              ...payload,
              'documentId': docRef.id,
              'isSample': false,
              JobFields.titleI18n: bundled['title']!,
              JobFields.locationI18n: bundled['location']!,
              JobFields.salaryI18n: bundled['salary']!,
              JobFields.descriptionI18n: bundled['detail']!,
              'deadlineAt': _deadline,
            };
            Navigator.of(context).pop({
              '_firebaseHandled': false,
              ...localEntry,
            });
            return;
          }
        }
      }

      if (mounted) Navigator.of(context).pop({'_firebaseHandled': true});
    } catch (e) {
      if (kDebugMode) debugPrint('_submit 최종 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('error_save_failed'))),
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
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_royalNavy, _royalBlue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.work_outline, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditMode
                      ? context.t('quick_job_post_edit_title')
                      : context.l10n('quick_job_post_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'LaoTrust',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 직무 선택 카드 ──
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(
                    kQuickJobUiText['jobtype_label']?[lang] ?? 'Job type',
                    Icons.work_outline,
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        builder: (ctx) {
                          final sheetLang = Localizations.localeOf(ctx).languageCode;
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: kQuickJobCatalog.entries.map((e) {
                                      return ListTile(
                                        title: Text(
                                          e.value[sheetLang] ?? e.value['en'] ?? e.key,
                                        ),
                                        onTap: () => Navigator.of(ctx).pop(e.key),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      );
                      if (selected != null && mounted) {
                        setState(() {
                          _selectedJobType = selected;
                          if (selected != 'other') _titleController.clear();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedJobType != null
                              ? _royalBlue
                              : Colors.grey.shade300,
                          width: _selectedJobType != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: _selectedJobType != null
                            ? _royalBlue.withValues(alpha: 0.05)
                            : Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: _selectedJobType != null
                                ? _royalBlue
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedJobType == null
                                  ? (kQuickJobUiText['select_job_type']?[lang] ?? 'Select job type')
                                  : (kQuickJobCatalog[_selectedJobType!]?[lang] ?? _selectedJobType!),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedJobType != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _selectedJobType == null
                                    ? Colors.grey.shade500
                                    : _royalBlue,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: _selectedJobType != null
                                ? _royalBlue
                                : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ② 기타 제목 입력칸
                  if (_selectedJobType == 'other') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: context.l10n('quick_job_field_title'),
                        hintText: context.l10n('quick_job_title_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _royalBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── 근무 정보 카드 ──
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(
                    context.l10n('quick_job_field_location'),
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildStyledField(
                    controller: _locationController,
                    hint: context.l10n('quick_job_location_hint'),
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                    context.l10n('quick_job_field_salary'),
                    Icons.payments_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildStyledField(
                    controller: _salaryController,
                    hint: context.l10n('quick_job_salary_hint'),
                    prefixIcon: Icons.payments_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── 상세 정보 카드 ──
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(
                    context.l10n('quick_job_field_detail'),
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildStyledField(
                    controller: _descriptionController,
                    hint: context.l10n('quick_job_detail_hint'),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── 마감일 카드 ──
            _buildSectionCard(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: _royalBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n('quick_job_deadline_title'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _royalNavy,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')} ${_deadline.hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deadline,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null && mounted) {
                        setState(() => _deadline = DateTime(
                            picked.year, picked.month, picked.day, _deadline.hour));
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: _royalBlue),
                    child: Text(context.l10n('quick_job_deadline_pick_date')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // ── 등록 버튼 (그라디언트) ──
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_royalNavy, _royalBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _royalBlue.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: _royalNavy.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_saving || _isLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.isEditMode
                                ? context.t('quick_job_post_save_edit')
                                : context.t('quick_job_post_submit'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── 섹션 카드 래퍼 ──
  Widget _buildSectionCard({required Widget child, Color? accentColor}) {
    final color = accentColor ?? _royalBlue;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.4)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── 섹션 라벨 (아이콘 + 텍스트) ──
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _royalBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: _royalBlue),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _royalNavy,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ── 스타일 통일 TextField ──
  Widget _buildStyledField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _royalBlue.withValues(alpha: 0.6), size: 18)
            : null,
        filled: true,
        fillColor: _bgGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _royalBlue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 8 : 16,
          vertical: 14,
        ),
      ),
    );
  }
}
