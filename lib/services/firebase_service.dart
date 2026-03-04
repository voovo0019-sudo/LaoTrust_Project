import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. 전문가 서비스 (정렬 없이 일단 다 가져오기)
  Stream<List<Map<String, dynamic>>> getExpertServices() {
    return _db.collection('expert_services').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // 2. 급구 알바 (정렬 없이 일단 다 가져오기)
  Stream<List<Map<String, dynamic>>> getQuickJobs() {
    return _db.collection('quick_jobs').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}