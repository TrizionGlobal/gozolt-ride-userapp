import 'ride_stop.dart';

class CreateRideRequest {
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String vehicleType;
  final String? paymentMethod;
  final String? paymentMethodId;
  final List<RideStop>? stops;
  final bool isScheduled;
  final String? scheduledAt;
  final String? promoCode;
  final double? walletAmountUsed;

  const CreateRideRequest({
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.vehicleType,
    this.paymentMethod,
    this.paymentMethodId,
    this.stops,
    this.isScheduled = false,
    this.scheduledAt,
    this.promoCode,
    this.walletAmountUsed,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffAddress': dropoffAddress,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'vehicleType': vehicleType,
    };
    if (paymentMethod != null) map['paymentMethod'] = paymentMethod;
    if (paymentMethodId != null) map['paymentMethodId'] = paymentMethodId;
    if (stops != null && stops!.isNotEmpty) {
      map['stops'] = stops!.map((s) => s.toJson()).toList();
    }
    if (isScheduled) {
      map['isScheduled'] = true;
      if (scheduledAt != null) map['scheduledAt'] = scheduledAt;
    }
    if (promoCode != null) map['promoCode'] = promoCode;
    if (walletAmountUsed != null) map['walletAmountUsed'] = walletAmountUsed;
    return map;
  }
}
