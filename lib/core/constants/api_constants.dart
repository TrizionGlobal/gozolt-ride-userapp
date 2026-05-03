abstract final class ApiConstants {
  // ── Base URL ───────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gozolt-new-ride-backend-production.up.railway.app/v1',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://gozolt-new-ride-backend-production.up.railway.app',
  );

  // ── Auth ───────────────────────────────────────────────
  static const String checkPhone = '/auth/user/check-phone';
  static const String sendOtp = '/auth/user/send-otp';
  static const String verifyOtp = '/auth/user/verify-otp';
  static const String socialLogin = '/auth/user/social';
  static const String completeProfile = '/auth/user/complete-profile';
  static const String linkPhone = '/auth/user/link-phone';
  static const String verifyLinkPhone = '/auth/user/verify-link-phone';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ── User Profile ───────────────────────────────────────
  static const String userProfile = '/users/me';
  static const String userAvatar = '/users/me/avatar';
  static const String userExport = '/users/me/export';
  static const String userAddresses = '/users/me/addresses';
  static const String userPreferences = '/users/me/preferences';

  // ── Payment Methods ────────────────────────────────────
  static const String paymentMethods = '/users/me/payment-methods';
  static const String paymentSetupIntent = '/users/me/payment-methods/setup-intent';

  // ── Rides ──────────────────────────────────────────────
  static const String rideEstimate = '/rides/estimate';
  static const String rides = '/rides';
  static const String activeRide = '/rides/active';
  static const String rideHistory = '/rides/history';

  // ride actions use: /rides/:id/cancel, /rides/:id/stops, etc.
  static String rideById(String id) => '/rides/$id';
  static String rideCancel(String id) => '/rides/$id/cancel';
  static String rideStops(String id) => '/rides/$id/stops';
  static String rideSos(String id) => '/rides/$id/sos';
  static String rideShare(String id) => '/rides/$id/share';
  static String rideRate(String id) => '/rides/$id/rate';
  static String rideMessages(String rideId) => '/rides/$rideId/messages';
  static String rideTrack(String token) => '/rides/track/$token';

  // ── Payments ───────────────────────────────────────────
  static String paymentByRide(String rideId) => '/payments/ride/$rideId';

  // ── Promo ──────────────────────────────────────────────
  static const String promoValidate = '/promo/validate';

  // ── Rewards ────────────────────────────────────────────
  static const String rewardRules = '/users/me/rewards/rules';
  static const String rewardSummary = '/users/me/rewards';
  static const String rewardHistory = '/users/me/rewards/history';
  static const String rewardRedeem = '/users/me/rewards/redeem';
  static const String rewardReferral = '/users/me/rewards/referral';

  // ── Notifications ──────────────────────────────────────
  static const String notifications = '/users/me/notifications';
  static const String notificationsUnreadCount = '/users/me/notifications/unread-count';
  static const String notificationsMarkRead = '/users/me/notifications/mark-read';
  static const String notificationPreferences = '/users/me/notifications/preferences';

  // ── Support ────────────────────────────────────────────
  static const String supportTickets = '/support/tickets';
  static String supportTicketById(String id) => '/support/tickets/$id';
  static String supportTicketReplies(String id) => '/support/tickets/$id/replies';

  // ── Invoices ───────────────────────────────────────────
  static const String myInvoices = '/invoices/my';
  static String rideInvoice(String rideId) => '/invoices/ride/$rideId';
  static String rideInvoicePdf(String rideId) => '/invoices/ride/$rideId/pdf';

  // ── Ride Tip ─────────────────────────────────────────────
  static String rideTip(String id) => '/rides/$id/tip';

  // ── Ride Reschedule ──────────────────────────────────────
  static String rideReschedule(String id) => '/rides/$id/reschedule';

  // ── Ride Change Destination ─────────────────────────────
  static String rideChangeDestination(String id) => '/rides/$id/change-destination';

  // ── Helpers ───────────────────────────────────────────────
  static String fullUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = baseUrl.replaceAll('/v1', '');
    return '$base$path';
  }
}
