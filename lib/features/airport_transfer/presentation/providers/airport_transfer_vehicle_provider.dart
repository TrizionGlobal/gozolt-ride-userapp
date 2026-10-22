import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/airport_transfer_vehicle.dart';
import '../../data/datasources/airport_transfer_remote_datasource.dart';
import 'airport_transfer_provider.dart';

final airportTransferVehiclesProvider =
    FutureProvider.autoDispose<List<AirportTransferVehicle>>((ref) async {
  final searchDraft = ref.watch(airportTransferDraftProvider);
  final datasource = ref.watch(airportTransferRemoteDatasourceProvider);

  try {
    final liveVehicles = await datasource.getAvailableVehicles(
      passengers: searchDraft.totalPassengers > 0 ? searchDraft.totalPassengers : null,
      luggage: searchDraft.totalLuggage > 0 ? searchDraft.totalLuggage : null,
      pickupLat: searchDraft.pickupLocation?.latitude,
      pickupLng: searchDraft.pickupLocation?.longitude,
      dropoffLat: searchDraft.dropoffLocation?.latitude,
      dropoffLng: searchDraft.dropoffLocation?.longitude,
      transferType: searchDraft.isRoundTrip ? 'ROUND_TRIP' : 'ONE_WAY',
    );
    return liveVehicles;
  } catch (e) {
    debugPrint('Failed to fetch airport transfer vehicles from backend: $e');
    return <AirportTransferVehicle>[];
  }
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
