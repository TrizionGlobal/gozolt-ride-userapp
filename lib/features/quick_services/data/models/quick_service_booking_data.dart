import 'package:flutter/material.dart';
import '../../../ride/data/models/location_data.dart';

class ServiceAddon {
  final String name;
  final int count;
  final double pricePerUnit;

  const ServiceAddon({
    required this.name,
    required this.count,
    required this.pricePerUnit,
  });

  double get totalPrice => count * pricePerUnit;

  ServiceAddon copyWith({
    String? name,
    int? count,
    double? pricePerUnit,
  }) {
    return ServiceAddon(
      name: name ?? this.name,
      count: count ?? this.count,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }
}

class QuickServiceBookingData {
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
  final String? dressPreference;
  final String? alcoholServed;

  // Mobile Repair specific fields
  final String? deviceType;
  final String? deviceBrand;
  final String? deviceModel;
  final String? operatingSystem;
  final String? mobileIssue;
  final int? deviceCount;

  // Computer Repair specific fields
  final String? computerDeviceType;
  final String? computerBrand;
  final String? computerModel;
  final String? computerOS;
  final String? computerIssue;

  // Printer & Scanner specific fields
  final String? printerDeviceType;
  final String? printerBrand;
  final String? printerModel;
  final String? printerSerialNumber;
  final String? printerConnectionMethod;
  final List<String>? printerIssues;
  final int? printerDeviceCount;
  final String? printerErrorCode;

  // Car Wash specific fields
  final String? carWashPackage;
  final double? carWashPackagePrice;
  final String? vehicleColour;
  final String? vehicleCondition;
  final String? waterAccess;
  final String? electricityAccess;
  final int? vehicleCount;

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

  // Beauty & Wellness specific fields
  final List<String>? beautySelectedTreatments;
  final double? beautyTreatmentsSubtotal;
  final int? peopleCount;
  final String? professionalPreference;
  final String? customBeautyService;

  // Gardening specific fields
  final String? gardeningServiceArea;
  final String? gardeningApproximateArea;
  final String? greenWasteRemoval;

  // Painter specific fields
  final String? paintingType;
  final int? roomCount;
  final bool? paintProvided;

  // Event Organisers specific fields
  final String? eventType;
  final int? guestCount;
  final String? eventDuration;

  // Suppliers specific fields
  final String? supplyType;
  final String? supplyScale;

  double get materialCost => (materialPreference == 'Bring materials') ? 5.0 : 0.0;
  double get estimatedTotal => subtotal + materialCost;

  const QuickServiceBookingData({
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
    this.computerDeviceType,
    this.computerBrand,
    this.computerModel,
    this.computerOS,
    this.computerIssue,
    this.printerDeviceType,
    this.printerBrand,
    this.printerModel,
    this.printerSerialNumber,
    this.printerConnectionMethod,
    this.printerIssues,
    this.printerDeviceCount,
    this.printerErrorCode,
    this.carWashPackage,
    this.carWashPackagePrice,
    this.vehicleColour,
    this.vehicleCondition,
    this.waterAccess,
    this.electricityAccess,
    this.vehicleCount,
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
    this.beautySelectedTreatments,
    this.beautyTreatmentsSubtotal,
    this.peopleCount,
    this.professionalPreference,
    this.customBeautyService,
    this.gardeningServiceArea,
    this.gardeningApproximateArea,
    this.greenWasteRemoval,
    this.paintingType,
    this.roomCount,
    this.paintProvided,
    this.eventType,
    this.guestCount,
    this.eventDuration,
    this.supplyType,
    this.supplyScale,
  });

  QuickServiceBookingData copyWith({
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
    String? dressPreference,
    String? alcoholServed,
    String? deviceType,
    String? deviceBrand,
    String? deviceModel,
    String? operatingSystem,
    String? mobileIssue,
    int? deviceCount,
    String? computerDeviceType,
    String? computerBrand,
    String? computerModel,
    String? computerOS,
    String? computerIssue,
    String? printerDeviceType,
    String? printerBrand,
    String? printerModel,
    String? printerSerialNumber,
    String? printerConnectionMethod,
    List<String>? printerIssues,
    int? printerDeviceCount,
    String? printerErrorCode,
    String? carWashPackage,
    double? carWashPackagePrice,
    String? vehicleColour,
    String? vehicleCondition,
    String? waterAccess,
    String? electricityAccess,
    int? vehicleCount,
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
    List<String>? beautySelectedTreatments,
    double? beautyTreatmentsSubtotal,
    int? peopleCount,
    String? professionalPreference,
    String? customBeautyService,
    String? gardeningServiceArea,
    String? gardeningApproximateArea,
    String? greenWasteRemoval,
    String? paintingType,
    int? roomCount,
    bool? paintProvided,
    String? eventType,
    int? guestCount,
    String? eventDuration,
    String? supplyType,
    String? supplyScale,
  }) {
    return QuickServiceBookingData(
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
      dressPreference: dressPreference ?? this.dressPreference,
      alcoholServed: alcoholServed ?? this.alcoholServed,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      mobileIssue: mobileIssue ?? this.mobileIssue,
      deviceCount: deviceCount ?? this.deviceCount,
      computerDeviceType: computerDeviceType ?? this.computerDeviceType,
      computerBrand: computerBrand ?? this.computerBrand,
      computerModel: computerModel ?? this.computerModel,
      computerOS: computerOS ?? this.computerOS,
      computerIssue: computerIssue ?? this.computerIssue,
      printerDeviceType: printerDeviceType ?? this.printerDeviceType,
      printerBrand: printerBrand ?? this.printerBrand,
      printerModel: printerModel ?? this.printerModel,
      printerSerialNumber: printerSerialNumber ?? this.printerSerialNumber,
      printerConnectionMethod: printerConnectionMethod ?? this.printerConnectionMethod,
      printerIssues: printerIssues ?? this.printerIssues,
      printerDeviceCount: printerDeviceCount ?? this.printerDeviceCount,
      printerErrorCode: printerErrorCode ?? this.printerErrorCode,
      carWashPackage: carWashPackage ?? this.carWashPackage,
      carWashPackagePrice: carWashPackagePrice ?? this.carWashPackagePrice,
      vehicleColour: vehicleColour ?? this.vehicleColour,
      vehicleCondition: vehicleCondition ?? this.vehicleCondition,
      waterAccess: waterAccess ?? this.waterAccess,
      electricityAccess: electricityAccess ?? this.electricityAccess,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      laundryServiceMethod: laundryServiceMethod ?? this.laundryServiceMethod,
      laundryServiceType: laundryServiceType ?? this.laundryServiceType,
      laundryPackagePrice: laundryPackagePrice ?? this.laundryPackagePrice,
      laundryQuantityKg: laundryQuantityKg ?? this.laundryQuantityKg,
      specialCareShirtCount: specialCareShirtCount ?? this.specialCareShirtCount,
      specialCareDressCount: specialCareDressCount ?? this.specialCareDressCount,
      specialCareTrouserCount: specialCareTrouserCount ?? this.specialCareTrouserCount,
      specialCareBeddingCount: specialCareBeddingCount ?? this.specialCareBeddingCount,
      detergentArrangement: detergentArrangement ?? this.detergentArrangement,
      customLaundryService: customLaundryService ?? this.customLaundryService,
      beautySelectedTreatments: beautySelectedTreatments ?? this.beautySelectedTreatments,
      beautyTreatmentsSubtotal: beautyTreatmentsSubtotal ?? this.beautyTreatmentsSubtotal,
      peopleCount: peopleCount ?? this.peopleCount,
      professionalPreference: professionalPreference ?? this.professionalPreference,
      customBeautyService: customBeautyService ?? this.customBeautyService,
      gardeningServiceArea: gardeningServiceArea ?? this.gardeningServiceArea,
      gardeningApproximateArea: gardeningApproximateArea ?? this.gardeningApproximateArea,
      greenWasteRemoval: greenWasteRemoval ?? this.greenWasteRemoval,
      paintingType: paintingType ?? this.paintingType,
      roomCount: roomCount ?? this.roomCount,
      paintProvided: paintProvided ?? this.paintProvided,
      eventType: eventType ?? this.eventType,
      guestCount: guestCount ?? this.guestCount,
      eventDuration: eventDuration ?? this.eventDuration,
      supplyType: supplyType ?? this.supplyType,
      supplyScale: supplyScale ?? this.supplyScale,
    );
  }
}
