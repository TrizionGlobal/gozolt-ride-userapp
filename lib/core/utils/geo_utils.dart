import 'dart:math';

/// Haversine formula to calculate distance between two GPS coordinates.
/// Returns distance in kilometers.
double haversineDistanceKm(
  double lat1, double lng1,
  double lat2, double lng2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Estimate travel time in minutes based on distance and average speed.
/// Default speed: 30 km/h (urban driving).
int estimateMinutes(double distanceKm, {double avgSpeedKmh = 30.0}) {
  if (distanceKm <= 0) return 1;
  final minutes = (distanceKm / avgSpeedKmh * 60).ceil();
  return minutes < 1 ? 1 : minutes;
}

double _toRadians(double degrees) => degrees * pi / 180;
