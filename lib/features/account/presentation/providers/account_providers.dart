import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../home/data/models/user_address.dart';
import '../../data/datasources/account_remote_datasource.dart';
import '../../../ride/data/models/saved_payment_method.dart';

final accountRemoteDatasourceProvider =
    Provider<AccountRemoteDatasource>((ref) {
  return AccountRemoteDatasource(ref.read(dioProvider));
});

/// Saved places for CRUD.
final accountAddressesProvider =
    StateNotifierProvider<AccountAddressesNotifier, AccountAddressesState>(
        (ref) {
  final ds = ref.read(accountRemoteDatasourceProvider);
  return AccountAddressesNotifier(ds);
});

/// Saved payment methods.
final accountPaymentMethodsProvider = StateNotifierProvider<
    AccountPaymentMethodsNotifier, AccountPaymentMethodsState>((ref) {
  final ds = ref.read(accountRemoteDatasourceProvider);
  return AccountPaymentMethodsNotifier(ds);
});

/// Language preference.
final languageProvider = StateProvider<String>((ref) => 'en');


// ── Addresses State ──────────────────────────────────────
class AccountAddressesState {
  final List<UserAddress> addresses;
  final bool isLoading;
  final String? error;

  const AccountAddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  AccountAddressesState copyWith({
    List<UserAddress>? addresses,
    bool? isLoading,
    String? error,
  }) {
    return AccountAddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AccountAddressesNotifier extends StateNotifier<AccountAddressesState> {
  final AccountRemoteDatasource _ds;

  AccountAddressesNotifier(this._ds) : super(const AccountAddressesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 200));
      state = const AccountAddressesState(
        addresses: [
          UserAddress(
            id: 'addr-1',
            label: 'Home',
            address: '24 Luxury Towers, Sliema',
            latitude: 35.9117,
            longitude: 14.5050,
          ),
          UserAddress(
            id: 'addr-2',
            label: 'Work',
            address: 'SmartCity Malta, Kalkara',
            latitude: 35.8885,
            longitude: 14.5340,
          ),
        ],
        isLoading: false,
      );
      return;
    }

    try {
      final addresses = await _ds.getAddresses();
      state = AccountAddressesState(addresses: addresses);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addAddress(Map<String, dynamic> data) async {
    if (AppConstants.kDevBypass) {
      final newAddr = UserAddress(
        id: 'addr-${state.addresses.length + 1}',
        label: data['label'] as String? ?? 'Other',
        address: data['address'] as String? ?? '',
        latitude: data['latitude'] as double?,
        longitude: data['longitude'] as double?,
      );
      state = state.copyWith(
          addresses: [...state.addresses, newAddr]);
      return;
    }
    await _ds.addAddress(data);
    load();
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    if (AppConstants.kDevBypass) {
      state = state.copyWith(
        addresses: state.addresses.map((a) {
          if (a.id == id) {
            return UserAddress(
              id: a.id,
              label: data['label'] as String? ?? a.label,
              address: data['address'] as String? ?? a.address,
              latitude: data['latitude'] as double? ?? a.latitude,
              longitude: data['longitude'] as double? ?? a.longitude,
            );
          }
          return a;
        }).toList(),
      );
      return;
    }
    await _ds.updateAddress(id, data);
    load();
  }

  Future<void> deleteAddress(String id) async {

    if (AppConstants.kDevBypass) {
      state = state.copyWith(
          addresses: state.addresses.where((a) => a.id != id).toList());
      return;
    }
    await _ds.deleteAddress(id);
    load();
  }
}

// ── Payment Methods State ────────────────────────────────
class AccountPaymentMethodsState {
  final List<SavedPaymentMethod> methods;
  final bool isLoading;
  final String? error;

  const AccountPaymentMethodsState({
    this.methods = const [],
    this.isLoading = false,
    this.error,
  });

  AccountPaymentMethodsState copyWith({
    List<SavedPaymentMethod>? methods,
    bool? isLoading,
    String? error,
  }) {
    return AccountPaymentMethodsState(
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AccountPaymentMethodsNotifier
    extends StateNotifier<AccountPaymentMethodsState> {
  final AccountRemoteDatasource _ds;

  AccountPaymentMethodsNotifier(this._ds)
      : super(const AccountPaymentMethodsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 200));
      state = const AccountPaymentMethodsState(
        methods: [
          SavedPaymentMethod(
            id: 'pm-1',
            brand: CardBrand.visa,
            last4: '4242',
            expMonth: 12,
            expYear: 2026,
            isDefault: true,
          ),
          SavedPaymentMethod(
            id: 'pm-2',
            brand: CardBrand.mastercard,
            last4: '8888',
            expMonth: 6,
            expYear: 2027,
          ),
        ],
        isLoading: false,
      );
      return;
    }

    try {
      final methods = await _ds.getPaymentMethods();
      state = AccountPaymentMethodsState(methods: methods);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteMethod(String id) async {
    if (AppConstants.kDevBypass) {
      state = state.copyWith(
          methods: state.methods.where((m) => m.id != id).toList());
      return;
    }
    await _ds.deletePaymentMethod(id);
    load();
  }

  Future<void> confirmSetup(String paymentMethodId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _ds.confirmSetupIntent(paymentMethodId);
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
