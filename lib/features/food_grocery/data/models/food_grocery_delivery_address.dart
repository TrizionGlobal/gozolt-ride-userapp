class FoodGroceryDeliveryAddress {
  const FoodGroceryDeliveryAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine,
    required this.locality,
    required this.city,
    required this.postalCode,
    this.apartmentDetails,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String addressLine;
  final String locality;
  final String city;
  final String postalCode;
  final String? apartmentDetails;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  String get fullAddress {
    final parts = <String>[
      if (apartmentDetails != null && apartmentDetails!.trim().isNotEmpty)
        apartmentDetails!.trim(),
      addressLine.trim(),
      locality.trim(),
      city.trim(),
      postalCode.trim(),
    ];

    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  FoodGroceryDeliveryAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? addressLine,
    String? locality,
    String? city,
    String? postalCode,
    String? apartmentDetails,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return FoodGroceryDeliveryAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine: addressLine ?? this.addressLine,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      apartmentDetails: apartmentDetails ?? this.apartmentDetails,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class FoodGroceryDeliveryState {
  const FoodGroceryDeliveryState({
    this.addresses = const [],
    this.selectedAddressId,
    this.deliveryInstructions = '',
    this.leaveAtDoor = false,
  });

  final List<FoodGroceryDeliveryAddress> addresses;
  final String? selectedAddressId;
  final String deliveryInstructions;
  final bool leaveAtDoor;

  FoodGroceryDeliveryAddress? get selectedAddress {
    if (selectedAddressId == null) {
      return null;
    }

    for (final address in addresses) {
      if (address.id == selectedAddressId) {
        return address;
      }
    }

    return null;
  }

  bool get canContinue => selectedAddress != null;

  FoodGroceryDeliveryState copyWith({
    List<FoodGroceryDeliveryAddress>? addresses,
    String? selectedAddressId,
    String? deliveryInstructions,
    bool? leaveAtDoor,
  }) {
    return FoodGroceryDeliveryState(
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      leaveAtDoor: leaveAtDoor ?? this.leaveAtDoor,
    );
  }
}
