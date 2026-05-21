import 'package:flutter_test/flutter_test.dart';
import 'package:gozolt_user_app/features/ride/data/models/fare_estimate.dart';

void main() {
  test('FareEstimate.fromJson parsing test', () {
    final json = {
      "baseFare": 3.5,
      "distanceFare": 1.45,
      "timeFare": 0.4,
      "bookingFee": 1,
      "surgeMultiplier": 1,
      "estimatedFare": 6.35,
      "distanceKm": 1.21,
      "durationMinutes": 2,
      "etaMinutes": 2,
      "goCoinsEarned": 10
    };

    final estimate = FareEstimate.fromJson(json);
    expect(estimate.baseFare, 3.5);
    expect(estimate.distanceFare, 1.45);
    expect(estimate.timeFare, 0.4);
    expect(estimate.bookingFee, 1.0);
    expect(estimate.surgeMultiplier, 1.0);
    expect(estimate.estimatedFare, 6.35);
    expect(estimate.distanceKm, 1.21);
    expect(estimate.durationMinutes, 2);
    expect(estimate.etaMinutes, 2);
  });
}
