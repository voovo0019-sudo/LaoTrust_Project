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
        'contact': data['contact']?.toString() ?? '',
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
                'contact': data['contact']?.toString() ?? '',
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

  /// 구인자 본인 공고에 달린 지원자 목록을 실시간 스트림으로 반환
  Stream<List<Map<String, dynamic>>> watchMyJobApplications(String employerId) {
    if (!isFirebaseEnabled) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection(kColApplications)
        .where(ApplicationFields.employerId, isEqualTo: employerId)
        .orderBy(ApplicationFields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'documentId': doc.id,
                'jobId': data[ApplicationFields.jobId] ?? '',
                'applicantId': data[ApplicationFields.applicantId] ?? '',
                'employerId': data[ApplicationFields.employerId] ?? '',
                'jobTitleI18n': data[ApplicationFields.jobTitleI18n] ?? {'ko': '', 'en': '', 'lo': ''},
                'status': data[ApplicationFields.status] ?? kAppStatusPending,
                'createdAt': data[ApplicationFields.createdAt] is Timestamp
                    ? (data[ApplicationFields.createdAt] as Timestamp).millisecondsSinceEpoch
                    : 0,
              };
            }).toList());
  }

  /// 구직자 본인이 지원한 알바 목록을 실시간 스트림으로 반환
  Stream<List<Map<String, dynamic>>> watchMyApplicationsAsApplicant(String applicantId) {
    if (!isFirebaseEnabled) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection(kColApplications)
        .where(ApplicationFields.applicantId, isEqualTo: applicantId)
        .orderBy(ApplicationFields.createdAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'documentId': doc.id,
                'jobId': data[ApplicationFields.jobId] ?? '',
                'applicantId': data[ApplicationFields.applicantId] ?? '',
                'employerId': data[ApplicationFields.employerId] ?? '',
                'jobTitleI18n': data[ApplicationFields.jobTitleI18n] ?? {'ko': '', 'en': '', 'lo': ''},
                'status': data[ApplicationFields.status] ?? kAppStatusPending,
                'createdAt': data[ApplicationFields.createdAt] is Timestamp
                    ? (data[ApplicationFields.createdAt] as Timestamp).millisecondsSinceEpoch
                    : 0,
              };
            }).toList());
  }

  // ─────────────────────────────────────────────────────────────
  // 채팅 관련 함수
  // ─────────────────────────────────────────────────────────────

  /// 수락(accepted) 시 1:1 채팅방 생성.
  /// 이미 같은 jobId+applicantId 방이 있으면 기존 방 ID 반환 (중복 방지).
  Future<String> createChatRoom({
    required String jobId,
    required Map<String, dynamic> jobTitleI18n,
    required String employerId,
    required String applicantId,
  }) async {
    if (!isFirebaseEnabled) return '';
    final existing = await FirebaseFirestore.instance
        .collection(kColChats)
        .where(ChatFields.jobId, isEqualTo: jobId)
        .where(ChatFields.applicantId, isEqualTo: applicantId)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    final ref = FirebaseFirestore.instance.collection(kColChats).doc();
    await ref.set({
      ChatFields.jobId: jobId,
      ChatFields.jobTitleI18n: jobTitleI18n,
      ChatFields.employerId: employerId,
      ChatFields.applicantId: applicantId,
      ChatFields.participants: [employerId, applicantId],
      ChatFields.lastMessage: '',
      ChatFields.lastMessageAt: FieldValue.serverTimestamp(),
      ChatFields.createdAt: FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// 내가 참여 중인 채팅방 목록 실시간 스트림.
  Stream<List<Map<String, dynamic>>> watchMyChatRooms(String uid) {
    if (!isFirebaseEnabled) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection(kColChats)
        .where(ChatFields.participants, arrayContains: uid)
        .orderBy(ChatFields.lastMessageAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'chatId': doc.id,
                'jobId': data[ChatFields.jobId] ?? '',
                'jobTitleI18n': data[ChatFields.jobTitleI18n] ?? {'ko': '', 'en': '', 'lo': ''},
                'employerId': data[ChatFields.employerId] ?? '',
                'applicantId': data[ChatFields.applicantId] ?? '',
                'participants': data[ChatFields.participants] ?? [],
                'lastMessage': data[ChatFields.lastMessage] ?? '',
                'lastMessageAt': data[ChatFields.lastMessageAt] is Timestamp
                    ? (data[ChatFields.lastMessageAt] as Timestamp).millisecondsSinceEpoch
                    : 0,
              };
            }).toList());
  }

  /// 채팅방 메시지 실시간 스트림.
  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    if (!isFirebaseEnabled) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection(kColChats)
        .doc(chatId)
        .collection(kColMessages)
        .orderBy(MessageFields.createdAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'messageId': doc.id,
                'senderId': data[MessageFields.senderId] ?? '',
                'text': data[MessageFields.text] ?? '',
                'imageUrl': data[MessageFields.imageUrl] ?? '',
                'isRead': data[MessageFields.isRead] ?? false,
                'translatedTextCache': data[MessageFields.translatedTextCache] ?? {},
                'createdAt': data[MessageFields.createdAt] is Timestamp
                    ? (data[MessageFields.createdAt] as Timestamp).millisecondsSinceEpoch
                    : 0,
              };
            }).toList());
  }

  /// 메시지 전송 (텍스트 or 사진 URL).
  /// 전송 후 채팅방 lastMessage / lastMessageAt 업데이트.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String text = '',
    String imageUrl = '',
  }) async {
    if (!isFirebaseEnabled) return;
    final msgRef = FirebaseFirestore.instance
        .collection(kColChats)
        .doc(chatId)
        .collection(kColMessages)
        .doc();
    await msgRef.set({
      MessageFields.senderId: senderId,
      MessageFields.text: text,
      MessageFields.imageUrl: imageUrl,
      MessageFields.isRead: false,
      MessageFields.createdAt: FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection(kColChats)
        .doc(chatId)
        .update({
      ChatFields.lastMessage: text.isNotEmpty ? text : '📷 사진',
      ChatFields.lastMessageAt: FieldValue.serverTimestamp(),
    });
  }

  /// 채팅방 입장 시 상대방 메시지 읽음 처리.
  Future<void> markMessagesAsRead({
    required String chatId,
    required String myUid,
  }) async {
    if (!isFirebaseEnabled) return;
    final unread = await FirebaseFirestore.instance
        .collection(kColChats)
        .doc(chatId)
        .collection(kColMessages)
        .where(MessageFields.isRead, isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      final data = doc.data();
      if (data[MessageFields.senderId] != myUid) {
        batch.update(doc.reference, {MessageFields.isRead: true});
      }
    }
    await batch.commit();
  }

  /// 메시지 번역 결과를 Firestore에 캐시 저장.
  /// 같은 메시지를 다시 번역할 때 API 재호출 없이 캐시에서 바로 가져오기 위함.
  Future<void> cacheTranslatedMessage({
    required String chatId,
    required String messageId,
    required String langCode,
    required String translatedText,
  }) async {
    if (!isFirebaseEnabled) return;
    await FirebaseFirestore.instance
        .collection(kColChats)
        .doc(chatId)
        .collection(kColMessages)
        .doc(messageId)
        .update({
      '${MessageFields.translatedTextCache}.$langCode': translatedText,
    });
  }
}
