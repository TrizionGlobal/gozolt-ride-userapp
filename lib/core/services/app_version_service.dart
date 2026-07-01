import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gozolt_user_app/core/providers/dio_provider.dart';
import 'package:gozolt_user_app/core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appVersionServiceProvider = Provider<AppVersionService>((ref) {
  final dio = ref.watch(dioProvider);
  return AppVersionService(dio);
});

class AppVersionConfig {
  final String minimumVersion;
  final String latestVersion;
  final String iosStoreUrl;
  final String androidStoreUrl;

  AppVersionConfig({
    required this.minimumVersion,
    required this.latestVersion,
    required this.iosStoreUrl,
    required this.androidStoreUrl,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) {
    return AppVersionConfig(
      minimumVersion: json['minimumVersion'] ?? '1.0.0',
      latestVersion: json['latestVersion'] ?? '1.0.0',
      iosStoreUrl: json['iosStoreUrl'] ?? '',
      androidStoreUrl: json['androidStoreUrl'] ?? '',
    );
  }
}

class AppVersionService {
  final Dio _dio;

  AppVersionService(this._dio);

  Future<AppVersionConfig?> fetchAppVersionConfig() async {
    try {
      final response = await _dio.get(ApiConstants.appVersion);
      if (response.data != null && response.data['userApp'] != null) {
        return AppVersionConfig.fromJson(response.data['userApp']);
      }
      return null;
    } catch (e) {
      print('Error fetching app version config: $e');
      return null;
    }
  }

  Future<bool> isUpdateRequired(String minimumVersion) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final minParts = minimumVersion.split('.').map(int.parse).toList();

      print('DEBUG: App Version Check - Current: $currentVersion, Minimum: $minimumVersion');

      for (int i = 0; i < 3; i++) {
        final current = i < currentParts.length ? currentParts[i] : 0;
        final min = i < minParts.length ? minParts[i] : 0;

        if (current < min) {
          return true; // Update required
        } else if (current > min) {
          return false; // Safely above min version
        }
      }
      return false; // Exact match
    } catch (e) {
      print('Error parsing versions: $e');
      return false;
    }
  }
}
