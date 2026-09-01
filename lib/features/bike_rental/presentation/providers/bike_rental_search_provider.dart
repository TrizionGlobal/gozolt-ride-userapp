import 'package:flutter_riverpod/flutter_riverpod.dart';

class BikeRentalSearchState {
  final String deliveryType;
  final String? deliveryAddress;
  final String? phone;
  final String? email;
  final String? whatsapp;
  final String? pickupLocation;
  final String? dropoffLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final DateTime? pickupDate;
  final String? pickupTime;
  final DateTime? dropoffDate;
  final String? dropoffTime;
  final bool isFlexible;

  BikeRentalSearchState({
    this.deliveryType = 'SELF_PICKUP',
    this.deliveryAddress,
    this.phone,
    this.email,
    this.whatsapp,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.pickupDate,
    this.pickupTime,
    this.dropoffDate,
    this.dropoffTime,
    this.isFlexible = false,
  });

  BikeRentalSearchState copyWith({
    String? deliveryType,
    String? deliveryAddress,
    String? phone,
    String? email,
    String? whatsapp,
    String? pickupLocation,
    String? dropoffLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    DateTime? pickupDate,
    String? pickupTime,
    DateTime? dropoffDate,
    String? dropoffTime,
    bool? isFlexible,
  }) {
    return BikeRentalSearchState(
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffDate: dropoffDate ?? this.dropoffDate,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      isFlexible: isFlexible ?? this.isFlexible,
    );
  }
}

class BikeRentalSearchNotifier extends StateNotifier<BikeRentalSearchState> {
  BikeRentalSearchNotifier() : super(BikeRentalSearchState());

  void setSearchOptions({
    required String type,
    String? address,
    String? phone,
    String? email,
    String? whatsapp,
    String? pickupLocation,
    String? dropoffLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    DateTime? pickupDate,
    String? pickupTime,
    DateTime? dropoffDate,
    String? dropoffTime,
  }) {
    state = state.copyWith(
      deliveryType: type,
      deliveryAddress: address,
      phone: phone,
      email: email,
      whatsapp: whatsapp,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      pickupDate: pickupDate,
      pickupTime: pickupTime,
      dropoffDate: dropoffDate,
      dropoffTime: dropoffTime,
    );
  }

  void updateSearch({bool? isFlexible}) {
    state = state.copyWith(isFlexible: isFlexible);
  }
}

final bikeRentalSearchProvider = StateNotifierProvider<BikeRentalSearchNotifier, BikeRentalSearchState>((ref) {
  return BikeRentalSearchNotifier();
});
