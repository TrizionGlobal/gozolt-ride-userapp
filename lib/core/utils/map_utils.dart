import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geo_utils.dart';

class MapUtils {
  /// Trim a polyline so it only shows the path from the current position onwards
    static List<LatLng> trimPolyline(List<LatLng> fullPolyline, LatLng currentPos) {
    if (fullPolyline.length < 2) return fullPolyline;

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < fullPolyline.length; i++) {
      final dist = haversineDistanceKm(
        currentPos.latitude,
        currentPos.longitude,
        fullPolyline[i].latitude,
        fullPolyline[i].longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    int indexInFront = closestIndex;
    if (closestIndex < fullPolyline.length - 1) {
      final distNext = haversineDistanceKm(
        currentPos.latitude, currentPos.longitude,
        fullPolyline[closestIndex + 1].latitude, fullPolyline[closestIndex + 1].longitude,
      );
      double distPrev = double.infinity;
      if (closestIndex > 0) {
        distPrev = haversineDistanceKm(
          currentPos.latitude, currentPos.longitude,
          fullPolyline[closestIndex - 1].latitude, fullPolyline[closestIndex - 1].longitude,
        );
      }
      
      if (distNext <= distPrev) {
        indexInFront = closestIndex + 1;
      } else {
        indexInFront = closestIndex;
      }
    }

    final remaining = fullPolyline.sublist(indexInFront);
    if (remaining.isNotEmpty && remaining.first.latitude != currentPos.latitude && remaining.first.longitude != currentPos.longitude) {
      remaining.insert(0, currentPos);
    } else if (remaining.isEmpty) {
      remaining.add(currentPos);
      remaining.add(fullPolyline.last);
    }
    return remaining;
  }

  /// Create bounds spanning a list of points
  static LatLngBounds boundsFromLocations(List<LatLng> points) {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
