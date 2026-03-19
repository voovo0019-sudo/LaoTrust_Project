// =============================================================================
// v1.3: 신뢰 검문소 — 라오트러스트 파트너 지원 (신분증·자격증·포트폴리오 업로드)
// 지사장님 검수 파이프라인 연동 시 Firestore/Cloud Functions 참고.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/app_localizations.dart';

const String partnerSupportCenterRouteName = '/partner-support-center';
const Color _royalNavy = Color(0xFF1E293B);

class PartnerSupportCenterScreen extends StatefulWidget {
  const PartnerSupportCenterScreen({super.key});

  @override
  State<PartnerSupportCenterScreen> createState() => _PartnerSupportCenterScreenState();
}

class _PartnerSupportCenterScreenState extends State<PartnerSupportCenterScreen> {
  bool _idUploaded = false;
  bool _certUploaded = false;
  bool _portfolioUploaded = false;
  bool _saving = false;

  void _toggleOffIfUploaded(String type) {
    setState(() {
      if (type == 'id') _idUploaded = false;
      if (type == 'cert') _certUploaded = false;
      if (type == 'portfolio') _portfolioUploaded = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n('partner_upload_removed')),
        backgroundColor: _royalNavy,
      ),
    );
  }

  Future<void> _pickAndUpload(String type) async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (type == 'id') _idUploaded = true;
      if (type == 'cert') _certUploaded = true;
      if (type == 'portfolio') _portfolioUploaded = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('partner_upload_success')),
          backgroundColor: _royalNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _royalNavy,
        foregroundColor: Colors.white,
        title: Text(context.l10n('partner_support_center_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildUploadSection(
              context.l10n('partner_upload_id'),
              context.l10n('partner_upload_id_hint'),
              Icons.badge,
              _idUploaded,
              type: 'id',
            ),
            const SizedBox(height: 16),
            _buildUploadSection(
              context.l10n('partner_upload_cert'),
              context.l10n('partner_upload_cert_hint'),
              Icons.card_membership,
              _certUploaded,
              type: 'cert',
            ),
            const SizedBox(height: 16),
            _buildUploadSection(
              context.l10n('partner_upload_portfolio'),
              context.l10n('partner_upload_portfolio_hint'),
              Icons.photo_library,
              _portfolioUploaded,
              type: 'portfolio',
            ),
            const SizedBox(height: 32),
            if (_idUploaded && _certUploaded)
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n('partner_submit_for_review')),
                            backgroundColor: _royalNavy,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _royalNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(context.l10n('partner_submit_for_review')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _royalNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _royalNavy.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _royalNavy, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n('partner_support_center_info'),
              style: const TextStyle(
                color: _royalNavy,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(
    String title,
    String hint,
    IconData icon,
    bool uploaded,
    {required String type}
  ) {
    final VoidCallback? onTap = _saving
        ? null
        : () {
            if (uploaded) {
              _toggleOffIfUploaded(type);
              return;
            }
            _pickAndUpload(type);
          };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _royalNavy.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _royalNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _royalNavy, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _royalNavy,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (uploaded)
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28)
            else if (_saving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.upload_file, color: _royalNavy, size: 26),
          ],
        ),
      ),
    );
  }
}
