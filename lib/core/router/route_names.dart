abstract final class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String phoneEntry = 'phone-entry';
  static const String otp = 'otp';
  static const String completeProfile = 'complete-profile';
  // linkPhone: handled via bottom sheet, not a route

  // Shell tabs
  static const String home = 'home';
  static const String myRides = 'my-rides';
  static const String rewards = 'rewards';
  static const String account = 'account';

  // Ride flow
  static const String searchDestination = 'search-destination';
  static const String mapPinSelection = 'map-pin-selection';
  static const String rideBooking = 'ride-booking';
  static const String findingDriver = 'finding-driver';
  static const String rideActive = 'ride-active';
  static const String rideComplete = 'ride-complete';
  // rideDetail: use tripSummary instead
  static const String rideChat = 'ride-chat';
  // rideSos: handled via dialog, not a route
  // scheduleRide: handled via bottom sheet in fare_estimate_screen

  // Account sub-screens
  static const String editProfile = 'edit-profile';
  static const String savedPlaces = 'saved-places';
  static const String paymentMethods = 'payment-methods';
  static const String accountPaymentMethods = 'account-payment-methods';
  static const String notifications = 'notifications';
  static const String notificationPreferences = 'notification-preferences';
  static const String helpCenter = 'help-center';
  static const String privacyPolicy = 'privacy-policy';
  static const String terms = 'terms';
  static const String deleteAccount = 'delete-account';

  // Rewards sub-screens
  static const String rewardsInfo = 'rewards-info';
  // redeem: handled via bottom sheet
  // referral: handled via bottom sheet

  // Support
  static const String support = 'support';
  static const String createTicket = 'create-ticket';
  static const String ticketDetail = 'ticket-detail';

  // Trip Summary & Receipt
  static const String tripSummary = 'trip-summary';
  static const String receipt = 'receipt';
}
