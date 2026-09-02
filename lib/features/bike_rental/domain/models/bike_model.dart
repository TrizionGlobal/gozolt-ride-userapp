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

class BikeModel {
  final String? id;
  final String name;
  final String brand;
  final String model;
  final int manufacturingYear;
  final String type; // category
  final String registrationNumber;
  final int? engineCapacityCc;
  final double? mileage;
  final String color;
  final String? batteryCapacity;
  final String? estimatedRange;
  final String? chargingType;
  final String? chargingTime;
  
  final String supplier;
  final double? supplierLatitude;
  final double? supplierLongitude;
  final double rating;
  final String transmission;
  final String fuelType;
  final int seats;
  final List<String> features;
  final String supplierOption;
  final bool isSelfPickupAllowed;
  final bool isSupplierDeliveryAllowed;
  final bool isDoorstepDeliveryAllowed;
  final double pricePerDay;
  final double deliveryCharge;
  
  final List<String> images;
  String get imageUrl => images.isNotEmpty ? images.first : '';

  final List<ProtectionPackageModel> protectionPackages;
  final String? selectedProtectionPackageId;
  final List<MileagePackageModel> mileagePackages;
  final String? selectedMileagePackageId;
  final List<String>? selectedAddonIds;

  BikeModel({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.manufacturingYear,
    required this.type,
    required this.registrationNumber,
    this.engineCapacityCc,
    this.mileage,
    required this.color,
    this.batteryCapacity,
    this.estimatedRange,
    this.chargingType,
    this.chargingTime,
    required this.supplier,
    this.supplierLatitude,
    this.supplierLongitude,
    required this.rating,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.features,
    required this.supplierOption,
    this.isSelfPickupAllowed = true,
    this.isSupplierDeliveryAllowed = false,
    this.isDoorstepDeliveryAllowed = false,
    required this.pricePerDay,
    this.deliveryCharge = 0.0,
    this.images = const [],
    this.protectionPackages = const [],
    this.selectedProtectionPackageId,
    this.mileagePackages = const [],
    this.selectedMileagePackageId,
    this.selectedAddonIds,
  });

  BikeModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    int? manufacturingYear,
    String? type,
    String? registrationNumber,
    int? engineCapacityCc,
    double? mileage,
    String? color,
    String? batteryCapacity,
    String? estimatedRange,
    String? chargingType,
    String? chargingTime,
    String? supplier,
    double? supplierLatitude,
    double? supplierLongitude,
    double? rating,
    String? transmission,
    String? fuelType,
    int? seats,
    List<String>? features,
    String? supplierOption,
    bool? isSelfPickupAllowed,
    bool? isSupplierDeliveryAllowed,
    bool? isDoorstepDeliveryAllowed,
    double? pricePerDay,
    double? deliveryCharge,
    List<String>? images,
    List<ProtectionPackageModel>? protectionPackages,
    String? selectedProtectionPackageId,
    List<MileagePackageModel>? mileagePackages,
    String? selectedMileagePackageId,
    List<String>? selectedAddonIds,
  }) {
    return BikeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      type: type ?? this.type,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      engineCapacityCc: engineCapacityCc ?? this.engineCapacityCc,
      mileage: mileage ?? this.mileage,
      color: color ?? this.color,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      estimatedRange: estimatedRange ?? this.estimatedRange,
      chargingType: chargingType ?? this.chargingType,
      chargingTime: chargingTime ?? this.chargingTime,
      supplier: supplier ?? this.supplier,
      supplierLatitude: supplierLatitude ?? this.supplierLatitude,
      supplierLongitude: supplierLongitude ?? this.supplierLongitude,
      rating: rating ?? this.rating,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      features: features ?? this.features,
      supplierOption: supplierOption ?? this.supplierOption,
      isSelfPickupAllowed: isSelfPickupAllowed ?? this.isSelfPickupAllowed,
      isSupplierDeliveryAllowed: isSupplierDeliveryAllowed ?? this.isSupplierDeliveryAllowed,
      isDoorstepDeliveryAllowed: isDoorstepDeliveryAllowed ?? this.isDoorstepDeliveryAllowed,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      images: images ?? this.images,
      protectionPackages: protectionPackages ?? this.protectionPackages,
      selectedProtectionPackageId: selectedProtectionPackageId ?? this.selectedProtectionPackageId,
      mileagePackages: mileagePackages ?? this.mileagePackages,
      selectedMileagePackageId: selectedMileagePackageId ?? this.selectedMileagePackageId,
      selectedAddonIds: selectedAddonIds ?? this.selectedAddonIds,
    );
  }

  factory BikeModel.fromJson(Map<String, dynamic> json) {
    return BikeModel(
      id: json['id'],
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      manufacturingYear: json['manufacturingYear'] ?? 2023,
      type: json['type'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      engineCapacityCc: json['engineCapacityCc'],
      mileage: json['mileage'] != null ? (json['mileage'] as num).toDouble() : null,
      color: json['color'] ?? 'Black',
      batteryCapacity: json['batteryCapacity'],
      estimatedRange: json['estimatedRange'],
      chargingType: json['chargingType'],
      chargingTime: json['chargingTime'],
      supplier: json['supplier'] ?? '',
      supplierLatitude: json['supplierLatitude'] != null ? (json['supplierLatitude'] as num).toDouble() : null,
      supplierLongitude: json['supplierLongitude'] != null ? (json['supplierLongitude'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 4.8,
      transmission: json['transmission'] ?? '',
      fuelType: json['fuelType'] ?? '',
      seats: json['seats'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      supplierOption: json['supplierOption'] ?? '',
      isSelfPickupAllowed: json['isSelfPickupAllowed'] ?? true,
      isSupplierDeliveryAllowed: json['isSupplierDeliveryAllowed'] ?? false,
      isDoorstepDeliveryAllowed: json['isDoorstepDeliveryAllowed'] ?? false,
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      images: json['images'] != null 
          ? List<String>.from(json['images']).map<String>((url) => ApiConstants.fullUrl(url)).toList() 
          : (json['imageUrl'] != null ? [ApiConstants.fullUrl(json['imageUrl'])] : []),
      protectionPackages: (json['protectionPackages'] as List<dynamic>?)
              ?.map((e) => ProtectionPackageModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      mileagePackages: (json['mileagePackages'] as List<dynamic>?)
              ?.map((e) => MileagePackageModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

