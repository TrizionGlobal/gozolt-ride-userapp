import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/food_grocery_delivery_address.dart';

final foodGroceryDeliveryProvider =
    StateNotifierProvider<FoodGroceryDeliveryNotifier, FoodGroceryDeliveryState>(
  (ref) => FoodGroceryDeliveryNotifier(ref),
);

class FoodGroceryDeliveryNotifier
    extends StateNotifier<FoodGroceryDeliveryState> {
  FoodGroceryDeliveryNotifier(this._ref)
      : super(const FoodGroceryDeliveryState()) {
    Future.microtask(() => _loadAddresses());
  }

  final Ref _ref;

  Future<void> _loadAddresses() async {
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final addresses = await ds.getAddresses();
      if (!mounted) return;
      final defaultId = addresses
          .where((a) => a.isDefault)
          .map((a) => a.id)
          .firstOrNull;
      state = FoodGroceryDeliveryState(
        addresses: addresses,
        selectedAddressId: defaultId ??
            (addresses.isNotEmpty ? addresses.first.id : null),
      );
    } catch (_) {
      // Keep empty state — user can add addresses manually
    }
  }

  Future<void> refreshAddresses() => _loadAddresses();

  void selectAddress(String addressId) {
    final addressExists = state.addresses.any(
      (address) => address.id == addressId,
    );

    if (!addressExists) return;

    state = state.copyWith(selectedAddressId: addressId);
  }

  Future<bool> addAddress(FoodGroceryDeliveryAddress address) async {
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final created = await ds.createAddress(address);
      if (!mounted) return true;
      final updatedAddresses = [...state.addresses, created];
      state = state.copyWith(
        addresses: updatedAddresses,
        selectedAddressId: created.id,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAddress(FoodGroceryDeliveryAddress updatedAddress) async {
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final updated = await ds.updateAddress(updatedAddress);
      if (!mounted) return true;
      state = state.copyWith(
        addresses: state.addresses.map((a) {
          return a.id == updated.id ? updated : a;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeAddress(String addressId) async {
    final previous = state;
    final updatedAddresses =
        state.addresses.where((address) => address.id != addressId).toList();
    String? nextSelectedAddressId = state.selectedAddressId;
    if (state.selectedAddressId == addressId) {
      nextSelectedAddressId = updatedAddresses.isEmpty
          ? null
          : updatedAddresses.first.id;
    }
    state = FoodGroceryDeliveryState(
      addresses: updatedAddresses,
      selectedAddressId: nextSelectedAddressId,
      deliveryInstructions: state.deliveryInstructions,
      leaveAtDoor: state.leaveAtDoor,
    );

    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      await ds.deleteAddress(addressId);
      return true;
    } catch (_) {
      if (mounted) {
        state = previous;
      }
      return false;
    }
  }

  void updateDeliveryInstructions(String value) {
    state = state.copyWith(deliveryInstructions: value);
  }

  void setLeaveAtDoor(bool value) {
    state = state.copyWith(leaveAtDoor: value);
  }

  void resetCheckoutDeliveryDetails() {
    final defaultAddress =
        state.addresses.where((address) => address.isDefault).firstOrNull;

    state = FoodGroceryDeliveryState(
      addresses: state.addresses,
      selectedAddressId: defaultAddress?.id ??
          (state.addresses.isEmpty ? null : state.addresses.first.id),
    );
  }
}
