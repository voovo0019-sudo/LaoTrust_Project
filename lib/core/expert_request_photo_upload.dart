// v5.c1: 전문가 요청 사진 → Firebase Storage 업로드 후 다운로드 URL 반환.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

String _storageSafeSegment(String raw) {
  if (raw.isEmpty) return 'anon';
  final s = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return s.length > 96 ? s.substring(0, 96) : s;
}

String _extForXFile(XFile x) {
  final pathLower = x.path.toLowerCase();
  if (pathLower.endsWith('.png')) return 'png';
  if (pathLower.endsWith('.webp')) return 'webp';
  if (pathLower.endsWith('.heic')) return 'heic';
  final mime = x.mimeType?.toLowerCase() ?? '';
  if (mime.contains('png')) return 'png';
  if (mime.contains('webp')) return 'webp';
  if (mime.contains('heic')) return 'heic';
  return 'jpg';
}

/// 선택한 이미지를 Storage에 올리고 `getDownloadURL()` 문자열 목록을 반환한다.
Future<List<String>> uploadExpertRequestImagesFromXFiles({
  required List<XFile> files,
  required String userId,
}) async {
  if (!isFirebaseEnabled || files.isEmpty) return [];
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    try {
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return [];
    }
    user ??= FirebaseAuth.instance.currentUser;
  }
  if (user == null) return [];
  await user.getIdToken(true);
  final storage = FirebaseStorage.instanceFor(
    bucket: 'laotrust-web.firebasestorage.app',
  );
  final safeUser = _storageSafeSegment(userId);
  final batch = DateTime.now().millisecondsSinceEpoch;
  final urls = <String>[];
  for (var i = 0; i < files.length; i++) {
    final x = files[i];
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) continue;
    final ext = _extForXFile(x);
    final name = '${i}_$batch.$ext';
    final ref = storage.ref('artifacts/$safeUser/expert_requests/$batch/$name');
    final mime = x.mimeType ?? 'image/jpeg';
    await ref.putData(bytes, SettableMetadata(contentType: mime));
    urls.add(await ref.getDownloadURL());
  }
  return urls;
}

/// 오프라인 큐 플러시용: 저장해 두었던 로컬 경로 목록에서 업로드.
Future<List<String>> uploadExpertRequestImagesFromLocalPaths({
  required List<String> paths,
  required String userId,
}) async {
  if (paths.isEmpty) return [];
  if (kIsWeb) return [];
  final files = <XFile>[];
  for (final p in paths) {
    if (p.isEmpty) continue;
    files.add(XFile(p));
  }
  return uploadExpertRequestImagesFromXFiles(files: files, userId: userId);
}
