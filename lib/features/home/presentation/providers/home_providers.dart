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
  
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUserAddresses();
});

/// Unread notification badge count.
/// In production: fetches from API.
/// In dev bypass: derived reactively from notificationsProvider state so
/// the badge updates instantly when notifications are marked as read.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.keepAlive();
  
  final ds = ref.read(homeRemoteDatasourceProvider);
  return ds.getUnreadNotificationCount();
});
