import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_grocery_delivery_address.dart';

final foodGroceryDeliveryProvider = StateNotifierProvider<
    FoodGroceryDeliveryNotifier, FoodGroceryDeliveryState>(
  (ref) => FoodGroceryDeliveryNotifier(),
);

class FoodGroceryDeliveryNotifier
    extends StateNotifier<FoodGroceryDeliveryState> {
  FoodGroceryDeliveryNotifier()
      : super(
          const FoodGroceryDeliveryState(
            addresses: [
              FoodGroceryDeliveryAddress(
                id: 'temporary-home-address',
                label: 'Home',
                recipientName: 'Customer Name',
                phoneNumber: '+356 9900 0000',
                addressLine: 'Triq il-Karmnu',
                locality: 'Ħal Luqa',
                city: 'Malta',
                postalCode: 'LQA 1311',
                apartmentDetails: 'Apartment 2',
                isDefault: true,
              ),
            ],
            selectedAddressId: 'temporary-home-address',
          ),
        );

  void selectAddress(String addressId) {
    final addressExists = state.addresses.any(
      (address) => address.id == addressId,
    );

    if (!addressExists) {
      return;
    }

    state = state.copyWith(
      selectedAddressId: addressId,
    );
  }

  void addAddress(FoodGroceryDeliveryAddress address) {
    final updatedAddresses = [
      ...state.addresses,
      address,
    ];

    state = state.copyWith(
      addresses: updatedAddresses,
      selectedAddressId: address.id,
    );
  }

  void updateAddress(FoodGroceryDeliveryAddress updatedAddress) {
    final updatedAddresses = state.addresses.map((address) {
      if (address.id == updatedAddress.id) {
        return updatedAddress;
      }

      return address;
    }).toList();

    state = state.copyWith(
      addresses: updatedAddresses,
    );
  }

  void removeAddress(String addressId) {
    final updatedAddresses =
        state.addresses.where((address) => address.id != addressId).toList();

    String? nextSelectedAddressId = state.selectedAddressId;

    if (state.selectedAddressId == addressId) {
      nextSelectedAddressId =
          updatedAddresses.isEmpty ? null : updatedAddresses.first.id;
    }

    state = FoodGroceryDeliveryState(
      addresses: updatedAddresses,
      selectedAddressId: nextSelectedAddressId,
      deliveryInstructions: state.deliveryInstructions,
      leaveAtDoor: state.leaveAtDoor,
    );
  }

  void updateDeliveryInstructions(String value) {
    state = state.copyWith(
      deliveryInstructions: value,
    );
  }

  void setLeaveAtDoor(bool value) {
    state = state.copyWith(
      leaveAtDoor: value,
    );
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
