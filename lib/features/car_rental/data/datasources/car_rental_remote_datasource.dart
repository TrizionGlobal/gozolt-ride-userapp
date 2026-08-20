import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/car_model.dart';

class CarRentalRemoteDatasource {
  final Dio _dio;

  CarRentalRemoteDatasource(this._dio);

  Future<List<CarModel>> getAvailableVehicles() async {
    try {
      final response = await _dio.get(ApiConstants.carRentalVehicles);
      final List<dynamic> data = response.data;
      return data.map((json) => CarModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch available rental vehicles: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    String? protectionPackageId,
    List<String>? addonIds,
    String? deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    String? dropoffLocation,
    bool isFlexible = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.carRentalBook,
        data: {
          'vehicleId': vehicleId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'protectionPackageId': protectionPackageId,
          'addonIds': addonIds,
          'deliveryType': deliveryType,
          'deliveryAddress': deliveryAddress,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'isFlexible': isFlexible,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to create rental booking';
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to create rental booking: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final response = await _dio.get(ApiConstants.carRentalMyBookings);
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch car rental history: $e');
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(String id) async {
    try {
      final response = await _dio.get(ApiConstants.carRentalBookingDetails(id));
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch booking details: $e');
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.carRentalBookingCancel(bookingId),
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
        ApiConstants.carRentalBookingExtendCalculate(bookingId),
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
        ApiConstants.carRentalBookingExtendPaymentIntent(bookingId),
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
        ApiConstants.carRentalBookingExtend(bookingId),
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
