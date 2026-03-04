import 'package:cloud_firestore/cloud_firestore.dart';

// 라오트러스트 수사본부 전용 데이터 서비스 (v2.0)
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. 전문가 서비스 목록 실시간 스트리밍 (order 순 정렬)
  Stream<List<Map<String, dynamic>>> getExpertServices() {
    return _db.collection('expert_services').orderBy('order').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // 2. 급구 알바 목록 실시간 스트리밍 (최신순 정렬)
  Stream<List<Map<String, dynamic>>> getQuickJobs() {
    return _db.collection('quick_jobs').orderBy('created_at', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}