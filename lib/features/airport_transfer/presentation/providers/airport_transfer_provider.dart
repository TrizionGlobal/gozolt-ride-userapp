import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/airport_transfer_remote_datasource.dart';
import '../../data/models/airport_transfer_draft.dart';

const List<String> kActiveAirportTransferStatuses = [
  'PENDING_PAYMENT',
  'PENDING_APPROVAL',
  'CONFIRMED',
  'DRIVER_ASSIGNED',
  'EN_ROUTE_TO_PICKUP',
  'ARRIVED_AT_AIRPORT',
  'PASSENGER_MET',
  'IN_TRANSIT',
];

/// Checks whether an airport transfer booking is still active/uncompleted.
/// For ONE_WAY: active unless status is COMPLETED, CANCELLED, or REFUNDED.
/// For ROUND_TRIP: active if EITHER outbound OR return trip is not completed/cancelled/refunded.
bool isAirportTransferBookingActive(Map<String, dynamic>? booking) {
  if (booking == null) return false;
  final status = booking['status']?.toString().toUpperCase() ?? '';
  final returnStatus = booking['returnStatus']?.toString().toUpperCase() ?? '';
  final paymentStatus =
      booking['paymentStatus']?.toString().toUpperCase() ?? '';
  final paymentMethod =
      booking['paymentMethod']?.toString().toUpperCase() ?? '';
  final isRoundTrip =
      booking['transferType']?.toString().toUpperCase() == 'ROUND_TRIP';

  // An abandoned online booking that was never paid does not block the user
  if (paymentStatus == 'PENDING' &&
      (paymentMethod == 'ONLINE' || status == 'PENDING_PAYMENT')) {
    return false;
  }

  const terminalStatuses = ['COMPLETED', 'CANCELLED', 'REFUNDED'];

  final isOutboundActive = !terminalStatuses.contains(status);
  final isReturnActive =
      isRoundTrip && !terminalStatuses.contains(returnStatus);

  return isOutboundActive || isReturnActive;
}

final airportTransferDraftProvider =
    StateNotifierProvider<AirportTransferDraftNotifier, AirportTransferDraft>(
        (ref) {
  return AirportTransferDraftNotifier();
});

class AirportTransferDraftNotifier extends StateNotifier<AirportTransferDraft> {
  AirportTransferDraftNotifier() : super(const AirportTransferDraft());

  void update(AirportTransferDraft draft) {
    state = draft;
  }

  void reset() {
    state = const AirportTransferDraft();
  }
}

final activeAirportTransferProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final datasource = ref.watch(airportTransferRemoteDatasourceProvider);
    final myBookings = await datasource.getMyBookings(limit: 20);
    final active = myBookings.cast<Map<String, dynamic>?>().firstWhere(
      (b) => isAirportTransferBookingActive(b),
      orElse: () => null,
    );
    return active;
  } catch (e) {
    return null;
  }
});

