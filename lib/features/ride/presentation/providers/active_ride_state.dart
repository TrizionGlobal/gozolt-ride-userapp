import '../../data/models/driver_info.dart';
import '../../data/models/driver_location.dart';
import '../../data/models/ride.dart';

enum ActiveRideStatus {
  scheduled,
  driverEnRoute,
  driverArrived,
  inProgress,
  completed,
  cancelled,
}

class ActiveRideState {
  final Ride? ride;
  final DriverInfo? driverInfo;
  final DriverLocation? driverLocation;
  final ActiveRideStatus status;
  final String? otpPin;
  final int? etaMinutes;
  final String? shareTrackingUrl;
  final String? cancelReason;
  final bool isLoading;
  final String? errorMessage;
  final bool isPaymentLoading;
  final bool isPaid;

  // Fare breakdown
  final double? baseFare;
  final double? distanceFare;
  final double? timeFare;
  final double? bookingFee;
  final double? surgeMultiplier;

  // Destination change
  final bool isDestinationChangePending;
  final String? pendingNewDropoffAddress;
  final double? pendingNewDropoffLat;
  final double? pendingNewDropoffLng;
  final double? pendingNewFare;

  const ActiveRideState({
    this.ride,
    this.driverInfo,
    this.driverLocation,
    this.status = ActiveRideStatus.driverEnRoute,
    this.otpPin,
    this.etaMinutes,
    this.shareTrackingUrl,
    this.cancelReason,
    this.isLoading = false,
    this.errorMessage,
    this.baseFare,
    this.distanceFare,
    this.timeFare,
    this.bookingFee,
    this.surgeMultiplier,
    this.isDestinationChangePending = false,
    this.pendingNewDropoffAddress,
    this.pendingNewDropoffLat,
     this.pendingNewDropoffLng,
    this.pendingNewFare,
    this.isPaymentLoading = false,
    this.isPaid = false,
  });

  bool get hasDriver => driverInfo != null;
  bool get isCompleted => status == ActiveRideStatus.completed;
  bool get isCancelled => status == ActiveRideStatus.cancelled;

  ActiveRideState copyWith({
    Ride? ride,
    DriverInfo? driverInfo,
    DriverLocation? driverLocation,
    ActiveRideStatus? status,
    String? otpPin,
    int? etaMinutes,
    String? shareTrackingUrl,
    String? cancelReason,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearOtp = false,
    double? baseFare,
    double? distanceFare,
    double? timeFare,
    double? bookingFee,
    double? surgeMultiplier,
    bool? isDestinationChangePending,
    String? pendingNewDropoffAddress,
    double? pendingNewDropoffLat,
    double? pendingNewDropoffLng,
    double? pendingNewFare,
    bool clearPendingDestination = false,
    bool? isPaymentLoading,
    bool? isPaid,
  }) {
    return ActiveRideState(
      ride: ride ?? this.ride,
      driverInfo: driverInfo ?? this.driverInfo,
      driverLocation: driverLocation ?? this.driverLocation,
      status: status ?? this.status,
      otpPin: clearOtp ? null : (otpPin ?? this.otpPin),
      etaMinutes: etaMinutes ?? this.etaMinutes,
      shareTrackingUrl: shareTrackingUrl ?? this.shareTrackingUrl,
      cancelReason: cancelReason ?? this.cancelReason,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      baseFare: baseFare ?? this.baseFare,
      distanceFare: distanceFare ?? this.distanceFare,
      timeFare: timeFare ?? this.timeFare,
      bookingFee: bookingFee ?? this.bookingFee,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      isDestinationChangePending: clearPendingDestination
          ? false
          : (isDestinationChangePending ?? this.isDestinationChangePending),
      pendingNewDropoffAddress: clearPendingDestination
          ? null
          : (pendingNewDropoffAddress ?? this.pendingNewDropoffAddress),
      pendingNewDropoffLat: clearPendingDestination
          ? null
          : (pendingNewDropoffLat ?? this.pendingNewDropoffLat),
      pendingNewDropoffLng: clearPendingDestination
          ? null
          : (pendingNewDropoffLng ?? this.pendingNewDropoffLng),
      pendingNewFare: clearPendingDestination
          ? null
          : (pendingNewFare ?? this.pendingNewFare),
      isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
