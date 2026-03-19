// =============================================================================
// v1.3: 신뢰 검문소 — 라오트러스트 파트너 지원 (신분증·자격증·포트폴리오 업로드)
// 지사장님 검수 파이프라인 연동 시 Firestore/Cloud Functions 참고.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/app_localizations.dart';
import '../../core/firebase_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

const String partnerSupportCenterRouteName = '/partner-support-center';
const Color _royalNavy = Color(0xFF1E293B);

class PartnerSupportCenterScreen extends StatefulWidget {
  const PartnerSupportCenterScreen({super.key});

  @override
  State<PartnerSupportCenterScreen> createState() => _PartnerSupportCenterScreenState();
}

class _PartnerSupportCenterScreenState extends State<PartnerSupportCenterScreen> {
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  XFile? _idImage;
  XFile? _certImage;
  final List<XFile> _portfolioImages = <XFile>[];

  String? _idDownloadUrl;
  String? _certDownloadUrl;
  final List<String> _portfolioDownloadUrls = <String>[];

  bool get _idUploaded => _idImage != null;
  bool get _certUploaded => _certImage != null;
  bool get _portfolioUploaded => _portfolioImages.isNotEmpty;

  String? get _uid => auth.currentUser?.uid;

  Reference _refFor({required String type, int? index}) {
    final uid = _uid ?? 'anonymous';
    final ts = DateTime.now().millisecondsSinceEpoch;
    if (type == 'portfolio') {
      final i = index ?? _portfolioImages.length;
      return FirebaseStorage.instance.ref('partner_support/$uid/portfolio_${i}_$ts.jpg');
    }
    return FirebaseStorage.instance.ref('partner_support/$uid/${type}_$ts.jpg');
  }

  Future<String?> _uploadToStorage(XFile file, {required String type, int? index}) async {
    if (!isFirebaseEnabled) return null;
    final ref = _refFor(type: type, index: index);
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await ref.putData(bytes, metadata).timeout(const Duration(seconds: 15));
      } else {
        await ref.putFile(File(file.path), metadata).timeout(const Duration(seconds: 15));
      }
      return await ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Keep local preview even when cloud upload is delayed/failed.
      return null;
    }
  }

  Future<void> _deleteFromStorageByUrl(String? url) async {
    if (!isFirebaseEnabled) return;
    if (url == null || url.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore: file may already be deleted or URL invalid.
    }
  }

  void _toggleOffIfUploaded(String type) {
    setState(() {
      if (type == 'id') {
        _idImage = null;
        _idDownloadUrl = null;
      }
      if (type == 'cert') {
        _certImage = null;
        _certDownloadUrl = null;
      }
      if (type == 'portfolio') {
        _portfolioImages.clear();
        _portfolioDownloadUrls.clear();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n('partner_upload_removed')),
        backgroundColor: _royalNavy,
      ),
    );
  }

  Future<void> _pickFromGallery(String type) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (type == 'portfolio') {
        final remaining = (5 - _portfolioImages.length).clamp(0, 5);
        if (remaining <= 0) return;
        final images = await _picker.pickMultiImage(imageQuality: 85);
        if (!mounted) return;
        if (images.isEmpty) return;
        final picked = images.take(remaining).toList();
        setState(() => _portfolioImages.addAll(picked));
        if (isFirebaseEnabled) {
          for (final f in picked) {
            final url = await _uploadToStorage(f, type: 'portfolio', index: _portfolioImages.indexOf(f));
            if (!mounted) return;
            if (url != null) {
              setState(() => _portfolioDownloadUrls.add(url));
            }
          }
        }
      } else {
        final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (!mounted) return;
        if (image == null) return;
        if (type == 'id') {
          setState(() => _idImage = image);
          final url = await _uploadToStorage(image, type: 'id');
          if (!mounted) return;
          if (url != null) setState(() => _idDownloadUrl = url);
        }
        if (type == 'cert') {
          setState(() => _certImage = image);
          final url = await _uploadToStorage(image, type: 'cert');
          if (!mounted) return;
          if (url != null) setState(() => _certDownloadUrl = url);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('partner_upload_success')),
          backgroundColor: _royalNavy,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFromCamera(String type) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (type == 'portfolio' && _portfolioImages.length >= 5) return;
      final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (!mounted) return;
      if (image == null) return;
      if (type == 'id') {
        setState(() => _idImage = image);
        final url = await _uploadToStorage(image, type: 'id');
        if (!mounted) return;
        if (url != null) setState(() => _idDownloadUrl = url);
      }
      if (type == 'cert') {
        setState(() => _certImage = image);
        final url = await _uploadToStorage(image, type: 'cert');
        if (!mounted) return;
        if (url != null) setState(() => _certDownloadUrl = url);
      }
      if (type == 'portfolio') {
        setState(() => _portfolioImages.add(image));
        final url = await _uploadToStorage(image, type: 'portfolio', index: _portfolioImages.length - 1);
        if (!mounted) return;
        if (url != null) setState(() => _portfolioDownloadUrls.add(url));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('partner_upload_success')),
          backgroundColor: _royalNavy,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showPickMenu(String type) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n('partner_pick_gallery')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFromGallery(type);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(context.l10n('partner_pick_camera')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFromCamera(type);
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(context.l10n('confirm')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(XFile file, {required VoidCallback onRemove}) {
    final img = kIsWeb ? Image.network(file.path, fit: BoxFit.cover) : Image.file(File(file.path), fit: BoxFit.cover);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 44, height: 44, child: img),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _royalNavy, width: 1.2),
              ),
              child: const Icon(Icons.close, size: 14, color: _royalNavy),
            ),
          ),
        ),
      ],
    );
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
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            content: Text(
                              context.l10n('partner_review_complete_message'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.of(context).popUntil(
                                    (route) => route.isFirst,
                                  );
                                },
                                child: Text(context.l10n('confirm')),
                              ),
                            ],
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
            _showPickMenu(type);
          };
    final preview = switch (type) {
      'id' => _idImage,
      'cert' => _certImage,
      _ => null,
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
            if (_saving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (type == 'portfolio' && _portfolioImages.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final f in _portfolioImages.take(2))
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _thumb(
                        f,
                        onRemove: () {
                          final idx = _portfolioImages.indexOf(f);
                          String? urlToDelete;
                          if (idx >= 0 && idx < _portfolioDownloadUrls.length) {
                            urlToDelete = _portfolioDownloadUrls[idx];
                          }
                          setState(() {
                            _portfolioImages.remove(f);
                            if (idx >= 0 && idx < _portfolioDownloadUrls.length) {
                              _portfolioDownloadUrls.removeAt(idx);
                            }
                          });
                          _deleteFromStorageByUrl(urlToDelete);
                          if (_portfolioImages.isEmpty) _toggleOffIfUploaded('portfolio');
                        },
                      ),
                    ),
                  if (_portfolioImages.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '+${_portfolioImages.length - 2}',
                        style: const TextStyle(color: _royalNavy, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              )
            else if (preview != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _thumb(
                  preview,
                  onRemove: () {
                    final urlToDelete = type == 'id' ? _idDownloadUrl : _certDownloadUrl;
                    _toggleOffIfUploaded(type);
                    _deleteFromStorageByUrl(urlToDelete);
                  },
                ),
              )
            else
              const Icon(Icons.upload_file, color: _royalNavy, size: 26),
          ],
        ),
      ),
    );
  }
}
