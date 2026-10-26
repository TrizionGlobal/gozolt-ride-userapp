import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../domain/models/airport_transfer_vehicle.dart';

final airportTransferRemoteDatasourceProvider = Provider<AirportTransferRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return AirportTransferRemoteDatasource(dio);
});

class AirportTransferRemoteDatasource {
  final Dio _dio;

  AirportTransferRemoteDatasource(this._dio);

  Future<List<AirportTransferVehicle>> getAvailableVehicles({
    int? passengers,
    int? luggage,
    String? type,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? transferType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (passengers != null && passengers > 0) queryParams['passengers'] = passengers;
      if (luggage != null && luggage > 0) queryParams['luggage'] = luggage;
      if (type != null && type.isNotEmpty && type != 'All') queryParams['type'] = type;
      if (pickupLat != null) queryParams['pickupLat'] = pickupLat;
      if (pickupLng != null) queryParams['pickupLng'] = pickupLng;
      if (dropoffLat != null) queryParams['dropoffLat'] = dropoffLat;
      if (dropoffLng != null) queryParams['dropoffLng'] = dropoffLng;
      if (transferType != null && transferType.isNotEmpty) queryParams['transferType'] = transferType;

      final response = await _dio.get(
        ApiConstants.airportTransferVehicles,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => AirportTransferVehicle.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch airport transfer vehicles: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String vehicleId,
    required String transferType,
    String? flightNumber,
    String? returnFlightNumber,
    required String pickupLocation,
    required String dropoffLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    required DateTime pickupDateTime,
    DateTime? returnDateTime,
    required int adults,
    int? children,
    int? infants,
    int? standardLuggage,
    int? largeLuggage,
    required String leadPassengerName,
    required String leadPassengerEmail,
    required String leadPassengerPhone,
    String? specialRequests,
    String? paymentMethod,
    String? paymentMethodId,
    double? totalAmount,
    double? discount,
  }) async {
    try {
      final payload = {
        'vehicleId': vehicleId,
        'transferType': transferType,
        if (flightNumber != null && flightNumber.isNotEmpty) 'flightNumber': flightNumber,
        if (returnFlightNumber != null && returnFlightNumber.isNotEmpty) 'returnFlightNumber': returnFlightNumber,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        if (pickupLat != null) 'pickupLat': pickupLat,
        if (pickupLng != null) 'pickupLng': pickupLng,
        if (dropoffLat != null) 'dropoffLat': dropoffLat,
        if (dropoffLng != null) 'dropoffLng': dropoffLng,
        'pickupDateTime': pickupDateTime.toIso8601String(),
        if (returnDateTime != null) 'returnDateTime': returnDateTime.toIso8601String(),
        'adults': adults,
        if (children != null) 'children': children,
        if (infants != null) 'infants': infants,
        if (standardLuggage != null) 'standardLuggage': standardLuggage,
        if (largeLuggage != null) 'largeLuggage': largeLuggage,
        'leadPassengerName': leadPassengerName,
        'leadPassengerEmail': leadPassengerEmail,
        'leadPassengerPhone': leadPassengerPhone,
        if (specialRequests != null && specialRequests.isNotEmpty) 'specialRequests': specialRequests,
        'paymentMethod': paymentMethod ?? 'CARD',
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (discount != null) 'discount': discount,
      };

      final response = await _dio.post(
        ApiConstants.airportTransferBook,
        data: payload,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to create transfer booking';
        throw Exception(message);
      }
      throw Exception('Failed to create transfer booking: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final response = await _dio.get(ApiConstants.airportTransferMyBookings);
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch airport transfer history: $e');
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(String id) async {
    try {
      final response = await _dio.get(ApiConstants.airportTransferBookingDetails(id));
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch booking details: $e');
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String id, {String? reason}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.airportTransferCancel(id),
        data: reason != null ? {'reason': reason} : {},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to cancel transfer booking';
        throw Exception(message);
      }
      throw Exception('Failed to cancel transfer booking: $e');
    }
  }

  Future<Map<String, dynamic>> verifyPayment(String id) async {
    try {
      final response = await _dio.get(ApiConstants.airportTransferVerifyPayment(id));
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to verify transfer payment';
        throw Exception(message);
      }
      throw Exception('Failed to verify transfer payment: $e');
    }
  }

  Future<Map<String, dynamic>> processPayment(
    String id, {
    required String paymentMethod,
    String? paymentMethodId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.airportTransferPay(id),
        data: {
          'paymentMethod': paymentMethod,
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Failed to process transfer payment';
        throw Exception(message);
      }
      throw Exception('Failed to process transfer payment: $e');
    }
  }
}
