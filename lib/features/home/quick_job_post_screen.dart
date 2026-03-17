// =============================================================================
// v1.3: 급구 알바 구인 등록 UI — [알바 구인+] 진입
// 디자인: 곡률 28px, 로얄 네이비 #1E293B.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';

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
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saving = false);
    final job = <String, dynamic>{
      'title': _titleController.text.trim().isEmpty ? '알바 공고' : _titleController.text.trim(),
      'loc': _locationController.text.trim().isEmpty ? '미정' : _locationController.text.trim(),
      'salary': _salaryController.text.trim().isEmpty ? '협의' : _salaryController.text.trim(),
      'detail': _descriptionController.text.trim(),
      'deadlineAt': _deadline,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    Navigator.of(context).pop(job);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _royalNavy,
        foregroundColor: Colors.white,
        title: const Text('알바 구인 등록'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildField(
              context.l10n('job_detail_description').replaceAll('상세 내용', '제목'),
              _titleController,
              hint: context.l10n('job_title_event_staff'),
            ),
            const SizedBox(height: 16),
            _buildField(
              context.l10n('job_detail_location'),
              _locationController,
              hint: context.l10n('location_downtown'),
            ),
            const SizedBox(height: 16),
            _buildField(
              context.l10n('job_detail_salary'),
              _salaryController,
              hint: context.l10n('salary_negotiable'),
            ),
            const SizedBox(height: 16),
            _buildField(
              context.l10n('job_detail_description'),
              _descriptionController,
              hint: '업무 내용을 입력하세요',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '마감 시각',
                style: TextStyle(
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
                child: const Text('날짜 선택'),
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
                  : Text(context.l10n('quick_job_post_submit')),
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
