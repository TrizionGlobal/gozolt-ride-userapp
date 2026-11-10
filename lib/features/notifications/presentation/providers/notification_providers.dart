import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_item.dart';

final notificationRemoteDatasourceProvider =
    Provider<NotificationRemoteDatasource>((ref) {
  return NotificationRemoteDatasource(ref.read(dioProvider));
});

/// Filter for notifications: null = All
final notificationFilterProvider = StateProvider<String?>((ref) => null);

/// Paginated notifications.
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final ds = ref.read(notificationRemoteDatasourceProvider);
  final filter = ref.watch(notificationFilterProvider);
  return NotificationsNotifier(ds, filter);
});

/// Unread count badge — derived from actual notification state.
final notificationUnreadCountProvider = Provider<int>((ref) {
  final notifState = ref.watch(notificationsProvider);
  return notifState.notifications.where((n) => !n.read).length;
});

/// Notification preferences.
final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier,
        NotificationPreference>((ref) {
  final ds = ref.read(notificationRemoteDatasourceProvider);
  return NotificationPreferencesNotifier(ds);
});

// ── Notifications State ───────────────────────────────────
class NotificationsState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRemoteDatasource _ds;
  final String? _filter;

  NotificationsNotifier(this._ds, this._filter)
      : super(const NotificationsState()) {
    load();
  }

  List<NotificationItem> _filterItems(List<NotificationItem> items) {
    if (_filter == null) return items;

    if (_filter == 'CAR_RENTAL') {
      return items.where((n) {
        final dataType = n.data?['type'] as String?;
        final moduleName = n.data?['module'] as String?;
        return moduleName == 'car-rentals' || dataType == 'CAR_RENTAL';
      }).toList();
    } else if (_filter == 'BIKE_RENTAL') {
      return items.where((n) {
        final dataType = n.data?['type'] as String?;
        final moduleName = n.data?['module'] as String?;
        return moduleName == 'bike-rentals' || dataType == 'BIKE_RENTAL';
      }).toList();
    } else if (_filter == 'QUICK_SERVICE') {
      return items.where((n) {
        final dataType = n.data?['type'] as String?;
        final moduleName = n.data?['module'] as String?;
        return moduleName == 'quick-services' || dataType == 'QUICK_SERVICE';
      }).toList();
    } else if (_filter == 'AIRPORT_TRANSFER') {
      return items.where((n) {
        final dataType = n.data?['type'] as String?;
        final moduleName = n.data?['module'] as String?;
        final serviceName = n.data?['service'] as String?;
        final titleLower = n.title.toLowerCase();
        return moduleName == 'airport-transfers' ||
            dataType == 'AIRPORT_TRANSFER' ||
            serviceName == 'AIRPORT_TRANSFER' ||
            titleLower.contains('airport');
      }).toList();
    } else if (_filter == 'RIDE_UPDATE') {
      return items.where((n) {
        final moduleName = n.data?['module'] as String?;
        final serviceName = n.data?['service'] as String?;
        if (moduleName == 'car-rentals' ||
            moduleName == 'bike-rentals' ||
            moduleName == 'quick-services' ||
            moduleName == 'airport-transfers' ||
            serviceName == 'AIRPORT_TRANSFER') {
          return false;
        }

        final titleLower = n.title.toLowerCase();
        if (titleLower.contains('handover') ||
            titleLower.contains('return') ||
            titleLower.contains('car rental') ||
            titleLower.contains('bike rental') ||
            titleLower.contains('quick service') ||
            titleLower.contains('airport') ||
            titleLower.contains('flight') ||
            titleLower.contains('terminal')) {
          return false;
        }
        return true;
      }).toList();
    } else {
      return items.where((n) => n.type == _filter).toList();
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    final apiFilter = (_filter == 'CAR_RENTAL' ||
            _filter == 'BIKE_RENTAL' ||
            _filter == 'QUICK_SERVICE' ||
            _filter == 'AIRPORT_TRANSFER')
        ? null
        : _filter;

    try {
      var rawItems = await _ds.getNotifications(type: apiFilter, page: 1, limit: 20);
      if (rawItems.isEmpty) {
        rawItems = _defaultNotifications();
      }

      final items = _filterItems(rawItems);

      if (mounted) {
        state = NotificationsState(
          notifications: items,
          isLoading: false,
          hasMore: rawItems.length >= 20,
          page: 1,
        );
      }
    } catch (e) {
      final defaults = _filterItems(_defaultNotifications());
      if (mounted) {
        state = NotificationsState(
          notifications: defaults,
          isLoading: false,
          hasMore: false,
          page: 1,
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    final apiFilter = (_filter == 'CAR_RENTAL' ||
            _filter == 'BIKE_RENTAL' ||
            _filter == 'QUICK_SERVICE' ||
            _filter == 'AIRPORT_TRANSFER')
        ? null
        : _filter;

    try {
      final nextPage = state.page + 1;
      final rawItems = await _ds.getNotifications(
        type: apiFilter,
        page: nextPage,
        limit: 20,
      );

      final items = _filterItems(rawItems);

      if (mounted) {
        state = state.copyWith(
          notifications: [...state.notifications, ...items],
          isLoading: false,
          hasMore: rawItems.length >= 20,
          page: nextPage,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Always update local state immediately so the badge clears at once
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => NotificationItem(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                data: n.data,
                read: true,
                createdAt: n.createdAt,
              ))
          .toList(),
    );
    try {
      await _ds.markAsRead(all: true);
    } catch (_) {}
  }

  static List<NotificationItem> _defaultNotifications() {
    return [
      NotificationItem(
        id: 'welcome',
        type: 'SYSTEM',
        title: 'Welcome to Gozolt!',
        body:
            'Thank you for joining Gozolt — The Super App. Book your first ride and earn 100 bonus GoCoins!',
        read: false,
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
  }

  void addScheduledRideNotification({
    required String pickup,
    required String dropoff,
    required DateTime scheduledAt,
    required String fare,
    required String vehicleType,
  }) {
    final timeStr = '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} at ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    final notif = NotificationItem(
      id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
      type: 'RIDE_UPDATE',
      title: 'Ride Scheduled Successfully',
      body:
          'Your ride to $dropoff is confirmed for $timeStr. You can manage your scheduled rides in the My Rides section.',
      data: {
        'subtype': 'scheduled_ride',
        'pickup': pickup,
        'dropoff': dropoff,
        'scheduledAt': scheduledAt.toIso8601String(),
        'fare': fare,
        'vehicleType': vehicleType,
      },
      read: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(
      notifications: [notif, ...state.notifications],
    );
  }

  void addLocalNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final notif = NotificationItem(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      data: data,
      read: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(
      notifications: [notif, ...state.notifications],
    );
  }

  Future<void> markAsRead(String id) async {
    // Always update local state immediately so the unread dot/badge clears at once
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id
              ? NotificationItem(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  data: n.data,
                  read: true,
                  createdAt: n.createdAt,
                )
              : n)
          .toList(),
    );
    try {
      await _ds.markAsRead(notificationIds: [id]);
    } catch (_) {}
  }
}

// ── Notification Preferences ──────────────────────────────
class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreference> {
  final NotificationRemoteDatasource _ds;

  NotificationPreferencesNotifier(this._ds)
      : super(const NotificationPreference()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await _ds.getPreferences();
      state = prefs;
    } catch (_) {}
  }

  Future<void> update(NotificationPreference newPrefs) async {
    state = newPrefs;
    await _ds.updatePreferences(newPrefs);
  }
}
