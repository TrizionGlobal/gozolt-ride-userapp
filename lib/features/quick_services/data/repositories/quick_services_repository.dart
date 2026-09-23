import 'package:dio/dio.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../../core/network/dio_client.dart';
import '../models/quick_service_booking_data.dart';
import '../models/quick_service_booking_data.dart';
import '../models/quick_service_history_model.dart';
import 'package:intl/intl.dart';

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
      final uploadRes = await _dio.post(
        '/v1/quick-services/upload-image', 
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (uploadRes.data != null && uploadRes.data['url'] != null) {
        imageUrls.add(uploadRes.data['url']);
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
      
      // Pest Control
      if (data.pestType != null) options['Pest Type'] = data.pestType;
      if (data.pestAffectedAreas != null && data.pestAffectedAreas!.isNotEmpty) options['Affected Areas'] = data.pestAffectedAreas;
      if (data.pestObservedLevel != null) options['Observed Level'] = data.pestObservedLevel;
      if (data.childrenOrPets != null) options['Children or Pets'] = data.childrenOrPets;
      
      // Laundry
      if (data.laundryServiceMethod != null) options['Service Method'] = data.laundryServiceMethod;
      if (data.laundryServiceType != null) options['Service Type'] = data.laundryServiceType;
      if (data.laundryQuantityKg != null) options['Quantity (Kg)'] = data.laundryQuantityKg;
      if (data.detergentArrangement != null) options['Detergent Arrangement'] = data.detergentArrangement;
      
      // IT & Mobile
      if (data.mobileDevices != null && data.mobileDevices!.isNotEmpty) {
        options['Mobile Devices'] = data.mobileDevices!.map((d) => {
          'Type': d.deviceType, 'Brand': d.deviceBrand, 'Model': d.deviceModel, 'Issue': d.issue
        }).toList();
      }
      if (data.computerDevices != null && data.computerDevices!.isNotEmpty) {
        options['Computer Devices'] = data.computerDevices!.map((d) => {
          'Type': d.deviceType, 'Brand': d.brand, 'Model': d.model, 'Issue': d.issue
        }).toList();
      }
      if (data.printerDevices != null && data.printerDevices!.isNotEmpty) {
        options['Printer Devices'] = data.printerDevices!.map((d) => {
          'Type': d.deviceType, 'Brand': d.brand, 'Model': d.model, 'Issues': d.issues
        }).toList();
      }
      
      // General Options Fallbacks
      if (data.materialPreference != null) options['Material Preference'] = data.materialPreference;
      if (data.whatYouNeed != null) options['What You Need'] = data.whatYouNeed;
      
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
        'totalAmount': data.upfrontBookingFee + data.materialCost, // Final upfront payment
        'options': options,
        'addOns': data.selectedAddons.map((addon) => {
          'name': addon.name,
          'count': addon.count,
          'price': addon.pricePerUnit,
          'isFixedPrice': addon.isFixedPrice,
        }).toList(),
        'images': imageUrls,
        'requirements': data.describeIssue ?? '',
      };

      final response = await _dio.post(
        '/v1/quick-services/book',
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
      final response = await _dio.get('/v1/quick-services/history');
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
