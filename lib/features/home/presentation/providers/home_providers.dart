import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/models/user_address.dart';
import '../../data/models/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';

final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  return HomeRemoteDatasource(ref.read(dioProvider));
});

/// Current bottom nav tab index.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// User profile for greeting header.
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  ref.keepAlive();

  ref.listen(authProvider, (previous, next) {
    if (next.status == AuthStatus.unauthenticated) {
      ref.invalidateSelf();
    }
  });

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
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUserProfile();
});

/// Saved addresses for the home shortcut.
final savedAddressesProvider = FutureProvider.autoDispose<List<UserAddress>>((ref) async {
  ref.keepAlive();

  ref.listen(authProvider, (previous, next) {
    if (next.status == AuthStatus.unauthenticated) {
      ref.invalidateSelf();
    }
  });
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
/// In production: fetches from API.
/// In dev bypass: derived reactively from notificationsProvider state so
/// the badge updates instantly when notifications are marked as read.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.keepAlive();
  if (AppConstants.kDevBypass) {
    // Watch notificationsProvider so this updates reactively when read state changes
    // ignore: unused_local_variable
    final _ = ref.watch(notificationsProvider);
    return ref.read(notificationsProvider).notifications.where((n) => !n.read).length;
  }
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUnreadNotificationCount();
});
