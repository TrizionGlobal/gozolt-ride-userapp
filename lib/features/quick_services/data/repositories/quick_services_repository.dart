import 'package:dio/dio.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../../core/config/quick_services_pricing_config.dart';

import '../../../../core/network/dio_client.dart';
import '../models/quick_service_booking_data.dart';
import '../models/quick_service_booking_data.dart';
import '../models/quick_service_history_model.dart';
import 'package:intl/intl.dart';
import '../../../../features/ride/data/models/saved_payment_method.dart';

class QuickServicesRepository {
  final Dio _dio;

  QuickServicesRepository(this._dio);

  Future<List<String>> uploadImages(List<String> imagePaths) async {
    final List<String> imageUrls = [];
    if (imagePaths.isEmpty) return imageUrls;
    
    for (final imagePath in imagePaths) {
      if (imagePath.startsWith('http')) {
        imageUrls.add(imagePath);
        continue;
      }
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });
      try {
        final uploadRes = await _dio.post(
          '/quick-services/upload-image', 
          data: formData,
        );
        if (uploadRes.data != null && uploadRes.data['url'] != null) {
          imageUrls.add(uploadRes.data['url']);
        }
      } catch (e) {
        if (e is DioException) {
          print('DioException during image upload: ${e.response?.statusCode} - ${e.response?.data}');
        } else {
          print('Error during image upload: $e');
        }
        rethrow;
      }
    }
    return imageUrls;
  }

  Future<String> bookQuickService(QuickServiceBookingData data) async {
    try {
      final List<String> imageUrls = await uploadImages(data.uploadedImages ?? []);

      // Build the options JSON mapping all category-specific fields
      final Map<String, dynamic> options = {};
      
      // Home Cleaning
      if (data.propertyType != null) options['Property Type'] = data.propertyType;
      if (data.roomCount != null) options['Room Count'] = data.roomCount;
      if (data.pestAffectedRooms != null) options['Affected Rooms'] = data.pestAffectedRooms;
      
      // Mechanic
      if (data.mechanicVehicles != null && data.mechanicVehicles!.isNotEmpty) {
        options['Vehicles'] = data.mechanicVehicles!.map((v) => {
          'Type': v.type, 'Make': v.make, 'Model': v.model, 'Year': v.year, 'Registration': v.registration, 'Issue': v.issue
        }).toList();
      } else {
        if (data.carType != null) options['Car Type'] = data.carType;
        if (data.vehicleMake != null) options['Vehicle Make'] = data.vehicleMake;
        if (data.vehicleModel != null) options['Vehicle Model'] = data.vehicleModel;
        if (data.vehicleIssue != null) options['Issue'] = data.vehicleIssue;
      }
      
      // Car Wash
      if (data.carWashVehicles != null && data.carWashVehicles!.isNotEmpty) {
        options['Car Wash Vehicles'] = data.carWashVehicles!.map((v) => {
          'Type': v.type, 'Make': v.make, 'Model': v.model, 'Package': v.washPackage, 'Condition': v.condition
        }).toList();
      }
      if (data.carWashPackage != null) options['Wash Package'] = data.carWashPackage;
      if (data.vehicleColour != null) options['Vehicle Colour'] = data.vehicleColour;
      if (data.vehicleCondition != null) options['Vehicle Condition'] = data.vehicleCondition;
      if (data.waterAccess != null) options['Water Access'] = data.waterAccess;
      if (data.electricityAccess != null) options['Electricity Access'] = data.electricityAccess;
      if (data.vehicleCount != null) options['Vehicle Count'] = data.vehicleCount;
      if (data.vehicleServiceMode != null) options['Service Mode'] = data.vehicleServiceMode;
      
      // Pest Control
      if (data.pestType != null) options['Pest Type'] = data.pestType;
      if (data.pestAffectedAreas != null && data.pestAffectedAreas!.isNotEmpty) options['Affected Areas'] = data.pestAffectedAreas;
      if (data.pestAffectedRooms != null) options['Affected Rooms'] = data.pestAffectedRooms;
      if (data.pestObservedLevel != null) options['Observed Level'] = data.pestObservedLevel;
      if (data.childrenOrPets != null) options['Children or Pets'] = data.childrenOrPets;
      
      // Laundry
      if (data.laundryServiceMethod != null) options['Service Method'] = data.laundryServiceMethod;
      if (data.laundryServiceType != null) options['Service Type'] = data.laundryServiceType;
      if (data.laundryQuantityKg != null) options['Quantity (Kg)'] = data.laundryQuantityKg;
      if (data.detergentArrangement != null) options['Detergent Arrangement'] = data.detergentArrangement;
      if (data.specialCareShirtCount != null) options['Special Care Shirts'] = data.specialCareShirtCount;
      if (data.specialCareDressCount != null) options['Special Care Dresses'] = data.specialCareDressCount;
      if (data.specialCareTrouserCount != null) options['Special Care Trousers'] = data.specialCareTrouserCount;
      if (data.specialCareBeddingCount != null) options['Special Care Bedding'] = data.specialCareBeddingCount;
      if (data.customLaundryService != null) options['Custom Laundry Service'] = data.customLaundryService;
      if (data.facilityName != null) options['Facility Name'] = data.facilityName;
      if (data.collectionPoint != null) options['Collection Point'] = data.collectionPoint;
      if (data.facilityContactPerson != null) options['Contact Person'] = data.facilityContactPerson;
      if (data.facilityContactNumber != null) options['Contact Number'] = data.facilityContactNumber;
      if (data.commercialLaundryTypes != null && data.commercialLaundryTypes!.isNotEmpty) options['Laundry Types'] = data.commercialLaundryTypes;
      if (data.numberOfBags != null) options['Number of Bags'] = data.numberOfBags;
      if (data.linenHandlingType != null) options['Handling Type'] = data.linenHandlingType;
      if (data.serviceFrequency != null) options['Service Frequency'] = data.serviceFrequency;
      if (data.businessType != null) options['Business Type'] = data.businessType;
      if (data.requestedReturnDate != null) options['Return Date'] = data.requestedReturnDate!.toIso8601String().split('T').first;
      if (data.requestedReturnTime != null) options['Return Time'] = '${data.requestedReturnTime!.hour}:${data.requestedReturnTime!.minute}';
      if (data.collectionInstructions != null) options['Collection Instructions'] = data.collectionInstructions;

      // IT & Mobile
      if (data.mobileDevices != null && data.mobileDevices!.isNotEmpty) {
        options['Mobile Devices'] = data.mobileDevices!.map((d) => {
          'Type': d.deviceType, 'Brand': d.deviceBrand, 'Model': d.deviceModel, 'Issue': d.issue
        }).toList();
      }
      if (data.deviceType != null) options['Device Type'] = data.deviceType;
      if (data.deviceBrand != null) options['Device Brand'] = data.deviceBrand;
      if (data.deviceModel != null) options['Device Model'] = data.deviceModel;
      if (data.operatingSystem != null) options['OS'] = data.operatingSystem;
      if (data.mobileIssue != null) options['Issue'] = data.mobileIssue;
      if (data.deviceCount != null) options['Device Count'] = data.deviceCount;
      
      if (data.computerDevices != null && data.computerDevices!.isNotEmpty) {
        options['Computer Devices'] = data.computerDevices!.map((d) => {
          'Type': d.deviceType, 'Brand': d.brand, 'Model': d.model, 'Issue': d.issue
        }).toList();
      }
      if (data.computerDeviceType != null) options['Computer Type'] = data.computerDeviceType;
      if (data.computerBrand != null) options['Computer Brand'] = data.computerBrand;
      if (data.computerModel != null) options['Computer Model'] = data.computerModel;
      if (data.computerOS != null) options['Computer OS'] = data.computerOS;
      if (data.computerIssue != null) options['Computer Issue'] = data.computerIssue;
      
      if (data.printerDevices != null && data.printerDevices!.isNotEmpty) {
        options['Printer Devices'] = data.printerDevices!.map((d) => {
          'Type': d.deviceType, 'Brand': d.brand, 'Model': d.model, 'Issues': d.issues
        }).toList();
      }
      if (data.printerDeviceType != null) options['Printer Type'] = data.printerDeviceType;
      if (data.printerBrand != null) options['Printer Brand'] = data.printerBrand;
      if (data.printerModel != null) options['Printer Model'] = data.printerModel;
      if (data.printerSerialNumber != null) options['Printer S/N'] = data.printerSerialNumber;
      if (data.printerConnectionMethod != null) options['Connection Method'] = data.printerConnectionMethod;
      if (data.printerIssues != null && data.printerIssues!.isNotEmpty) options['Printer Issues'] = data.printerIssues;
      if (data.printerDeviceCount != null) options['Printer Count'] = data.printerDeviceCount;
      if (data.printerErrorCode != null) options['Printer Error Code'] = data.printerErrorCode;
      
      // General Options Fallbacks
      if (data.materialPreference != null) options['Material Preference'] = data.materialPreference;
      if (data.whatYouNeed != null) options['What You Need'] = data.whatYouNeed;
      if (data.describeIssue != null) options['Issue Description'] = data.describeIssue;
      if (data.taskCategory != null) options['Task Category'] = data.taskCategory;
      if (data.projectScope != null) options['Project Scope'] = data.projectScope;
      if (data.propertyType != null) options['Property Type'] = data.propertyType;
      if (data.liftType != null) options['Lift Type'] = data.liftType;
      if (data.floorsServed != null) options['Floors Served'] = data.floorsServed;
      if (data.expectedDuration != null) options['Expected Duration'] = data.expectedDuration;
      if (data.comments != null) options['Comments'] = data.comments;
      if (data.helperCount != null) options['Helper Count'] = data.helperCount;
      if (data.genderPreference != null) options['Gender Preference'] = data.genderPreference;
      if (data.securityService != null) options['Security Service'] = data.securityService;
      if (data.venueType != null) options['Venue Type'] = data.venueType;
      if (data.dutyStartTime != null) options['Duty Start Time'] = data.dutyStartTime;
      if (data.dutyEndTime != null) options['Duty End Time'] = data.dutyEndTime;
      if (data.personnelCount != null) options['Personnel Count'] = data.personnelCount;
      if (data.expectedAttendance != null) options['Expected Attendance'] = data.expectedAttendance;
      if (data.serviceArea != null) options['Service Area'] = data.serviceArea;
      
      // Gardening
      if (data.gardeningServices != null) options['Gardening Services'] = data.gardeningServices;
      if (data.gardeningServiceArea != null) options['Service Area'] = data.gardeningServiceArea;
      if (data.gardeningApproximateArea != null) options['Approximate Area'] = data.gardeningApproximateArea;
      if (data.greenWasteRemoval != null) options['Green Waste Removal'] = data.greenWasteRemoval;

      // Moving & Painting
      if (data.paintingType != null) options['Painting Type'] = data.paintingType;
      if (data.roomCount != null) options['Room Count'] = data.roomCount;
      if (data.paintProvided != null) options['Paint Provided'] = data.paintProvided! ? 'Yes' : 'No';
      if (data.paintingAreas != null && data.paintingAreas!.isNotEmpty) options['Painting Areas'] = data.paintingAreas;
      
      // Beauty & Events
      if (data.professionalPreference != null) options['Professional Preference'] = data.professionalPreference;
      if (data.customBeautyService != null) options['Custom Beauty Service'] = data.customBeautyService;
      if (data.eventType != null) options['Event Type'] = data.eventType;
      if (data.eventDuration != null) options['Event Duration'] = data.eventDuration;
      if (data.dressPreference != null) options['Dress Preference'] = data.dressPreference;
      if (data.alcoholServed != null) options['Alcohol Served'] = data.alcoholServed;
      if (data.beautySelectedTreatments != null && data.beautySelectedTreatments!.isNotEmpty) options['Selected Treatments'] = data.beautySelectedTreatments;
      if (data.peopleCount != null) options['People Count'] = data.peopleCount;
      if (data.guestCount != null) options['Guest Count'] = data.guestCount;
      
      // Supply Delivery
      if (data.supplyCategory != null) options['Supply Category'] = data.supplyCategory;
      if (data.itemRequired != null) options['Item Required'] = data.itemRequired;
      if (data.supplyQuantity != null) options['Quantity'] = data.supplyQuantity;
      if (data.supplyUnit != null) options['Unit'] = data.supplyUnit;
      if (data.requestType != null) options['Request Type'] = data.requestType;
      if (data.requirementDescription != null) options['Description'] = data.requirementDescription;

      // Other Services
      if (data.bikeType != null) options['Bike Type'] = data.bikeType;
      if (data.truckType != null) options['Truck Type'] = data.truckType;
      
      final double rawTotal = data.upfrontBookingFee + data.materialCost;
      final double discountAmount = data.useGoCoins ? rawTotal.clamp(0.0, 6.0) : 0.0;
      final double finalTotal = rawTotal - discountAmount;
      final String? estimatedPrice = QuickServicesPricingConfig.getEstimatedSparePrice(data.servicePricingKey);

      final payload = {
        'serviceCategory': data.category,
        'serviceTitle': data.selectedServiceTitle ?? data.category,
        'serviceMethod': data.laundryServiceMethod ?? '',
        'serviceType': data.laundryServiceType ?? '',
        // Combine date and time
        'bookingDate': DateTime(
          data.scheduleDate.year,
          data.scheduleDate.month,
          data.scheduleDate.day,
          data.scheduleTime.hour,
          data.scheduleTime.minute,
        ).toUtc().toIso8601String(),
        'upfrontFee': data.upfrontBookingFee,
        'materialCost': data.materialCost,
        'discountAmount': discountAmount,
        'totalAmount': finalTotal, // Final upfront payment after discount
        'estimatedPrice': estimatedPrice,
        'options': options,
        'addOns': data.selectedAddons.map((addon) {
          final Map<String, dynamic> addonData = {
            'name': addon.name,
            'count': addon.count,
          };
          if (addon.pricePerUnit != null) {
            addonData['price'] = addon.pricePerUnit;
            addonData['isFixedPrice'] = addon.isFixedPrice;
          }
          return addonData;
        }).toList(),
        'images': imageUrls,
        'requirements': data.describeIssue ?? '',
        'location': data.location.address,
        'userName': data.userName,
        'userPhone': data.userPhone,
        'userEmail': data.userEmail,
        'paymentMethodType': data.paymentMethodType == PaymentMethodType.cash ? 'cash' : 'card',
        'paymentMethodId': data.paymentMethodId,
      };

      final response = await _dio.post(
        '/quick-services/book',
        data: payload,
      );

      return response.data['id'] as String;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to book quick service');
      }
      throw Exception(e.toString());
    }
  }

  Future<List<QuickServiceHistoryModel>> getQuickServiceHistory() async {
    try {
      final response = await _dio.get('/quick-services/history');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => QuickServiceHistoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching quick service history: $e');
      return [];
    }
  }
}
