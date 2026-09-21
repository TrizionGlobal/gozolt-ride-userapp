import '../../../../core/config/quick_services_pricing_config.dart';
import 'package:flutter/material.dart';
import '../../../ride/data/models/location_data.dart';
import '../../../ride/data/models/saved_payment_method.dart';

class ServiceAddon {
  final String name;
  final int count;
  final double? pricePerUnit;
  final double? hoursPerUnit;
  final bool isFixedPrice;

  const ServiceAddon({
    required this.name,
    required this.count,
    this.pricePerUnit,
    this.hoursPerUnit,
    this.isFixedPrice = false,
  });

  double get totalHours => (hoursPerUnit ?? 0.0) * count;
  double get totalPrice => (pricePerUnit ?? 0.0) * count;

  ServiceAddon copyWith({
    String? name,
    int? count,
    double? pricePerUnit,
    double? hoursPerUnit,
    bool? isFixedPrice,
  }) {
    return ServiceAddon(
      name: name ?? this.name,
      count: count ?? this.count,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      hoursPerUnit: hoursPerUnit ?? this.hoursPerUnit,
      isFixedPrice: isFixedPrice ?? this.isFixedPrice,
    );
  }
}

class MechanicVehicle {
  final String type;
  final String make;
  final String model;
  final String? year;
  final String? registration;
  final String? mileage;
  final String issue;

  const MechanicVehicle({
    required this.type,
    required this.make,
    required this.model,
    this.year,
    this.registration,
    this.mileage,
    required this.issue,
  });

  MechanicVehicle copyWith({
    String? type,
    String? make,
    String? model,
    String? year,
    String? registration,
    String? mileage,
    String? issue,
  }) {
    return MechanicVehicle(
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      registration: registration ?? this.registration,
      mileage: mileage ?? this.mileage,
      issue: issue ?? this.issue,
    );
  }
}


class CarWashVehicle {
  final String type;
  final String make;
  final String model;
  final String washPackage;
  final double washPackagePrice;
  final String condition;

  const CarWashVehicle({
    required this.type,
    required this.make,
    required this.model,
    required this.washPackage,
    required this.washPackagePrice,
    required this.condition,
  });

  CarWashVehicle copyWith({
    String? type,
    String? make,
    String? model,
    String? washPackage,
    double? washPackagePrice,
    String? condition,
  }) {
    return CarWashVehicle(
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      washPackage: washPackage ?? this.washPackage,
      washPackagePrice: washPackagePrice ?? this.washPackagePrice,
      condition: condition ?? this.condition,
    );
  }
}

class MobileDevice {
  final String deviceType;
  final String deviceBrand;
  final String deviceModel;
  final String? operatingSystem;
  final String issue;

  const MobileDevice({
    required this.deviceType,
    required this.deviceBrand,
    required this.deviceModel,
    this.operatingSystem,
    required this.issue,
  });

  MobileDevice copyWith({
    String? deviceType,
    String? deviceBrand,
    String? deviceModel,
    String? operatingSystem,
    String? issue,
  }) {
    return MobileDevice(
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      issue: issue ?? this.issue,
    );
  }
}

class ComputerDevice {
  final String deviceType;
  final String brand;
  final String model;
  final String? operatingSystem;
  final String issue;

  const ComputerDevice({
    required this.deviceType,
    required this.brand,
    required this.model,
    this.operatingSystem,
    required this.issue,
  });

  ComputerDevice copyWith({
    String? deviceType,
    String? brand,
    String? model,
    String? operatingSystem,
    String? issue,
  }) {
    return ComputerDevice(
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      issue: issue ?? this.issue,
    );
  }
}

class PrinterDevice {
  final String deviceType;
  final String brand;
  final String model;
  final String? serialNumber;
  final List<String> issues;

  const PrinterDevice({
    required this.deviceType,
    required this.brand,
    required this.model,
    this.serialNumber,
    required this.issues,
  });

  PrinterDevice copyWith({
    String? deviceType,
    String? brand,
    String? model,
    String? serialNumber,
    List<String>? issues,
  }) {
    return PrinterDevice(
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      issues: issues ?? this.issues,
    );
  }
}

class QuickServiceBookingData {
  final String category;
  final String selectedService;
  final DateTime scheduleDate;
  final TimeOfDay scheduleTime;
  final LocationData location;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String? selectedServiceTitle;
  final List<ServiceAddon> selectedAddons;
  final String? materialPreference;
  final double subtotal;
  final double baseEstimatedHours;
  final double minHourlyRate;
  final double? maxHourlyRate;
  final String? whatYouNeed;
  final String? describeIssue;
  final List<String>? uploadedImages;

  // Vehicle Mechanic specific fields
  final String? bikeType;
  final String? carType;
  final String? truckType;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? vehicleRegistration;
  final String? mileage;
  final String? vehicleIssue;
  final List<MechanicVehicle>? mechanicVehicles;
  final String? taskCategory;
  final String? projectScope;

  // Pest Control specific fields
  final String? pestType;
  final List<String>? pestAffectedAreas;
  final int? pestAffectedRooms;
  final String? pestObservedLevel;
  final String? childrenOrPets;

  // Lift / Elevator Mechanic specific fields
  final String? propertyType;
  final String? liftType;
  final String? floorsServed;

  // Handyman specific fields
  final String? wallType;

  // Hire a Person specific fields
  final String? expectedDuration;
  final String? comments;
  final int? helperCount;

  // Security Personnel specific fields
  final String? securityService;
  final String? venueType;
  final String? dutyStartTime;
  final String? dutyEndTime;
  final int? personnelCount;
  final String? expectedAttendance;
  final String? serviceArea;

  final PaymentMethodType paymentMethodType;
  final String? paymentMethodId;
  final bool useGoCoins;
  final String? dressPreference;
  final String? alcoholServed;

  // Mobile Repair specific fields
  final String? deviceType;
  final String? deviceBrand;
  final String? deviceModel;
  final String? operatingSystem;
  final String? mobileIssue;
  final int? deviceCount;
  final List<MobileDevice>? mobileDevices;

  // Computer Repair specific fields
  final String? computerDeviceType;
  final String? computerBrand;
  final String? computerModel;
  final String? computerOS;
  final String? computerIssue;
  final List<ComputerDevice>? computerDevices;

  // Printer & Scanner specific fields
  final String? printerDeviceType;
  final String? printerBrand;
  final String? printerModel;
  final String? printerSerialNumber;
  final String? printerConnectionMethod;
  final List<String>? printerIssues;
  final int? printerDeviceCount;
  final String? printerErrorCode;
  final List<PrinterDevice>? printerDevices;

  // Car Wash specific fields
  final String? carWashPackage;
  final double? carWashPackagePrice;
  final String? vehicleColour;
  final String? vehicleCondition;
  final String? waterAccess;
  final String? electricityAccess;
  final int? vehicleCount;
  final List<CarWashVehicle>? carWashVehicles;
  final String? vehicleServiceMode;
  final double? pickupAndReturnFee;


  // Laundry & Ironing specific fields
  final String? laundryServiceMethod;
  final String? laundryServiceType;
  final double? laundryPackagePrice;
  final int? laundryQuantityKg;
  final int? specialCareShirtCount;
  final int? specialCareDressCount;
  final int? specialCareTrouserCount;
  final int? specialCareBeddingCount;
  final String? detergentArrangement;
  final String? customLaundryService;

  // Commercial/Hospital Laundry specific fields
  final String? facilityName;
  final String? collectionPoint;
  final String? facilityContactPerson;
  final String? facilityContactNumber;
  final List<String>? commercialLaundryTypes;
  final int? numberOfBags;
  final String? linenHandlingType;
  final String? serviceFrequency;
  final String? businessType;
  final DateTime? requestedReturnDate;
  final TimeOfDay? requestedReturnTime;
  final String? collectionInstructions;

  // Beauty & Wellness specific fields
  final List<String>? beautySelectedTreatments;
  final double? beautyTreatmentsSubtotal;
  final int? peopleCount;
  final String? professionalPreference;
  final String? customBeautyService;

  // Gardening specific fields
  final String? gardeningServices;
  final String? gardeningServiceArea;
  final String? gardeningApproximateArea;
  final String? greenWasteRemoval;

  // Painter specific fields
  final String? paintingType;
  final int? roomCount;
  final bool? paintProvided;
  final List<String>? paintingAreas;

  // Event Organisers specific fields
  final String? eventType;
  final int? guestCount;
  final String? eventDuration;

  // Suppliers specific fields
  final String? supplyCategory;
  final String? itemRequired;
  final int? supplyQuantity;
  final String? supplyUnit;
  final String? requestType;
  final String? requirementDescription;

  String get servicePricingKey {
    if (category == 'Vehicle Wash') {
      if (selectedServiceTitle?.contains('Bike') == true) return 'bike_wash';
      if (selectedServiceTitle?.contains('Truck') == true) return 'truck_wash';
      return 'car_wash';
    }
    if (category == 'Vehicle Mechanic') {
       if (selectedServiceTitle?.contains('Bike') == true) return 'bike_mechanic';
       if (selectedServiceTitle?.contains('Truck') == true) return 'truck_mechanic';
       return 'car_mechanic';
    }
    if (category == 'Electrical Repair') {
       if (selectedServiceTitle?.contains('Commercial') == true || selectedServiceTitle?.contains('Lift') == true) return 'lift_elevator_mechanic';
       if (selectedServiceTitle?.contains('Events') == true) return 'events_electric';
       return 'home_electric';
    }
    if (category == 'PC & Mobile Repair' || category == 'PC & Mobile') {
       if (selectedServiceTitle?.contains('Printer') == true) return 'printer_scanner';
       if (selectedServiceTitle?.contains('Mobile') == true) return 'mobile_repair';
       return 'computer_repair';
    }
    return category.toLowerCase().replaceAll(' ', '_');
  }

  String get expertVisitName {
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('mechanic')) {
      return 'Mechanic Visit/hr';
    } else if (lowerCat.contains('electric')) {
      if (selectedServiceTitle?.contains('Commercial') == true || selectedServiceTitle?.contains('Lift') == true || selectedServiceTitle?.contains('Events') == true) {
        return 'Mechanic Visit/hr';
      }
      return 'Expert Visit/hr';
    } else if (lowerCat.contains('engineer') || 
               lowerCat.contains('computer') ||
               lowerCat.contains('printer') ||
               lowerCat.contains('mobile') ||
               lowerCat.contains('technician')) {
      return 'Engineering Visit/hr';
    } else if (lowerCat.contains('wash')) {
      return 'Service Agent Visit/hr';
    }
    return 'Expert Visit/hr';
  }

  double get materialCost =>
      (materialPreference == 'Bring materials' || materialPreference == 'Bring tools') ? QuickServicesPricingConfig.getMaterialCost(servicePricingKey) : 0.0;

  double get totalEstimatedHours {
    double addonHours = 0.0;
    for (var addon in selectedAddons) {
      addonHours += addon.totalHours;
    }
    return baseEstimatedHours + addonHours;
  }

  double get fixedAddonCosts {
    double total = 0.0;
    for (var addon in selectedAddons) {
      if (addon.isFixedPrice) {
        total += addon.totalPrice;
      }
    }
    return total;
  }

  bool get hasRateRange =>
      maxHourlyRate != null && maxHourlyRate! > minHourlyRate;

  double get upfrontBookingFee => QuickServicesPricingConfig.getUpfrontFee(servicePricingKey);

  double get estimatedTotalMin =>
      (totalEstimatedHours * minHourlyRate) +
      fixedAddonCosts +
      materialCost +
      (pickupAndReturnFee ?? 0.0) +
      subtotal;

  double get estimatedTotalMax => (maxHourlyRate != null)
      ? ((totalEstimatedHours * maxHourlyRate!) +
          fixedAddonCosts +
          materialCost +
          (pickupAndReturnFee ?? 0.0) +
          subtotal)
      : estimatedTotalMin;

  const QuickServiceBookingData({
    this.category = '',
    this.paymentMethodType = PaymentMethodType.cash,
    this.paymentMethodId,
    this.useGoCoins = false,
    this.selectedService = '',
    required this.scheduleDate,
    required this.scheduleTime,
    required this.location,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.selectedServiceTitle,
    this.selectedAddons = const [],
    this.materialPreference,
    this.subtotal = 0.0,
    this.baseEstimatedHours = QuickServicesPricingConfig.defaultBaseHours,
    this.minHourlyRate = QuickServicesPricingConfig.defaultHourlyRate,
    this.maxHourlyRate,
    this.whatYouNeed,
    this.describeIssue,
    this.uploadedImages,
    this.bikeType,
    this.carType,
    this.truckType,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleRegistration,
    this.mileage,
    this.vehicleIssue,
    this.mechanicVehicles,
    this.taskCategory,
    this.projectScope,
    this.pestType,
    this.pestAffectedAreas,
    this.pestAffectedRooms,
    this.pestObservedLevel,
    this.childrenOrPets,
    this.propertyType,
    this.liftType,
    this.floorsServed,
    this.wallType,
    this.expectedDuration,
    this.comments,
    this.helperCount,
    this.securityService,
    this.venueType,
    this.dutyStartTime,
    this.dutyEndTime,
    this.personnelCount,
    this.expectedAttendance,
    this.serviceArea,
    this.dressPreference,
    this.alcoholServed,
    this.deviceType,
    this.deviceBrand,
    this.deviceModel,
    this.operatingSystem,
    this.mobileIssue,
    this.deviceCount,
    this.mobileDevices,
    this.computerDeviceType,
    this.computerBrand,
    this.computerModel,
    this.computerOS,
    this.computerIssue,
    this.computerDevices,
    this.printerDeviceType,
    this.printerBrand,
    this.printerModel,
    this.printerSerialNumber,
    this.printerConnectionMethod,
    this.printerIssues,
    this.printerDeviceCount,
    this.printerErrorCode,
    this.printerDevices,
    this.carWashPackage,
    this.carWashPackagePrice,
    this.vehicleColour,
    this.vehicleCondition,
    this.waterAccess,
    this.electricityAccess,
    this.vehicleCount,
    this.carWashVehicles,
    this.vehicleServiceMode = 'On-Site',
    this.pickupAndReturnFee,
    this.laundryServiceMethod,
    this.laundryServiceType,
    this.laundryPackagePrice,
    this.laundryQuantityKg,
    this.specialCareShirtCount,
    this.specialCareDressCount,
    this.specialCareTrouserCount,
    this.specialCareBeddingCount,
    this.detergentArrangement,
    this.customLaundryService,
    this.facilityName,
    this.collectionPoint,
    this.facilityContactPerson,
    this.facilityContactNumber,
    this.commercialLaundryTypes,
    this.numberOfBags,
    this.linenHandlingType,
    this.serviceFrequency,
    this.businessType,
    this.requestedReturnDate,
    this.requestedReturnTime,
    this.collectionInstructions,
    this.beautySelectedTreatments,
    this.beautyTreatmentsSubtotal,
    this.peopleCount,
    this.professionalPreference,
    this.customBeautyService,
    this.gardeningServices,
    this.gardeningServiceArea,
    this.gardeningApproximateArea,
    this.greenWasteRemoval,
    this.paintingType,
    this.roomCount,
    this.paintProvided,
    this.paintingAreas,
    this.eventType,
    this.guestCount,
    this.eventDuration,
    this.supplyCategory,
    this.itemRequired,
    this.supplyQuantity,
    this.supplyUnit,
    this.requestType,
    this.requirementDescription,
  });

  QuickServiceBookingData copyWith({
    String? category,
    String? selectedService,
    DateTime? scheduleDate,
    TimeOfDay? scheduleTime,
    LocationData? location,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? selectedServiceTitle,
    List<ServiceAddon>? selectedAddons,
    String? materialPreference,
    double? subtotal,
    double? baseEstimatedHours,
    double? minHourlyRate,
    double? maxHourlyRate,
    String? whatYouNeed,
    String? describeIssue,
    List<String>? uploadedImages,
    String? bikeType,
    String? carType,
    String? truckType,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleYear,
    String? vehicleRegistration,
    String? mileage,
    String? vehicleIssue,
    List<MechanicVehicle>? mechanicVehicles,
    String? taskCategory,
    String? projectScope,
    String? pestType,
    List<String>? pestAffectedAreas,
    int? pestAffectedRooms,
    String? pestObservedLevel,
    String? childrenOrPets,
    String? propertyType,
    String? liftType,
    String? floorsServed,
    String? wallType,
    String? expectedDuration,
    String? comments,
    int? helperCount,
    String? securityService,
    String? venueType,
    String? dutyStartTime,
    String? dutyEndTime,
    int? personnelCount,
    String? expectedAttendance,
    String? serviceArea,
    PaymentMethodType? paymentMethodType,
    String? paymentMethodId,
    bool? useGoCoins,
    String? dressPreference,
    String? alcoholServed,
    String? deviceType,
    String? deviceBrand,
    String? deviceModel,
    String? operatingSystem,
    String? mobileIssue,
    int? deviceCount,
    List<MobileDevice>? mobileDevices,
    String? computerDeviceType,
    String? computerBrand,
    String? computerModel,
    String? computerOS,
    String? computerIssue,
    List<ComputerDevice>? computerDevices,
    String? printerDeviceType,
    String? printerBrand,
    String? printerModel,
    String? printerSerialNumber,
    String? printerConnectionMethod,
    List<String>? printerIssues,
    int? printerDeviceCount,
    String? printerErrorCode,
    List<PrinterDevice>? printerDevices,
    String? vehicleServiceMode,
    double? pickupAndReturnFee,
    String? carWashPackage,
    double? carWashPackagePrice,
    String? vehicleColour,
    String? vehicleCondition,
    String? waterAccess,
    String? electricityAccess,
    int? vehicleCount,
    List<CarWashVehicle>? carWashVehicles,
    String? laundryServiceMethod,
    String? laundryServiceType,
    double? laundryPackagePrice,
    int? laundryQuantityKg,
    int? specialCareShirtCount,
    int? specialCareDressCount,
    int? specialCareTrouserCount,
    int? specialCareBeddingCount,
    String? detergentArrangement,
    String? customLaundryService,
    String? facilityName,
    String? collectionPoint,
    String? facilityContactPerson,
    String? facilityContactNumber,
    List<String>? commercialLaundryTypes,
    int? numberOfBags,
    String? linenHandlingType,
    String? serviceFrequency,
    String? businessType,
    DateTime? requestedReturnDate,
    TimeOfDay? requestedReturnTime,
    String? collectionInstructions,
    List<String>? beautySelectedTreatments,
    double? beautyTreatmentsSubtotal,
    int? peopleCount,
    String? professionalPreference,
    String? customBeautyService,
    String? gardeningServices,
    String? gardeningServiceArea,
    String? gardeningApproximateArea,
    String? greenWasteRemoval,
    String? paintingType,
    int? roomCount,
    bool? paintProvided,
    List<String>? paintingAreas,
    String? eventType,
    int? guestCount,
    String? eventDuration,
    String? supplyCategory,
    String? itemRequired,
    int? supplyQuantity,
    String? supplyUnit,
    String? requestType,
    String? requirementDescription,
  }) {
    return QuickServiceBookingData(
      category: category ?? this.category,
      selectedService: selectedService ?? this.selectedService,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      location: location ?? this.location,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      selectedServiceTitle: selectedServiceTitle ?? this.selectedServiceTitle,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      materialPreference: materialPreference ?? this.materialPreference,
      subtotal: subtotal ?? this.subtotal,
      baseEstimatedHours: baseEstimatedHours ?? this.baseEstimatedHours,
      minHourlyRate: minHourlyRate ?? QuickServicesPricingConfig.getMinRate(this.servicePricingKey),
      maxHourlyRate: maxHourlyRate ?? QuickServicesPricingConfig.getMaxRate(this.servicePricingKey),
      whatYouNeed: whatYouNeed ?? this.whatYouNeed,
      describeIssue: describeIssue ?? this.describeIssue,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      bikeType: bikeType ?? this.bikeType,
      carType: carType ?? this.carType,
      truckType: truckType ?? this.truckType,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      mileage: mileage ?? this.mileage,
      vehicleIssue: vehicleIssue ?? this.vehicleIssue,
      mechanicVehicles: mechanicVehicles ?? this.mechanicVehicles,
      taskCategory: taskCategory ?? this.taskCategory,
      projectScope: projectScope ?? this.projectScope,
      pestType: pestType ?? this.pestType,
      pestAffectedAreas: pestAffectedAreas ?? this.pestAffectedAreas,
      pestAffectedRooms: pestAffectedRooms ?? this.pestAffectedRooms,
      pestObservedLevel: pestObservedLevel ?? this.pestObservedLevel,
      childrenOrPets: childrenOrPets ?? this.childrenOrPets,
      propertyType: propertyType ?? this.propertyType,
      liftType: liftType ?? this.liftType,
      floorsServed: floorsServed ?? this.floorsServed,
      wallType: wallType ?? this.wallType,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      comments: comments ?? this.comments,
      helperCount: helperCount ?? this.helperCount,
      securityService: securityService ?? this.securityService,
      venueType: venueType ?? this.venueType,
      dutyStartTime: dutyStartTime ?? this.dutyStartTime,
      dutyEndTime: dutyEndTime ?? this.dutyEndTime,
      personnelCount: personnelCount ?? this.personnelCount,
      expectedAttendance: expectedAttendance ?? this.expectedAttendance,
      serviceArea: serviceArea ?? this.serviceArea,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      useGoCoins: useGoCoins ?? this.useGoCoins,
      dressPreference: dressPreference ?? this.dressPreference,
      alcoholServed: alcoholServed ?? this.alcoholServed,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      mobileIssue: mobileIssue ?? this.mobileIssue,
      deviceCount: deviceCount ?? this.deviceCount,
      mobileDevices: mobileDevices ?? this.mobileDevices,
      computerDeviceType: computerDeviceType ?? this.computerDeviceType,
      computerBrand: computerBrand ?? this.computerBrand,
      computerModel: computerModel ?? this.computerModel,
      computerOS: computerOS ?? this.computerOS,
      computerIssue: computerIssue ?? this.computerIssue,
      computerDevices: computerDevices ?? this.computerDevices,
      printerDeviceType: printerDeviceType ?? this.printerDeviceType,
      printerBrand: printerBrand ?? this.printerBrand,
      printerModel: printerModel ?? this.printerModel,
      printerSerialNumber: printerSerialNumber ?? this.printerSerialNumber,
      printerConnectionMethod:
          printerConnectionMethod ?? this.printerConnectionMethod,
      printerIssues: printerIssues ?? this.printerIssues,
      printerDeviceCount: printerDeviceCount ?? this.printerDeviceCount,
      printerErrorCode: printerErrorCode ?? this.printerErrorCode,
      printerDevices: printerDevices ?? this.printerDevices,
      vehicleServiceMode: vehicleServiceMode ?? this.vehicleServiceMode,
      pickupAndReturnFee: pickupAndReturnFee ?? this.pickupAndReturnFee,
      carWashPackage: carWashPackage ?? this.carWashPackage,
      carWashPackagePrice: carWashPackagePrice ?? this.carWashPackagePrice,
      vehicleColour: vehicleColour ?? this.vehicleColour,
      vehicleCondition: vehicleCondition ?? this.vehicleCondition,
      waterAccess: waterAccess ?? this.waterAccess,
      electricityAccess: electricityAccess ?? this.electricityAccess,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      carWashVehicles: carWashVehicles ?? this.carWashVehicles,
      laundryServiceMethod: laundryServiceMethod ?? this.laundryServiceMethod,
      laundryServiceType: laundryServiceType ?? this.laundryServiceType,
      laundryPackagePrice: laundryPackagePrice ?? this.laundryPackagePrice,
      laundryQuantityKg: laundryQuantityKg ?? this.laundryQuantityKg,
      specialCareShirtCount:
          specialCareShirtCount ?? this.specialCareShirtCount,
      specialCareDressCount:
          specialCareDressCount ?? this.specialCareDressCount,
      specialCareTrouserCount:
          specialCareTrouserCount ?? this.specialCareTrouserCount,
      specialCareBeddingCount:
          specialCareBeddingCount ?? this.specialCareBeddingCount,
      detergentArrangement: detergentArrangement ?? this.detergentArrangement,
      customLaundryService: customLaundryService ?? this.customLaundryService,
      facilityName: facilityName ?? this.facilityName,
      collectionPoint: collectionPoint ?? this.collectionPoint,
      facilityContactPerson:
          facilityContactPerson ?? this.facilityContactPerson,
      facilityContactNumber:
          facilityContactNumber ?? this.facilityContactNumber,
      commercialLaundryTypes:
          commercialLaundryTypes ?? this.commercialLaundryTypes,
      numberOfBags: numberOfBags ?? this.numberOfBags,
      linenHandlingType: linenHandlingType ?? this.linenHandlingType,
      serviceFrequency: serviceFrequency ?? this.serviceFrequency,
      businessType: businessType ?? this.businessType,
      requestedReturnDate: requestedReturnDate ?? this.requestedReturnDate,
      requestedReturnTime: requestedReturnTime ?? this.requestedReturnTime,
      collectionInstructions:
          collectionInstructions ?? this.collectionInstructions,
      beautySelectedTreatments:
          beautySelectedTreatments ?? this.beautySelectedTreatments,
      beautyTreatmentsSubtotal:
          beautyTreatmentsSubtotal ?? this.beautyTreatmentsSubtotal,
      peopleCount: peopleCount ?? this.peopleCount,
      professionalPreference:
          professionalPreference ?? this.professionalPreference,
      customBeautyService: customBeautyService ?? this.customBeautyService,
      gardeningServices: gardeningServices ?? this.gardeningServices,
      gardeningServiceArea: gardeningServiceArea ?? this.gardeningServiceArea,
      gardeningApproximateArea:
          gardeningApproximateArea ?? this.gardeningApproximateArea,
      greenWasteRemoval: greenWasteRemoval ?? this.greenWasteRemoval,
      paintingType: paintingType ?? this.paintingType,
      roomCount: roomCount ?? this.roomCount,
      paintProvided: paintProvided ?? this.paintProvided,
      paintingAreas: paintingAreas ?? this.paintingAreas,
      eventType: eventType ?? this.eventType,
      guestCount: guestCount ?? this.guestCount,
      eventDuration: eventDuration ?? this.eventDuration,
      supplyCategory: supplyCategory ?? this.supplyCategory,
      itemRequired: itemRequired ?? this.itemRequired,
      supplyQuantity: supplyQuantity ?? this.supplyQuantity,
      supplyUnit: supplyUnit ?? this.supplyUnit,
      requestType: requestType ?? this.requestType,
      requirementDescription:
          requirementDescription ?? this.requirementDescription,
    );
  }
}
