import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

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
      state = state.copyWith(
        addresses: addresses,
        selectedAddressId: defaultId ??
            (addresses.isNotEmpty ? addresses.first.id : state.selectedAddressId),
        isUsingCurrentLocation: defaultId == null && addresses.isEmpty,
      );

      // If user has no saved addresses, automatically request GPS location
      if (addresses.isEmpty && state.currentLocationAddress == null) {
        await requestCurrentLocation();
      }
    } catch (_) {
      // Keep state — user can add addresses or use current location
    }
  }

  Future<void> refreshAddresses() => _loadAddresses();

  /// Requests device GPS location and reverse-geocodes it to a readable locality.
  Future<FoodGroceryDeliveryAddress?> requestCurrentLocation({
    bool forceSet = false,
  }) async {
    state = state.copyWith(isLoadingLocation: true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLoadingLocation: false);
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      String locality = 'Current Location';
      String street = 'Current Location';
      String city = 'Malta';
      String postalCode = '';

      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          locality = p.locality?.isNotEmpty == true
              ? p.locality!
              : (p.subLocality?.isNotEmpty == true
                  ? p.subLocality!
                  : (p.administrativeArea ?? 'Malta'));
          street = p.street?.isNotEmpty == true
              ? p.street!
              : (p.name ?? locality);
          city = p.locality?.isNotEmpty == true
              ? p.locality!
              : (p.subAdministrativeArea ?? 'Malta');
          postalCode = p.postalCode ?? '';
        }
      } catch (_) {
        // Fallback to coordinates label if reverse-geocoding fails/offline
      }

      final currentAddress = FoodGroceryDeliveryAddress(
        id: 'current_location',
        label: 'Current Location',
        recipientName: 'You',
        phoneNumber: '',
        addressLine: street,
        locality: locality,
        city: city,
        postalCode: postalCode,
        latitude: position.latitude,
        longitude: position.longitude,
        isDefault: false,
      );

      final shouldSelect = forceSet || state.selectedAddressId == null;
      state = state.copyWith(
        currentLocationAddress: currentAddress,
        isUsingCurrentLocation: shouldSelect,
        selectedAddressId:
            shouldSelect ? 'current_location' : state.selectedAddressId,
        isLoadingLocation: false,
      );

      return currentAddress;
    } catch (_) {
      state = state.copyWith(isLoadingLocation: false);
      return null;
    }
  }

  void selectCurrentLocation() {
    if (state.currentLocationAddress != null) {
      state = state.copyWith(
        isUsingCurrentLocation: true,
        selectedAddressId: 'current_location',
      );
    } else {
      requestCurrentLocation(forceSet: true);
    }
  }

  void selectAddress(String addressId) {
    if (addressId == 'current_location') {
      selectCurrentLocation();
      return;
    }

    final addressExists = state.addresses.any(
      (address) => address.id == addressId,
    );

    if (!addressExists) return;

    state = state.copyWith(
      selectedAddressId: addressId,
      isUsingCurrentLocation: false,
    );
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
        isUsingCurrentLocation: false,
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
