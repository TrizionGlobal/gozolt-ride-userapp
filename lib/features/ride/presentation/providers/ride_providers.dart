import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/models/location_data.dart';
import '../../data/models/promo_validation.dart';
import '../../data/models/saved_payment_method.dart';
import 'ride_booking_provider.dart';
import 'ride_booking_state.dart';

// ── Datasource Providers ────────────────────────────────

final paymentRemoteDatasourceProvider = Provider<PaymentRemoteDatasource>((ref) {
  return PaymentRemoteDatasource(ref.read(dioProvider));
});

// ── Main Booking State ──────────────────────────────────

final rideBookingProvider =
    StateNotifierProvider<RideBookingNotifier, RideBookingState>((ref) {
  return RideBookingNotifier(ref);
});

// ── Payment Methods ─────────────────────────────────────

final paymentMethodsProvider =
    FutureProvider<List<SavedPaymentMethod>>((ref) async {
  
  final ds = ref.read(paymentRemoteDatasourceProvider);
  return ds.getPaymentMethods();
});

/// Returns the default saved card, or null if user has no saved cards.
final defaultPaymentMethodProvider =
    FutureProvider<SavedPaymentMethod?>((ref) async {
  final methods = await ref.watch(paymentMethodsProvider.future);
  if (methods.isEmpty) return null;
  // Prefer the card marked as default; otherwise take the first one.
  return methods.firstWhere(
    (m) => m.isDefault,
    orElse: () => methods.first,
  );
});

// ── Recent Searches ─────────────────────────────────────

const _recentSearchesKey = 'gozolt_recent_searches';
const _maxRecentSearches = 5;

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<LocationData>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<LocationData>> {
  RecentSearchesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentSearchesKey) ?? [];
    state = raw.map((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return LocationData.fromJson(map);
    }).toList();
  }

  Future<void> add(LocationData location) async {
    final existing =
        state.where((l) => l.address != location.address).toList();
    final updated = [location, ...existing].take(_maxRecentSearches).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchesKey,
      updated.map((l) => jsonEncode(l.toJson())).toList(),
    );
  }
}

// ── Promo Validation ────────────────────────────────────

final promoValidationProvider =
    FutureProvider.family<PromoValidation, ({String code, double fare})>(
        (ref, params) async {
  
  final ds = ref.read(rideRemoteDatasourceProvider);
  return ds.validatePromo(code: params.code, rideFare: params.fare);
});

// ── User Rewards (for GoCoins) ──────────────────────────

final userRewardsPointsProvider = FutureProvider.autoDispose<int>((ref) async {
    try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/users/me/rewards');
    final data = response.data as Map<String, dynamic>;
    return (data['currentPoints'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});

// ── Schedule mode (from home screen) ────────────────────

final isScheduleModeProvider = StateProvider<bool>((ref) => false);
