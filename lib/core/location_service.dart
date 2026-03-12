import 'package:geolocator/geolocator.dart';

/// 단순 위도/경도 포인트.
class LocationPoint {
  final double latitude;
  final double longitude;
  const LocationPoint(this.latitude, this.longitude);
}

/// 비엔티안 시청 좌표 (권한 거부 시 기본값).
const LocationPoint kVientianeCityHall =
    LocationPoint(17.9748, 102.6308);

/// 현재 위치를 가져오되, 권한 거부/오류 시 비엔티안 시청 좌표를 반환한다.
/// 반환 값: (위치, 기본좌표사용여부)
Future<(LocationPoint, bool)> getUserLocationOrDefault() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (kVientianeCityHall, true);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return (kVientianeCityHall, true);
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return (
      LocationPoint(position.latitude, position.longitude),
      false,
    );
  } catch (_) {
    return (kVientianeCityHall, true);
  }
}

/// 두 지점 사이의 거리를 km 단위로 반환한다.
double distanceInKm(LocationPoint from, LocationPoint to) {
  final meters = Geolocator.distanceBetween(
    from.latitude,
    from.longitude,
    to.latitude,
    to.longitude,
  );
  return meters / 1000.0;
}

