// =============================================================================
// v1.3: 전문가 가용성 레이더 · Duty Toggle · Privacy Masking (잠복)
// Duty OFF 시 Firestore lat/lng 즉시 null 처리하여 리스트에서 숨김.
// 확대 수색: 5km → 15km → 전역 Elastic Search.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lao_trust/core/firebase_service.dart';
import 'package:lao_trust/core/location_service.dart';
import 'package:lao_trust/data/firestore_schema.dart';

/// 전문가 한 명의 공개 프로필 (위치 잠복 시 lat/lng null)
class ExpertProfile {
  ExpertProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.lat,
    this.lng,
    this.dutyOn = false,
    this.commanderApproved = false,
    this.partnerSerialId,
    this.categories = const [],
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final double? lat;
  final double? lng;
  final bool dutyOn;
  final bool commanderApproved;
  final String? partnerSerialId;
  final List<String> categories;

  bool get isVisible => dutyOn && lat != null && lng != null;

  LocationPoint? get location {
    if (lat == null || lng == null) return null;
    return LocationPoint(lat!, lng!);
  }

  static ExpertProfile fromMap(String uid, Map<String, dynamic> data) {
    final lat = data[UserFields.lat];
    final lng = data[UserFields.lng];
    return ExpertProfile(
      uid: uid,
      displayName: data[UserFields.displayName]?.toString() ?? 'Expert',
      photoUrl: data[UserFields.photoUrl]?.toString(),
      lat: lat is num ? lat.toDouble() : null,
      lng: lng is num ? lng.toDouble() : null,
      dutyOn: data[UserFields.dutyOn] == true,
      commanderApproved: data[UserFields.commanderApproved] == true,
      partnerSerialId: data[UserFields.partnerSerialId]?.toString(),
      categories: List<String>.from(data['categories'] ?? []),
    );
  }
}

/// 현재 사용자 UID (전문가일 때만 사용)
String? get currentUserId => auth.currentUser?.uid;

/// Expert duty toggle. When OFF, clear lat/lng immediately.
Future<void> setExpertDuty(bool on, {double? lat, double? lng}) async {
  if (!isFirebaseEnabled) return;
  final uid = currentUserId;
  if (uid == null) return;

  final ref = firestore.collection(kColUsers).doc(uid);
  if (on && lat != null && lng != null) {
    await ref.set({
      UserFields.dutyOn: true,
      UserFields.lat: lat,
      UserFields.lng: lng,
      UserFields.userType: kUserTypeExpert,
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } else {
    await ref.set({
      UserFields.dutyOn: false,
      UserFields.lat: null,
      UserFields.lng: null,
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// 현재 전문가의 duty_on 상태 조회 (대시보드 초기 표시용).
Future<bool> getExpertDutyStatus() async {
  if (!isFirebaseEnabled) return false;
  final uid = currentUserId;
  if (uid == null) return false;
  final doc = await firestore.collection(kColUsers).doc(uid).get();
  return doc.data()?[UserFields.dutyOn] == true;
}

/// 전문가 위치만 즉시 잠복(Clear). duty_on 은 유지.
Future<void> clearExpertLocation() async {
  if (!isFirebaseEnabled) return;
  final uid = currentUserId;
  if (uid == null) return;
  await firestore.collection(kColUsers).doc(uid).set({
    UserFields.lat: null,
    UserFields.lng: null,
    UserFields.updatedAt: FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

/// 확대 수색 반경 (km): 5 → 15 → 전역(9999)
const List<double> kRadiiKm = [5.0, 15.0, 9999.0];

/// 사용자 위치 기준으로 duty_on 이고 lat/lng 있는 전문가만 스냅샷.
/// radiusKm 까지 거리 필터는 클라이언트에서 수행 (Firestore 쿼리는 복잡하므로).
Stream<List<ExpertProfile>> streamExpertsNearby(LocationPoint userLocation, {double maxRadiusKm = 5.0}) {
  if (!isFirebaseEnabled) {
    return Stream.value([]);
  }
  return firestore
      .collection(kColUsers)
      .where(UserFields.userType, isEqualTo: kUserTypeExpert)
      .where(UserFields.dutyOn, isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final list = <ExpertProfile>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data[UserFields.lat] == null || data[UserFields.lng] == null) continue;
      final profile = ExpertProfile.fromMap(doc.id, data);
      if (!profile.isVisible) continue;
      final loc = profile.location!;
      final km = distanceInKm(userLocation, loc);
      if (km <= maxRadiusKm) list.add(profile);
    }
    list.sort((a, b) {
      final kmA = distanceInKm(userLocation, a.location!);
      final kmB = distanceInKm(userLocation, b.location!);
      return kmA.compareTo(kmB);
    });
    return list;
  });
}

/// 단일 스냅샷: 5km → 15km → 전역 순으로 확대 수색. 첫 번째 비어있지 않은 결과 반환.
Future<({List<ExpertProfile> experts, double usedRadiusKm})> fetchExpertsElastic(LocationPoint userLocation) async {
  for (final radiusKm in kRadiiKm) {
    final snapshot = await firestore
        .collection(kColUsers)
        .where(UserFields.userType, isEqualTo: kUserTypeExpert)
        .where(UserFields.dutyOn, isEqualTo: true)
        .get();
    final list = <ExpertProfile>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data[UserFields.lat] == null || data[UserFields.lng] == null) continue;
      final profile = ExpertProfile.fromMap(doc.id, data);
      if (!profile.isVisible) continue;
      final km = distanceInKm(userLocation, profile.location!);
      if (km <= radiusKm) list.add(profile);
    }
    list.sort((a, b) {
      final kmA = distanceInKm(userLocation, a.location!);
      final kmB = distanceInKm(userLocation, b.location!);
      return kmA.compareTo(kmB);
    });
    if (list.isNotEmpty) return (experts: list, usedRadiusKm: radiusKm);
  }
  return (experts: <ExpertProfile>[], usedRadiusKm: kRadiiKm.last);
}
