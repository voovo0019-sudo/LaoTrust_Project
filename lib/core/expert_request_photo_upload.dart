// v5.c2: 익명/미로그인 차단 + 토큰 갱신 + 실패 시 빈 배열 반환
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

/// 정식 로그인 유저인지 확인 (익명 + 미로그인 모두 차단)
bool _isVerifiedUser(User? user) {
  if (user == null) return false;
  if (user.isAnonymous) return false;
  return true;
}

/// Storage 업로드 + getDownloadURL() 반환
/// 미로그인/익명 유저는 빈 배열 반환 (저장은 계속 진행)
Future<List<String>> uploadExpertRequestImagesFromXFiles({
  required List<XFile> files,
  required String userId,
}) async {
  if (!isFirebaseEnabled || files.isEmpty) return [];

  // 1단계: Auth 상태 확인
  User? user = FirebaseAuth.instance.currentUser;
  if (!_isVerifiedUser(user)) {
    try {
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      if (kDebugMode) debugPrint('[Storage] Auth 대기 타임아웃 → 업로드 스킵');
      return [];
    }
  }

  // 2단계: 익명/미로그인 최종 차단
  if (!_isVerifiedUser(user)) {
    if (kDebugMode) debugPrint('[Storage] 익명 또는 미로그인 유저 → 업로드 차단');
    return [];
  }

  // 3단계: 토큰 강제 갱신
  try {
    await user!.getIdToken(true);
  } catch (e) {
    if (kDebugMode) debugPrint('[Storage] 토큰 갱신 실패 → 업로드 스킵: $e');
    return [];
  }

  final storage = FirebaseStorage.instanceFor(
    bucket: 'laotrust-web.firebasestorage.app',
  );
  final safeUser = _storageSafeSegment(userId);
  final batch = DateTime.now().millisecondsSinceEpoch;
  final urls = <String>[];

  for (var i = 0; i < files.length; i++) {
    try {
      final x = files[i];
      final bytes = await x.readAsBytes();
      if (bytes.isEmpty) continue;
      final ext = _extForXFile(x);
      final name = '${i}_$batch.$ext';
      final ref = storage.ref('artifacts/$safeUser/expert_requests/$batch/$name');
      final mime = x.mimeType ?? 'image/jpeg';
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      urls.add(await ref.getDownloadURL());
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] 개별 사진 업로드 실패 (스킵): $e');
      // 개별 실패 시 다음 사진으로 계속 진행
    }
  }
  return urls;
}

/// 모바일 전용: 로컬 경로 → XFile 변환 후 업로드
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
