import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/airport_transfer_vehicle.dart';
import 'airport_transfer_provider.dart';

final airportTransferVehiclesProvider =
    FutureProvider.autoDispose<List<AirportTransferVehicle>>((ref) async {
  final searchDraft = ref.watch(airportTransferDraftProvider);

  // Temporary loading delay. This will later be replaced by the API call.
  await Future<void>.delayed(
    const Duration(milliseconds: 600),
  );

  const vehicles = <AirportTransferVehicle>[
    AirportTransferVehicle(
      id: 'transfer-go-1',
      name: 'Toyota Corolla',
      type: 'Go - 5P',
      supplierName: 'GOZOLT Transfer Partner',
      supplierRating: 4.8,
      passengerCapacity: 5,
      luggageCapacity: 3,
      fixedPrice: 24,
      currency: '€',
      imageUrl: '',
      estimatedDurationMinutes: 25,
      features: [
        'Air Conditioning',
        'Meet & Greet',
      ],
      isBestValue: true,
    ),
    AirportTransferVehicle(
      id: 'transfer-premium-1',
      name: 'Mercedes-Benz E-Class',
      type: 'Premium - 5P',
      supplierName: 'Malta Executive Transfer',
      supplierRating: 4.9,
      passengerCapacity: 5,
      luggageCapacity: 3,
      fixedPrice: 35,
      currency: '€',
      imageUrl: '',
      estimatedDurationMinutes: 25,
      features: [
        'Air Conditioning',
        'Meet & Greet',
        'Free Waiting Time',
      ],
      isRecommended: true,
    ),
    AirportTransferVehicle(
      id: 'transfer-suv-1',
      name: 'Premium SUV',
      type: 'SUV - 7P',
      supplierName: 'Island Transfer Services',
      supplierRating: 4.7,
      passengerCapacity: 7,
      luggageCapacity: 5,
      fixedPrice: 42,
      currency: '€',
      imageUrl: '',
      estimatedDurationMinutes: 25,
      features: ['Air Conditioning', 'Child Seat Available', 'Meet & Greet'],
    ),
    AirportTransferVehicle(
      id: 'transfer-mini-van-1',
      name: 'Mercedes Vito',
      type: 'Mini Van - 8P & Above',
      supplierName: 'Malta Group Transfers',
      supplierRating: 4.9,
      passengerCapacity: 8,
      luggageCapacity: 7,
      fixedPrice: 48,
      currency: '€',
      imageUrl: '',
      estimatedDurationMinutes: 28,
      features: [
        'Air Conditioning',
        'Meet & Greet',
        'Child Seat Available',
      ],
    ),
    AirportTransferVehicle(
      id: 'transfer-van-1',
      name: 'Mercedes Sprinter',
      type: 'Van - 8P & Above',
      supplierName: 'Malta Group Transfers',
      supplierRating: 4.8,
      passengerCapacity: 15,
      luggageCapacity: 12,
      fixedPrice: 72,
      currency: '€',
      imageUrl: '',
      estimatedDurationMinutes: 30,
      features: [
        'Air Conditioning',
        'Meet & Greet',
        'Wheelchair Accessible',
      ],
    ),
    AirportTransferVehicle(
      id: 'transfer-electric-1',
      name: 'Tesla Model Y',
      type: 'Electric - 5P',
      supplierName: 'Eco Malta Transfers',
      supplierRating: 4.8,
      passengerCapacity: 5,
      luggageCapacity: 3,
      fixedPrice: 38,
      currency: '€',
      imageUrl: '',
      estimatedDurationMinutes: 25,
      features: [
        'Electric',
        'Air Conditioning',
        'Meet & Greet',
      ],
    ),
  ];

  return vehicles.where((vehicle) {
    if (!vehicle.isActive) return false;

    if (vehicle.passengerCapacity < searchDraft.totalPassengers) {
      return false;
    }

    if (vehicle.luggageCapacity < searchDraft.totalLuggage) {
      return false;
    }

    return true;
  }).toList();
});

final selectedAirportTransferVehicleProvider = StateNotifierProvider<
    SelectedAirportTransferVehicleNotifier, AirportTransferVehicle?>((ref) {
  return SelectedAirportTransferVehicleNotifier();
});

class SelectedAirportTransferVehicleNotifier
    extends StateNotifier<AirportTransferVehicle?> {
  SelectedAirportTransferVehicleNotifier() : super(null);

  void select(AirportTransferVehicle vehicle) {
    state = vehicle;
  }

  void clear() {
    state = null;
  }
}
