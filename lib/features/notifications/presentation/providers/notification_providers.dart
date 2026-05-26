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

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 300));
      final filtered = _filter == null
          ? _mockNotifications
          : _mockNotifications.where((n) => n.type == _filter).toList();
      state = NotificationsState(
        notifications: filtered,
        isLoading: false,
        hasMore: false,
        page: 1,
      );
      return;
    }

    try {
      var items = await _ds.getNotifications(type: _filter, page: 1);
      // If API returned empty, show default notifications
      if (items.isEmpty) {
        items = _defaultNotifications();
        if (_filter != null) {
          items = items.where((n) => n.type == _filter).toList();
        }
      }
      state = NotificationsState(
        notifications: items,
        isLoading: false,
        hasMore: items.length >= 20,
        page: 1,
      );
    } catch (e) {
      // API failed — show default notifications instead of error
      var defaults = _defaultNotifications();
      if (_filter != null) {
        defaults = defaults.where((n) => n.type == _filter).toList();
      }
      state = NotificationsState(
        notifications: defaults,
        isLoading: false,
        hasMore: false,
        page: 1,
      );
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
    if (!AppConstants.kDevBypass) {
      try {
        await _ds.markAsRead(all: true);
      } catch (_) {}
    }
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
    if (!AppConstants.kDevBypass) {
      try {
        await _ds.markAsRead(notificationIds: [id]);
      } catch (_) {}
    }
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
    if (AppConstants.kDevBypass) return;
    try {
      final prefs = await _ds.getPreferences();
      state = prefs;
    } catch (_) {}
  }

  Future<void> update(NotificationPreference newPrefs) async {
    state = newPrefs;
    if (!AppConstants.kDevBypass) {
      await _ds.updatePreferences(newPrefs);
    }
  }
}

// ── Dev mock data ─────────────────────────────────────────
final _mockNotifications = [
  const NotificationItem(
    id: 'notif-001',
    type: 'RIDE_UPDATE',
    title: 'Thank you for riding with us!',
    body: 'Your trip to Valletta Bus Station is complete. View your trip details in the My Rides section.',
    data: {'subtype': 'ride_completed', 'rideId': 'ride-001'},
    read: false,
    createdAt: '2025-05-20T14:50:00Z',
  ),
  const NotificationItem(
    id: 'notif-002',
    type: 'PROMOTION',
    title: 'Weekend Special!',
    body: 'Get 2x GoCoins on all rides this weekend. Book now and earn more!',
    read: false,
    createdAt: '2025-05-19T10:00:00Z',
  ),
  const NotificationItem(
    id: 'notif-003',
    type: 'RIDE_UPDATE',
    title: 'Ride Scheduled Successfully',
    body: 'Your ride to Malta International Airport is confirmed for 25/5/2025 at 06:00. You can manage your scheduled rides in the My Rides section.',
    data: {
      'subtype': 'scheduled_ride',
      'pickup': '24 Luxury Towers, Sliema',
      'dropoff': 'Malta International Airport',
      'scheduledAt': '2025-05-25T06:00:00Z',
      'fare': '€22.00',
      'vehicleType': 'PREMIUM',
    },
    read: false,
    createdAt: '2025-05-18T08:00:00Z',
  ),
  const NotificationItem(
    id: 'notif-004',
    type: 'RIDE_UPDATE',
    title: 'Thank you for riding with us!',
    body: 'Your trip to Hilton Malta, Portomaso is complete. View your trip details in the My Rides section.',
    data: {'subtype': 'ride_completed', 'rideId': 'ride-002'},
    read: true,
    createdAt: '2025-05-18T09:40:00Z',
  ),
  const NotificationItem(
    id: 'notif-005',
    type: 'RIDE_UPDATE',
    title: 'Ride Cancelled',
    body: 'Your ride to Bugibba Square, Bugibba has been cancelled. You can book a new ride anytime.',
    data: {'subtype': 'ride_cancelled', 'rideId': 'ride-003'},
    read: true,
    createdAt: '2025-05-17T18:50:00Z',
  ),
  const NotificationItem(
    id: 'notif-006',
    type: 'PROMOTION',
    title: 'Refer & Earn',
    body: 'Share your referral code and earn GoCoins for every friend who joins Gozolt!',
    read: true,
    createdAt: '2025-05-16T14:00:00Z',
  ),
  const NotificationItem(
    id: 'notif-007',
    type: 'SYSTEM',
    title: 'Welcome to Gozolt!',
    body: 'Thank you for joining Gozolt — The Super App. Book your first ride and earn 100 bonus GoCoins!',
    read: true,
    createdAt: '2025-05-10T09:00:00Z',
  ),
];
