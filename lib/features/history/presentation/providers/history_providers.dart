import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
