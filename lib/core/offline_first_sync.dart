// LT-08 태스크02: 오프라인 우선 저장 + 사진 업로드 실패 방어 강화
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lao_trust/firebase_options.dart';
import 'expert_request_photo_upload.dart';

import '../data/firestore_schema.dart';
import 'firebase_service.dart';

const String _keyPending = 'laotrust_pending_requests';

CollectionReference<Map<String, dynamic>> expertRequestsV5Collection() {
  final appId = DefaultFirebaseOptions.currentPlatform.projectId;
  return firestore
      .collection('artifacts')
      .doc(appId)
      .collection('public')
      .doc('data')
      .collection('requests');
}

Future<void> saveExpertRequestV5OfflineFirst(Map<String, dynamic> body) async {
  final uid = auth.currentUser?.uid ?? employerIdForCurrentSession() ?? '';
  final map = Map<String, dynamic>.from(body);
  final existingUid = map['userId'] as String?;
  map['userId'] =
      (existingUid != null && existingUid.trim().isNotEmpty) ? existingUid.trim() : uid;

  if (isFirebaseEnabled) {
    final result = await Connectivity().checkConnectivity();
    final online = result.any((e) =>
        e == ConnectivityResult.mobile ||
        e == ConnectivityResult.wifi ||
        e == ConnectivityResult.ethernet);
    if (online) {
      final pending = map['_photoLocalPaths'];
      if (pending is List && pending.isNotEmpty) {
        final paths = pending.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        final uid = map['userId'] as String? ?? '';
        // 사진 업로드 실패해도 Firestore 저장은 반드시 진행
        try {
          map['photos'] = await uploadExpertRequestImagesFromLocalPaths(
            paths: paths,
            userId: uid,
          );
        } catch (e) {
          if (kDebugMode) debugPrint('[OfflineFirst] 사진 업로드 실패 → photos=[] 로 저장 진행: $e');
          map['photos'] = <String>[];
        }
        map.remove('_photoLocalPaths');
      }
      await _sendExpertV5ToFirestore(map);
      return;
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_keyPending) ?? [];
  list.add(jsonEncode({
    'version': 5,
    'payload': map,
    'at': DateTime.now().toIso8601String(),
  }));
  await prefs.setStringList(_keyPending, list);
}

Future<void> _sendExpertV5ToFirestore(Map<String, dynamic> body) async {
  final data = Map<String, dynamic>.from(body);
  data.remove('_photoLocalPaths');
  data['createdAt'] = FieldValue.serverTimestamp();
  final uuid =
      '${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(99999)}';
  await FirebaseAuth.instance.currentUser?.getIdToken(true);
  await expertRequestsV5Collection().doc(uuid).set(data);
}

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
      if (map['version'] == 5) {
        final payload = Map<String, dynamic>.from(map['payload'] as Map);
        final pending = payload['_photoLocalPaths'];
        if (pending is List && pending.isNotEmpty && isFirebaseEnabled) {
          final paths = pending.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
          final uid = (payload['userId'] as String?)?.trim() ?? '';
          // 사진 업로드 실패해도 Firestore 저장은 반드시 진행
          try {
            final urls = await uploadExpertRequestImagesFromLocalPaths(
              paths: paths,
              userId: uid,
            );
            payload['photos'] = urls;
          } catch (e) {
            if (kDebugMode) debugPrint('[Flush] 사진 업로드 실패 → photos=[] 로 저장 진행: $e');
            payload['photos'] = <String>[];
          }
          payload.remove('_photoLocalPaths');
        }
        await _sendExpertV5ToFirestore(payload);
        sent++;
      } else {
        final category = map['category'] as String;
        final payload = map['payload'] as Map<String, dynamic>;
        await _sendToFirestore(category: category, payload: payload);
        sent++;
      }
    } catch (_) {
      remaining.add(raw);
    }
  }
  await prefs.setStringList(_keyPending, remaining);
  return sent;
}
