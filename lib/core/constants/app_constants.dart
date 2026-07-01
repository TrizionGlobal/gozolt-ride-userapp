abstract final class AppConstants {
  // ── Google Maps API ────────────────────────────────────
  static const String googleMapsApiKey = 'AIzaSyCSwSCRQUTql_5bowO2-GiBMl4H8No0ZY4';

  // ── Splash ─────────────────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 1700);

  // ── Onboarding ─────────────────────────────────────────
  static const int onboardingPageCount = 3;

  // ── OTP ────────────────────────────────────────────────
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;

  // ── Stripe ────────────────────────────────────────────
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PK',
    defaultValue: 'pk_live_51RhyquLppOyXcfaxlpBULfNGVCeGeWJcBptsxFG9MXtMY2m1RFCQBL83Do6KPLLcNFqRcFlDg6od7FQ52pK0uJCm00EVV3XnHO',
  );

  // ── Location Config ───────────────────────────────────
  static const double defaultLat = 35.8989;
  static const double defaultLng = 14.5146;
  static const String defaultCity = 'Valletta';

  // ── App Info ───────────────────────────────────────────
  static const String appName = 'Gozolt';
  static const String appTagline = 'THE SUPER APP';
  static const String defaultCountryCode = '+356';
  static const String defaultCountry = 'MT';
  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'EUR';
  static const String currencySymbol = '€';

  // ── Timeouts ───────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
