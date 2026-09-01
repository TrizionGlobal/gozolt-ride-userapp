import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/bike_model.dart';

class BikeRentalRemoteDatasource {
  final Dio _dio;

  BikeRentalRemoteDatasource(this._dio);

  Future<List<BikeModel>> getAvailableBikes() async {
    try {
      final response = await _dio.get(ApiConstants.bikeRentalBikes);
      final List<dynamic> data = response.data;
      return data.map((json) => BikeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch available rental bikes: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String bikeId,
    required DateTime startDate,
    required DateTime endDate,
    String? protectionPackageId,
    List<String>? addonIds,
    String? deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    String? dropoffLocation,
    bool? isFlexible,
    required String nationalIdPath,
    required String drivingLicencePath,
    String? paymentMethodId,
    double? walletAmountUsed,
    double? deliveryFee,
  }) async {
    try {
      final formData = FormData.fromMap({
        'bikeId': bikeId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (protectionPackageId != null) 'protectionPackageId': protectionPackageId,
        if (addonIds != null && addonIds.isNotEmpty) 'addonIds': addonIds.join(','),
        if (deliveryType != null) 'deliveryType': deliveryType,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        if (pickupLocation != null) 'pickupLocation': pickupLocation,
        if (dropoffLocation != null) 'dropoffLocation': dropoffLocation,
        if (isFlexible != null) 'isFlexible': isFlexible.toString(),
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (walletAmountUsed != null) 'walletAmountUsed': walletAmountUsed.toString(),
        if (deliveryFee != null) 'deliveryFee': deliveryFee.toString(),
        'nationalId': await MultipartFile.fromFile(nationalIdPath, filename: 'national_id.jpg'),
        'drivingLicence': await MultipartFile.fromFile(drivingLicencePath, filename: 'driving_licence.jpg'),
      });

      final response = await _dio.post(
        ApiConstants.bikeRentalBook,
        data: formData,
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to create booking';
        throw Exception(message);
      }
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final response = await _dio.get(ApiConstants.bikeRentalMyBookings);
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch bike rental history: $e');
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(String id) async {
    try {
      final response = await _dio.get(ApiConstants.bikeRentalBookingDetails(id));
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch booking details: $e');
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.bikeRentalBookingCancel(bookingId),
        data: reason != null ? {'reason': reason} : {},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to cancel booking';
        throw Exception(message);
      }
      throw Exception('Failed to cancel booking: $e');
    }
  }
  Future<Map<String, dynamic>> calculateExtensionCost(String bookingId, String newEndDate) async {
    try {
      final response = await _dio.post(
        ApiConstants.bikeRentalBookingExtendCalculate(bookingId),
        data: {'newEndDate': newEndDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to calculate extension cost';
        throw Exception(message);
      }
      throw Exception('Failed to calculate extension cost: $e');
    }
  }

  Future<Map<String, dynamic>> createExtensionPaymentIntent(String bookingId, String newEndDate) async {
    try {
      final response = await _dio.post(
        ApiConstants.bikeRentalBookingExtendPaymentIntent(bookingId),
        data: {'newEndDate': newEndDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to initialize payment';
        throw Exception(message);
      }
      throw Exception('Failed to initialize payment: $e');
    }
  }

  Future<Map<String, dynamic>> createExtensionRequest(String bookingId, String newEndDate, {String? paymentIntentId}) async {
    try {
      final response = await _dio.post(
        ApiConstants.bikeRentalBookingExtend(bookingId),
        data: {
          'newEndDate': newEndDate,
          if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to submit extension request';
        throw Exception(message);
      }
      throw Exception('Failed to submit extension request: $e');
    }
  }
}
