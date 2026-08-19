import 'package:flutter_riverpod/flutter_riverpod.dart';

class CarRentalSearchState {
  final String deliveryType;
  final String? deliveryAddress;
  final String? phone;
  final String? email;
  final String? whatsapp;
  final String? pickupLocation;
  final String? dropoffLocation;
  final DateTime? pickupDate;
  final String? pickupTime;
  final DateTime? dropoffDate;
  final String? dropoffTime;
  final bool isFlexible;

  CarRentalSearchState({
    this.deliveryType = 'SELF_PICKUP',
    this.deliveryAddress,
    this.phone,
    this.email,
    this.whatsapp,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupDate,
    this.pickupTime,
    this.dropoffDate,
    this.dropoffTime,
    this.isFlexible = false,
  });

  CarRentalSearchState copyWith({
    String? deliveryType,
    String? deliveryAddress,
    String? phone,
    String? email,
    String? whatsapp,
    String? pickupLocation,
    String? dropoffLocation,
    DateTime? pickupDate,
    String? pickupTime,
    DateTime? dropoffDate,
    String? dropoffTime,
    bool? isFlexible,
  }) {
    return CarRentalSearchState(
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffDate: dropoffDate ?? this.dropoffDate,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      isFlexible: isFlexible ?? this.isFlexible,
    );
  }
}

class CarRentalSearchNotifier extends StateNotifier<CarRentalSearchState> {
  CarRentalSearchNotifier() : super(CarRentalSearchState());

  void setSearchOptions({
    required String type,
    String? address,
    String? phone,
    String? email,
    String? whatsapp,
    String? pickupLocation,
    String? dropoffLocation,
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

final carRentalSearchProvider = StateNotifierProvider<CarRentalSearchNotifier, CarRentalSearchState>((ref) {
  return CarRentalSearchNotifier();
});
