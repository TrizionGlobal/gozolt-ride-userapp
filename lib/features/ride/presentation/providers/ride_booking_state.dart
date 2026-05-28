import '../../data/models/fare_estimate.dart';
import '../../data/models/location_data.dart';
import '../../data/models/saved_payment_method.dart';
import '../../data/models/vehicle_type.dart';

enum BookingStatus {
  idle,
  estimating,
  estimated,
  booking,
  findingDriver,
  driverFound,
  scheduled,
  error,
}

class RideBookingState {
  final LocationData? pickup;
  final LocationData? dropoff;
  final List<LocationData> stops;
  final VehicleType vehicleType;
  final PaymentMethodType paymentMethodType;
  final String? selectedCardId;
  final String? promoCode;
  final double? promoDiscount;
  final String? promoDescription;
  final bool useCoins;
  final double? coinsDiscount;
  final bool isScheduled;
  final DateTime? scheduledAt;
  final FareEstimate? fareEstimate;
  final BookingStatus status;
  final String? errorMessage;
  final String? createdRideId;
  final String? createdRideOtp;
  final String? searchingMessage;

  const RideBookingState({
    this.pickup,
    this.dropoff,
    this.stops = const [],
    this.vehicleType = VehicleType.go,
    this.paymentMethodType = PaymentMethodType.cash,
    this.selectedCardId,
    this.promoCode,
    this.promoDiscount,
    this.promoDescription,
    this.useCoins = false,
    this.coinsDiscount,
    this.isScheduled = false,
    this.scheduledAt,
    this.fareEstimate,
    this.status = BookingStatus.idle,
    this.errorMessage,
    this.createdRideId,
    this.createdRideOtp,
    this.searchingMessage,
  });

  bool get hasLocations => pickup != null && dropoff != null;

  double get totalFare {
    if (fareEstimate == null) return 0;
    double total = fareEstimate!.estimatedFare;
    if (promoDiscount != null) total -= promoDiscount!;
    if (useCoins && coinsDiscount != null) total -= coinsDiscount!;
    if (total < 0) total = 0;
    return total;
  }

  RideBookingState copyWith({
    LocationData? pickup,
    LocationData? dropoff,
    List<LocationData>? stops,
    VehicleType? vehicleType,
    PaymentMethodType? paymentMethodType,
    String? selectedCardId,
    String? promoCode,
    double? promoDiscount,
    String? promoDescription,
    bool? useCoins,
    double? coinsDiscount,
    bool? isScheduled,
    DateTime? scheduledAt,
    FareEstimate? fareEstimate,
    BookingStatus? status,
    String? errorMessage,
    String? createdRideId,
    String? createdRideOtp,
    String? searchingMessage,
    bool clearPromo = false,
    bool clearSchedule = false,
    bool clearCard = false,
    bool clearError = false,
    bool clearRideId = false,
  }) {
    return RideBookingState(
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      stops: stops ?? this.stops,
      vehicleType: vehicleType ?? this.vehicleType,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      selectedCardId: clearCard ? null : (selectedCardId ?? this.selectedCardId),
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      promoDiscount: clearPromo ? null : (promoDiscount ?? this.promoDiscount),
      promoDescription: clearPromo ? null : (promoDescription ?? this.promoDescription),
      useCoins: useCoins ?? this.useCoins,
      coinsDiscount: coinsDiscount ?? this.coinsDiscount,
      isScheduled: clearSchedule ? false : (isScheduled ?? this.isScheduled),
      scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
      fareEstimate: fareEstimate ?? this.fareEstimate,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdRideId: clearRideId ? null : (createdRideId ?? this.createdRideId),
      createdRideOtp: clearRideId ? null : (createdRideOtp ?? this.createdRideOtp),
      searchingMessage: searchingMessage ?? this.searchingMessage,
    );
  }
}
