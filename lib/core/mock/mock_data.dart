import '../../../features/home/data/models/user_profile.dart';
import '../../../features/home/data/models/user_address.dart';
import '../../../features/notifications/data/models/notification_item.dart';
import '../../../features/ride/data/models/saved_payment_method.dart';

/// Centralized mock data used throughout the app when dev bypass mode is active.
abstract final class MockData {
  // ── User Profile ──────────────────────────────────────────────────────

  static const mockUserProfile = UserProfile(
    id: 'dev-user',
    firstName: 'Dev',
    lastName: 'User',
    phone: '+35699000001',
    email: 'dev@gozolt.com',
    city: 'Sliema',
    country: 'MT',
    referralCode: 'GOZOLT-DEV',
  );

  // ── Saved Addresses ───────────────────────────────────────────────────

  static const mockAddresses = <UserAddress>[
    UserAddress(
      id: 'addr-1',
      label: 'Home',
      address: '24 Luxury Towers, Sliema',
      latitude: 35.9117,
      longitude: 14.5050,
    ),
  ];

  // ── Payment Methods ───────────────────────────────────────────────────

  static const mockPaymentMethods = <SavedPaymentMethod>[
    SavedPaymentMethod(
      id: 'pm-1',
      brand: CardBrand.visa,
      last4: '4242',
      expMonth: 12,
      expYear: 2026,
      isDefault: true,
    ),
    SavedPaymentMethod(
      id: 'pm-2',
      brand: CardBrand.mastercard,
      last4: '8888',
      expMonth: 3,
      expYear: 2027,
    ),
  ];

  // ── Notifications ─────────────────────────────────────────────────────

  static const mockNotifications = <NotificationItem>[
    NotificationItem(
      id: 'notif-1',
      type: 'RIDE_UPDATE',
      title: 'Ride Completed',
      body: 'Your ride from Sliema to Valletta has been completed',
      read: false,
      createdAt: '2026-02-22T10:30:00Z',
    ),
    NotificationItem(
      id: 'notif-2',
      type: 'PROMOTION',
      title: 'Weekend Bonus!',
      body: 'Earn 2x GoCoins on all rides this weekend',
      read: false,
      createdAt: '2026-02-21T08:00:00Z',
    ),
    NotificationItem(
      id: 'notif-3',
      type: 'PAYMENT',
      title: 'Payment Received',
      body: 'EUR 15.50 charged to Visa ****4242',
      read: true,
      createdAt: '2026-02-20T14:15:00Z',
    ),
  ];

  // ── Derived Constants ─────────────────────────────────────────────────

  static const int mockUnreadCount = 2;
}
