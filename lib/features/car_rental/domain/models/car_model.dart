import 'dart:convert';
import '../../../../core/constants/api_constants.dart';

class ProtectionPackageModel {
  final String id;
  final String title;
  final int stars;
  final String deductibleText;
  final String? deductibleColorHex;
  final double pricePerDay;
  final double? originalPricePerDay;
  final String? discountText;
  final String valueIdentifier;
  final Map<String, dynamic> features;

  ProtectionPackageModel({
    required this.id,
    required this.title,
    required this.stars,
    required this.deductibleText,
    this.deductibleColorHex,
    required this.pricePerDay,
    this.originalPricePerDay,
    this.discountText,
    required this.valueIdentifier,
    required this.features,
  });

  factory ProtectionPackageModel.fromJson(Map<String, dynamic> json) {
    return ProtectionPackageModel(
      id: json['id'],
      title: json['title'] ?? '',
      stars: json['stars'] ?? 1,
      deductibleText: json['deductibleText'] ?? '',
      deductibleColorHex: json['deductibleColorHex'],
      pricePerDay: (json['pricePerDay'] ?? 0.0).toDouble(),
      originalPricePerDay: json['originalPricePerDay'] != null ? (json['originalPricePerDay']).toDouble() : null,
      discountText: json['discountText'],
      valueIdentifier: json['valueIdentifier'] ?? 'basic',
      features: json['features'] ?? {},
    );
  }
}

class AddonModel {
  final String id;
  final String name;
  final double pricePerDay;
  final String iconIdentifier;

  AddonModel({
    required this.id,
    required this.name,
    required this.pricePerDay,
    required this.iconIdentifier,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      id: json['id'],
      name: json['name'] ?? '',
      pricePerDay: (json['pricePerDay'] ?? 0.0).toDouble(),
      iconIdentifier: json['iconIdentifier'] ?? '',
    );
  }
}

class MileagePackageModel {
  final String id;
  final String type; // 'LIMITED', 'UNLIMITED', 'PREMIUM_UNLIMITED'
  final double pricePerDay;
  final int? includedKm;
  final double? extraKmCharge;

  MileagePackageModel({
    required this.id,
    required this.type,
    required this.pricePerDay,
    this.includedKm,
    this.extraKmCharge,
  });

  factory MileagePackageModel.fromJson(Map<String, dynamic> json) {
    return MileagePackageModel(
      id: json['id'],
      type: json['type'] ?? 'UNLIMITED',
      pricePerDay: (json['pricePerDay'] ?? 0.0).toDouble(),
      includedKm: json['includedKm'],
      extraKmCharge: json['extraKmCharge'] != null ? (json['extraKmCharge']).toDouble() : null,
    );
  }
}

class CarModel {
  final String? id;
  final String name;
  final String type;
  final String supplier;
  final double? supplierLatitude;
  final double? supplierLongitude;
  final double rating;
  final String transmission;
  final String fuelType;
  final int seats;
  final int luggageCapacity;
  final List<String> features;
  final String supplierOption;
  final bool isSelfPickupAllowed;
  final bool isSupplierDeliveryAllowed;
  final bool isDoorstepDeliveryAllowed;
  final double pricePerDay;
  final double deliveryCharge;
  final String imageUrl;
  final List<String> images;
  final List<ProtectionPackageModel> protectionPackages;
  final String? selectedProtectionPackageId;
  final List<MileagePackageModel> mileagePackages;
  final String? selectedMileagePackageId;
  final List<AddonModel> addons;
  final List<String>? selectedAddonIds;

  CarModel({
    this.id,
    required this.name,
    required this.type,
    required this.supplier,
    this.supplierLatitude,
    this.supplierLongitude,
    required this.rating,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.luggageCapacity,
    required this.features,
    required this.supplierOption,
    this.isSelfPickupAllowed = true,
    this.isSupplierDeliveryAllowed = false,
    this.isDoorstepDeliveryAllowed = false,
    required this.pricePerDay,
    this.deliveryCharge = 0.0,
    required this.imageUrl,
    this.images = const [],
    this.protectionPackages = const [],
    this.selectedProtectionPackageId,
    this.mileagePackages = const [],
    this.selectedMileagePackageId,
    this.addons = const [],
    this.selectedAddonIds,
  });

  CarModel copyWith({
    String? id,
    String? name,
    String? type,
    String? supplier,
    double? supplierLatitude,
    double? supplierLongitude,
    double? rating,
    String? transmission,
    String? fuelType,
    int? seats,
    int? luggageCapacity,
    List<String>? features,
    String? supplierOption,
    bool? isSelfPickupAllowed,
    bool? isSupplierDeliveryAllowed,
    bool? isDoorstepDeliveryAllowed,
    double? pricePerDay,
    double? deliveryCharge,
    String? imageUrl,
    List<String>? images,
    List<ProtectionPackageModel>? protectionPackages,
    String? selectedProtectionPackageId,
    List<MileagePackageModel>? mileagePackages,
    String? selectedMileagePackageId,
    List<AddonModel>? addons,
    List<String>? selectedAddonIds,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      supplier: supplier ?? this.supplier,
      supplierLatitude: supplierLatitude ?? this.supplierLatitude,
      supplierLongitude: supplierLongitude ?? this.supplierLongitude,
      rating: rating ?? this.rating,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      luggageCapacity: luggageCapacity ?? this.luggageCapacity,
      features: features ?? this.features,
      supplierOption: supplierOption ?? this.supplierOption,
      isSelfPickupAllowed: isSelfPickupAllowed ?? this.isSelfPickupAllowed,
      isSupplierDeliveryAllowed: isSupplierDeliveryAllowed ?? this.isSupplierDeliveryAllowed,
      isDoorstepDeliveryAllowed: isDoorstepDeliveryAllowed ?? this.isDoorstepDeliveryAllowed,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      protectionPackages: protectionPackages ?? this.protectionPackages,
      selectedProtectionPackageId: selectedProtectionPackageId ?? this.selectedProtectionPackageId,
      mileagePackages: mileagePackages ?? this.mileagePackages,
      selectedMileagePackageId: selectedMileagePackageId ?? this.selectedMileagePackageId,
      addons: addons ?? this.addons,
      selectedAddonIds: selectedAddonIds ?? this.selectedAddonIds,
    );
  }

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      supplier: json['supplier'] ?? '',
      supplierLatitude: json['supplierLatitude'] != null ? (json['supplierLatitude'] as num).toDouble() : null,
      supplierLongitude: json['supplierLongitude'] != null ? (json['supplierLongitude'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 4.8,
      transmission: json['transmission'] ?? '',
      fuelType: json['fuelType'] ?? '',
      seats: json['seats'] ?? 0,
      luggageCapacity: json['luggageCapacity'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      supplierOption: json['supplierOption'] ?? '',
      isSelfPickupAllowed: json['isSelfPickupAllowed'] ?? true,
      isSupplierDeliveryAllowed: json['isSupplierDeliveryAllowed'] ?? false,
      isDoorstepDeliveryAllowed: json['isDoorstepDeliveryAllowed'] ?? false,
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] != null ? ApiConstants.fullUrl(json['imageUrl']) : '',
      images: json['images'] != null ? List<String>.from(json['images']).map<String>((url) => ApiConstants.fullUrl(url)).toList() : [],
      protectionPackages: (json['protectionPackages'] as List<dynamic>?)
              ?.map((e) => ProtectionPackageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mileagePackages: (json['mileagePackages'] as List<dynamic>?)
              ?.map((e) => MileagePackageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      addons: (json['addons'] as List<dynamic>?)
              ?.map((e) => AddonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

