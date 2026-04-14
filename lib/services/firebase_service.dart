// =============================================================================
// 전문가 서비스 / 급구 알바 데이터 계층 전용. UI 코드 없음.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lao_trust/core/firebase_service.dart';
import 'package:lao_trust/core/quick_job_triple_map_builder.dart';
import 'package:lao_trust/data/firestore_schema.dart';

/// 전문가 서비스·급구 알바 Firestore 스트림 제공. UI는 사용처(예: HomeScreen)에서만 처리.
class FirebaseService {
  FirebaseService();

  int _createdAtMillis(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    return 0;
  }

  dynamic _normalizeDeadline(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return v;
  }

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

  /// 급구 알바 목록 일회 조회 (`Query.get`).
  /// v10.8: title_i18n 등 Map 우선, 레거시 String은 healQuickJobI18nField로 즉시 정규화.
  Future<List<Map<String, dynamic>>> getQuickJobs() async {
    if (!isFirebaseEnabled) {
      return [];
    }
    final snapshot = await firestore
        .collection(kColJobs)
        .orderBy(JobFields.createdAt, descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = data[JobFields.createdAt];
      final deadlineAt = data[JobFields.deadlineAt];
      final titleMap = healQuickJobI18nField(
        data[JobFields.titleI18n] ?? data[JobFields.title],
      );
      final locMap = healQuickJobI18nField(
        data[JobFields.locationI18n] ?? data[JobFields.location],
      );
      final salaryMap = healQuickJobI18nField(
        data[JobFields.salaryI18n] ?? data[JobFields.salary],
      );
      final detailMap = healQuickJobI18nField(
        data[JobFields.descriptionI18n] ?? data[JobFields.description],
      );
      return {
        'documentId': doc.id,
        'employerId': data[JobFields.employerId],
        'titleMap': titleMap,
        'locMap': locMap,
        'salaryMap': salaryMap,
        'detailMap': detailMap,
        'tag': data[JobFields.jobType] ?? 'quick_job_tag_part_time',
        'tagColor': data['tagColor']?.toString() ?? '0xFF9E9E9E',
        'createdAt': _createdAtMillis(createdAt),
        'deadlineAt': _normalizeDeadline(deadlineAt),
        'isSample': false,
      };
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> watchQuickJobs() {
    if (!isFirebaseEnabled) {
      return Stream.value([]);
    }
    return firestore
        .collection(kColJobs)
        .orderBy(JobFields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final titleMap = healQuickJobI18nField(
                data[JobFields.titleI18n] ?? data[JobFields.title],
              );
              final locMap = healQuickJobI18nField(
                data[JobFields.locationI18n] ?? data[JobFields.location],
              );
              final salaryMap = healQuickJobI18nField(
                data[JobFields.salaryI18n] ?? data[JobFields.salary],
              );
              final detailMap = healQuickJobI18nField(
                data[JobFields.descriptionI18n] ?? data[JobFields.description],
              );
              return {
                'documentId': doc.id,
                'employerId': data[JobFields.employerId],
                'titleMap': titleMap,
                'locMap': locMap,
                'salaryMap': salaryMap,
                'detailMap': detailMap,
                'tag': data[JobFields.jobType] ?? 'quick_job_tag_part_time',
                'tagColor': data['tagColor']?.toString() ?? '0xFF9E9E9E',
                'createdAt': data[JobFields.createdAt] is Timestamp
                    ? (data[JobFields.createdAt] as Timestamp).millisecondsSinceEpoch
                    : 0,
                'deadlineAt': data[JobFields.deadlineAt] is Timestamp
                    ? (data[JobFields.deadlineAt] as Timestamp).toDate()
                    : null,
                'isSample': false,
              };
            }).toList());
  }

  /// 본인 급구 알바 공고 삭제 (문서 ID).
  Future<void> deleteQuickJobDocument(String documentId) async {
    if (!isFirebaseEnabled) return;
    await firestore.collection(kColJobs).doc(documentId).delete();
  }
}
