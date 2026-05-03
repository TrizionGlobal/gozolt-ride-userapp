import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/models/user_address.dart';
import '../../data/models/user_profile.dart';

final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  return HomeRemoteDatasource(ref.read(dioProvider));
});

/// Current bottom nav tab index.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// User profile for greeting header.
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  if (AppConstants.kDevBypass) {
    return const UserProfile(
      id: 'dev-user',
      firstName: 'Dev',
      lastName: 'User',
      phone: '+35699000001',
      city: 'Sliema',
      country: 'MT',
    );
  }
  ref.keepAlive();
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUserProfile();
});

/// Saved addresses for the home shortcut.
final savedAddressesProvider = FutureProvider.autoDispose<List<UserAddress>>((ref) async {
  ref.keepAlive();
  if (AppConstants.kDevBypass) {
    return const [
      UserAddress(
        id: 'addr-1',
        label: 'Home',
        address: '24 Luxury Towers, Sliema',
        latitude: 35.9117,
        longitude: 14.5050,
      ),
      UserAddress(
        id: 'addr-2',
        label: 'Work',
        address: 'SmartCity Malta, Kalkara',
        latitude: 35.8885,
        longitude: 14.5340,
      ),
    ];
  }
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUserAddresses();
});

/// Unread notification badge count.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.keepAlive();
  if (AppConstants.kDevBypass) return 3;
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUnreadNotificationCount();
});
