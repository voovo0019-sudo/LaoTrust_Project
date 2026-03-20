// =============================================================================
// v1.3: 급구 알바 구인 등록 UI — [알바 구인+] 진입
// 디자인: 곡률 28px, 로얄 네이비 #1E293B.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import '../../core/location_service.dart';
import '../../data/firestore_schema.dart';

const String quickJobPostRouteName = '/quick-job-post';
const Color _royalNavy = Color(0xFF1E293B);

class QuickJobPostScreen extends StatefulWidget {
  const QuickJobPostScreen({super.key});

  @override
  State<QuickJobPostScreen> createState() => _QuickJobPostScreenState();
}

class _QuickJobPostScreenState extends State<QuickJobPostScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(hours: 24));
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final title = _titleController.text.trim();
    final locText = _locationController.text.trim();
    final salary = _salaryController.text.trim();
    final detail = _descriptionController.text.trim();

    // UI 즉시 반영용(로컬) 데이터
    final jobForUi = <String, dynamic>{
      'title': title.isEmpty ? context.l10n('quick_job_default_title') : title,
      'loc': locText.isEmpty ? context.l10n('quick_job_default_location') : locText,
      'salary': salary.isEmpty ? context.l10n('salary_negotiable') : salary,
      'detail': detail,
      'deadlineAt': _deadline,
      'createdAt': nowMs,
      'tag': 'quick_job_tag_part_time',
    };

    // Firestore 실시간 동기화(웹/모바일 공통)
    if (isFirebaseEnabled) {
      try {
        final (p, _) = await getUserLocationOrDefault();
        final geo = GeoPoint(p.latitude, p.longitude);

        // Store language-neutral keys for defaults so UI can localize dynamically.
        final titleValue = title.isEmpty ? null : title;
        final titleKey = title.isEmpty ? 'quick_job_default_title' : null;
        final locValue = locText.isEmpty ? null : locText;
        final locKey = locText.isEmpty ? 'quick_job_default_location' : null;
        final salaryValue = salary.isEmpty ? null : salary;
        final salaryKey = salary.isEmpty ? 'salary_negotiable' : null;

        await firestore.collection(kColJobs).add({
          JobFields.title: titleValue ?? titleKey,
          JobFields.location: locValue ?? locKey,
          JobFields.salary: salaryValue ?? salaryKey,
          JobFields.description: detail,
          JobFields.deadlineAt: Timestamp.fromDate(_deadline),
          JobFields.createdAt: FieldValue.serverTimestamp(),
          JobFields.updatedAt: FieldValue.serverTimestamp(),
          JobFields.locationGeo: geo,
          JobFields.jobType: 'quick_job_tag_part_time',
          JobFields.employerId: auth.currentUser?.uid,
        });
      } catch (_) {
        // 동기화 실패해도 UI는 먼저 완료 처리(오프라인/권한 등 케이스)
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(jobForUi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _royalNavy,
        foregroundColor: Colors.white,
        title: Text(context.l10n('quick_job_post_title')),
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
                  : Text(context.t('quick_job_post_submit')),
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
