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
  if (AppConstants.kDevBypass) {
    return const [
      SavedPaymentMethod(
        id: 'card-1',
        brand: CardBrand.visa,
        last4: '4345',
        expMonth: 12,
        expYear: 2026,
        isDefault: true,
      ),
      SavedPaymentMethod(
        id: 'card-2',
        brand: CardBrand.mastercard,
        last4: '5567',
        expMonth: 6,
        expYear: 2027,
      ),
    ];
  }
  final ds = ref.read(paymentRemoteDatasourceProvider);
  return ds.getPaymentMethods();
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
  if (AppConstants.kDevBypass) {
    await Future.delayed(const Duration(milliseconds: 500));
    if (params.code.toUpperCase() == 'GOZOLTSUPERAPP26') {
      return PromoValidation(
        isValid: true,
        code: 'GOZOLTSUPERAPP26',
        description: '10% off on 1 ride',
        discountPercent: 10,
        maxDiscount: 25.0,
        discountAmount: (params.fare * 0.1).clamp(0, 25.0),
        validUntil: '2026-03-01',
      );
    }
    return const PromoValidation(
      isValid: false,
      errorMessage: 'Invalid coupon code',
    );
  }
  final ds = ref.read(rideRemoteDatasourceProvider);
  return ds.validatePromo(code: params.code, rideFare: params.fare);
});

// ── User Rewards (for GoCoins) ──────────────────────────

final userRewardsPointsProvider = FutureProvider.autoDispose<int>((ref) async {
  if (AppConstants.kDevBypass) return 60;
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
