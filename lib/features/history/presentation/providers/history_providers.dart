import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/datasources/history_remote_datasource.dart';
import '../../data/models/ride_history_item.dart';

final historyRemoteDatasourceProvider =
    Provider<HistoryRemoteDatasource>((ref) {
  return HistoryRemoteDatasource(ref.read(dioProvider));
});

/// Filter for the history tab: null = All
final rideHistoryFilterProvider = StateProvider<String?>((ref) => null);

/// Paginated ride history.
final rideHistoryProvider =
    StateNotifierProvider<RideHistoryNotifier, RideHistoryState>((ref) {
  final ds = ref.read(historyRemoteDatasourceProvider);
  final filter = ref.watch(rideHistoryFilterProvider);
  return RideHistoryNotifier(ds, filter);
});

/// Selected ride for detail view.
final selectedRideDetailProvider =
    FutureProvider.family<RideHistoryItem, String>((ref, rideId) async {
  if (AppConstants.kDevBypass) {
    final history = ref.read(rideHistoryProvider);
    final match = history.rides.where((r) => r.id == rideId);
    if (match.isNotEmpty) return match.first;
    return _mockRides.firstWhere((r) => r.id == rideId,
        orElse: () => _mockRides.first);
  }
  final ds = ref.read(historyRemoteDatasourceProvider);
  return ds.getRideDetail(rideId);
});

class RideHistoryState {
  final List<RideHistoryItem> rides;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const RideHistoryState({
    this.rides = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  RideHistoryState copyWith({
    List<RideHistoryItem>? rides,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return RideHistoryState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

class RideHistoryNotifier extends StateNotifier<RideHistoryState> {
  final HistoryRemoteDatasource _ds;
  final String? _filter;

  RideHistoryNotifier(this._ds, this._filter)
      : super(const RideHistoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 300));
      final filtered = _filter == null
          ? _mockRides
          : _mockRides.where((r) => r.status == _filter).toList();
      state = RideHistoryState(
        rides: filtered,
        isLoading: false,
        hasMore: false,
        page: 1,
      );
      return;
    }

    try {
      final rides = await _ds.getRideHistory(status: _filter, page: 1);
      state = RideHistoryState(
        rides: rides,
        isLoading: false,
        hasMore: rides.length >= 10,
        page: 1,
      );
    } catch (e) {
      // For new users or API errors, show empty list instead of error
      if (kDebugMode) print('[RideHistory] load error: $e');
      state = RideHistoryState(
        rides: const [],
        isLoading: false,
        hasMore: false,
        page: 1,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final rides =
          await _ds.getRideHistory(status: _filter, page: nextPage);
      state = state.copyWith(
        rides: [...state.rides, ...rides],
        isLoading: false,
        hasMore: rides.length >= 10,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelScheduledRide(String rideId) async {
    if (AppConstants.kDevBypass) {
      state = state.copyWith(
        rides: state.rides.where((r) => r.id != rideId).toList(),
      );
      return;
    }

    try {
      await _ds.cancelRide(rideId, 'User cancelled scheduled ride');
      
      // Update local state immediately for "Rapido-like" feel
      if (_filter == 'SCHEDULED') {
        // If we are looking at scheduled rides, just remove it
        state = state.copyWith(
          rides: state.rides.where((r) => r.id != rideId).toList(),
        );
      } else {
        // If we are looking at all rides, update status to CANCELLED
        state = state.copyWith(
          rides: state.rides.map<RideHistoryItem>((r) {
            if (r.id == rideId) {
              return r.copyWith(status: 'CANCELLED');
            }
            return r;
          }).toList(),

        );
      }
    } catch (e) {
      if (kDebugMode) print('[RideHistory] cancelScheduledRide error: $e');
      // Refresh list to ensure consistency if API call failed but we want to be sure
      load();
    }
  }

  Future<void> rescheduleRide(String rideId, DateTime newTime) async {
    if (AppConstants.kDevBypass) {
      state = state.copyWith(
        rides: state.rides.map<RideHistoryItem>((r) {
          if (r.id == rideId) {
            return r.copyWith(
              isScheduled: true,
              scheduledAt: newTime.toUtc().toIso8601String(),
            );
          }
          return r;
        }).toList(),

      );
      return;
    }

    try {
      await _ds.rescheduleRide(rideId, newTime);
      
      // Update local state immediately
      state = state.copyWith(
        rides: state.rides.map<RideHistoryItem>((r) {
          if (r.id == rideId) {
            return r.copyWith(
              scheduledAt: newTime.toUtc().toIso8601String(),
            );
          }
          return r;
        }).toList(),

      );
    } catch (e) {
      if (kDebugMode) print('[RideHistory] rescheduleRide error: $e');
      load();
    }
  }

}

// ── Dev mock data ─────────────────────────────────────────────
final _mockRides = [
  RideHistoryItem(
    id: 'ride-001',
    status: 'COMPLETED',
    pickupAddress: '24 Luxury Towers, Sliema',
    dropoffAddress: 'Valletta Bus Station, Valletta',
    pickupLat: 35.9117,
    pickupLng: 14.5050,
    dropoffLat: 35.8978,
    dropoffLng: 14.5148,
    vehicleType: 'STANDARD',
    estimatedFare: 12.50,
    actualFare: 11.80,
    paymentMethod: 'visa',
    createdAt: '2025-05-20T14:30:00Z',
    driverName: 'Marco Borg',
    driverRating: 4.8,
    driverVehicle: 'Toyota Camry',
    driverPlate: 'GZL 001',
    distanceKm: 5.2,
    durationMinutes: 14,
    rating: 5,
    goCoinsEarned: 5,
  ),
  RideHistoryItem(
    id: 'ride-002',
    status: 'COMPLETED',
    pickupAddress: 'Malta International Airport',
    dropoffAddress: 'Hilton Malta, Portomaso',
    pickupLat: 35.8575,
    pickupLng: 14.4775,
    dropoffLat: 35.9228,
    dropoffLng: 14.4932,
    vehicleType: 'PREMIUM',
    estimatedFare: 25.00,
    actualFare: 23.50,
    paymentMethod: 'mastercard',
    createdAt: '2025-05-18T09:15:00Z',
    driverName: 'Josef Camilleri',
    driverRating: 4.9,
    driverVehicle: 'Mercedes E-Class',
    driverPlate: 'GZL 042',
    distanceKm: 12.8,
    durationMinutes: 22,
    rating: 5,
    goCoinsEarned: 10,
  ),
  RideHistoryItem(
    id: 'ride-003',
    status: 'CANCELLED',
    pickupAddress: 'University of Malta, Msida',
    dropoffAddress: 'Bugibba Square, Bugibba',
    pickupLat: 35.9036,
    pickupLng: 14.4847,
    dropoffLat: 35.9505,
    dropoffLng: 14.4152,
    vehicleType: 'STANDARD',
    estimatedFare: 15.00,
    paymentMethod: 'cash',
    createdAt: '2025-05-17T18:45:00Z',
    cancelReason: 'Driver asked me to cancel',
  ),
  RideHistoryItem(
    id: 'ride-004',
    status: 'SCHEDULED',
    pickupAddress: '24 Luxury Towers, Sliema',
    dropoffAddress: 'Malta International Airport',
    pickupLat: 35.9117,
    pickupLng: 14.5050,
    dropoffLat: 35.8575,
    dropoffLng: 14.4775,
    vehicleType: 'PREMIUM',
    estimatedFare: 22.00,
    paymentMethod: 'visa',
    createdAt: '2025-05-22T06:00:00Z',
    isScheduled: true,
    scheduledAt: '2025-05-25T06:00:00Z',
  ),
  RideHistoryItem(
    id: 'ride-005',
    status: 'COMPLETED',
    pickupAddress: 'Spinola Bay, St. Julians',
    dropoffAddress: 'The Point Shopping Mall, Sliema',
    pickupLat: 35.9190,
    pickupLng: 14.4886,
    dropoffLat: 35.9098,
    dropoffLng: 14.5045,
    vehicleType: 'STANDARD',
    estimatedFare: 8.00,
    actualFare: 7.50,
    paymentMethod: 'visa',
    createdAt: '2025-05-15T12:00:00Z',
    driverName: 'Anna Vella',
    driverRating: 4.7,
    driverVehicle: 'Hyundai Ioniq',
    driverPlate: 'GZL 018',
    distanceKm: 3.1,
    durationMinutes: 8,
    rating: 4,
    goCoinsEarned: 3,
  ),
  RideHistoryItem(
    id: 'ride-006',
    status: 'COMPLETED',
    pickupAddress: 'Mdina Gate, Mdina',
    dropoffAddress: 'Golden Bay Beach',
    pickupLat: 35.8855,
    pickupLng: 14.4033,
    dropoffLat: 35.9341,
    dropoffLng: 14.3472,
    vehicleType: 'XL',
    estimatedFare: 18.00,
    actualFare: 19.20,
    paymentMethod: 'mastercard',
    createdAt: '2025-05-12T16:30:00Z',
    driverName: 'David Grech',
    driverRating: 4.6,
    driverVehicle: 'VW Transporter',
    driverPlate: 'GZL 077',
    distanceKm: 8.4,
    durationMinutes: 18,
    goCoinsEarned: 8,
  ),
];
