// =============================================================================
// 전문가 서비스 / 급구 알바 데이터 계층 전용. UI 코드 없음.
// =============================================================================

import 'package:lao_trust/core/firebase_service.dart';
import 'package:lao_trust/data/firestore_schema.dart';

/// 전문가 서비스·급구 알바 Firestore 스트림 제공. UI는 사용처(예: HomeScreen)에서만 처리.
class FirebaseService {
  FirebaseService();

  /// 전문가 서비스 목록 실시간 스트림.
  /// 컬렉션: expert_services. 필드: name, icon, color (int 색상 코드 문자열).
  Stream<List<Map<String, dynamic>>> getExpertServices() {
    if (!isFirebaseEnabled) {
      return Stream.value([]);
    }
    return firestore.collection('expert_services').snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data())
          .map((data) => {
                'name': data['name'],
                'icon': data['icon'],
                'color': data['color']?.toString(),
              })
          .toList();
    });
  }

  /// 급구 알바 목록 실시간 스트림.
  /// 컬렉션: jobs. 필드: title, loc(location), tag(jobType), tagColor.
  Stream<List<Map<String, dynamic>>> getQuickJobs() {
    if (!isFirebaseEnabled) {
      return Stream.value([]);
    }
    return firestore
        .collection(kColJobs)
        .orderBy(JobFields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data[JobFields.createdAt];
        final deadlineAt = data[JobFields.deadlineAt];
        return {
          'title': data[JobFields.title],
          'loc': data[JobFields.location],
          'salary': data[JobFields.salary],
          'detail': data[JobFields.description],
          'tag': data[JobFields.jobType] ?? '알바',
          'tagColor': data['tagColor']?.toString() ?? '0xFF9E9E9E',
          'createdAt': createdAt,
          'deadlineAt': deadlineAt,
          'isSample': false,
        };
      }).toList();
    });
  }
}
