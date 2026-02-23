// LT-08 미션02: 오프라인 우선(Offline-First) — 잠복 수사 모드.
// 데이터를 기기에 먼저 임시 저장하고, 연결 시 자동 전송.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/firestore_schema.dart';
import 'firebase_service.dart';

const String _keyPending = 'laotrust_pending_requests';

/// 오프라인 시 로컬에 적재해 두었다가, 온라인 시 Firestore로 전송.
Future<void> saveRequestOfflineFirst({
  required String category,
  required Map<String, dynamic> payload,
}) async {
  if (isFirebaseEnabled) {
    final result = await Connectivity().checkConnectivity();
    final online = result.any((e) =>
        e == ConnectivityResult.mobile ||
        e == ConnectivityResult.wifi ||
        e == ConnectivityResult.ethernet);
    if (online) {
      await _sendToFirestore(category: category, payload: payload);
      return;
    }
  }
  await _enqueueLocal(category: category, payload: payload);
}

Future<void> _enqueueLocal({
  required String category,
  required Map<String, dynamic> payload,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_keyPending) ?? [];
  list.add(jsonEncode({
    'category': category,
    'payload': payload,
    'at': DateTime.now().toIso8601String(),
  }));
  await prefs.setStringList(_keyPending, list);
}

Future<void> _sendToFirestore({
  required String category,
  required Map<String, dynamic> payload,
}) async {
  await firestore.collection(kColRequests).add({
    RequestFields.category: category,
    ...payload,
    RequestFields.createdAt: FieldValue.serverTimestamp(),
    RequestFields.updatedAt: FieldValue.serverTimestamp(),
  });
}

/// 연결 복구 시 대기 중인 요청 일괄 전송. 앱 시작·포그라운드 시 호출 권장.
Future<int> flushPendingRequestsWhenOnline() async {
  if (!isFirebaseEnabled) return 0;
  final result = await Connectivity().checkConnectivity();
  final online = result.any((e) =>
      e == ConnectivityResult.mobile ||
      e == ConnectivityResult.wifi ||
      e == ConnectivityResult.ethernet);
  if (!online) return 0;

  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_keyPending) ?? [];
  if (list.isEmpty) return 0;

  final remaining = <String>[];
  int sent = 0;
  for (final raw in list) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final category = map['category'] as String;
      final payload = map['payload'] as Map<String, dynamic>;
      await _sendToFirestore(category: category, payload: payload);
      sent++;
    } catch (_) {
      remaining.add(raw);
    }
  }
  await prefs.setStringList(_keyPending, remaining);
  return sent;
}
