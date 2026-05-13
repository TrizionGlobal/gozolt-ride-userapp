import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../home/data/models/user_address.dart';
import '../../../home/data/models/user_profile.dart';
import '../../../ride/data/models/saved_payment_method.dart';

class AccountRemoteDatasource {
  final Dio _dio;

  AccountRemoteDatasource(this._dio);

  // ── Profile ─────────────────────────────────────────
  Future<UserProfile> getProfile() async {
    final response = await _dio.get(ApiConstants.userProfile);
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> updates) async {
    final response = await _dio.patch(ApiConstants.userProfile, data: updates);
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    await _dio.post(ApiConstants.userAvatar, data: formData);
  }

  Future<void> deleteAvatar() async {
    await _dio.delete(ApiConstants.userAvatar);
  }

  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.userProfile);
  }

  Future<void> exportData() async {
    await _dio.get(ApiConstants.userExport);
  }

  // ── Addresses ───────────────────────────────────────
  Future<List<UserAddress>> getAddresses() async {
    final response = await _dio.get(ApiConstants.userAddresses);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserAddress> addAddress(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.userAddresses, data: data);
    return UserAddress.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    await _dio.patch('${ApiConstants.userAddresses}/$id', data: data);
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('${ApiConstants.userAddresses}/$id');
  }

  // ── Payment Methods ─────────────────────────────────
  Future<List<SavedPaymentMethod>> getPaymentMethods() async {
    final response = await _dio.get(ApiConstants.paymentMethods);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => SavedPaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createSetupIntent() async {
    final response = await _dio.post(ApiConstants.paymentSetupIntent);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPaymentSheet(double amount) async {
    final response = await _dio.post(
      ApiConstants.paymentPaymentSheet,
      data: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePaymentMethod(String id) async {
    await _dio.delete('${ApiConstants.paymentMethods}/$id');
  }

  Future<void> confirmSetupIntent(String paymentMethodId) async {
    await _dio.post(
      ApiConstants.paymentConfirmSetup,
      data: {'paymentMethodId': paymentMethodId},
    );
  }

  // ── Preferences ─────────────────────────────────────
  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _dio.get(ApiConstants.userPreferences);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    await _dio.patch(ApiConstants.userPreferences, data: data);
  }

  // ── Auth ────────────────────────────────────────────
  Future<void> logout() async {
    await _dio.post(ApiConstants.logout);
  }
}
