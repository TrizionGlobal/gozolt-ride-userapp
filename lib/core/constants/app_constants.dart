abstract final class AppConstants {
  // ── Dev Bypass ─────────────────────────────────────────
  /// Set to `true` to skip OTP verification and use a hardcoded test token.
  /// MUST be `false` before any release build.
  static const bool kDevBypass = bool.fromEnvironment('DEV_BYPASS', defaultValue: false);
  static const String kDevAccessToken = 'dev-token-placeholder';
  static const String kDevRefreshToken = 'dev-refresh-placeholder';
  static const String kDevPhone = '+35699000001';

  // ── Google Maps API ────────────────────────────────────
  static const String googleMapsApiKey = 'AIzaSyCSwSCRQUTql_5bowO2-GiBMl4H8No0ZY4';

  // ── Splash ─────────────────────────────────────────────
  static const Duration splashDuration = Duration(milliseconds: 2500);

  // ── Onboarding ─────────────────────────────────────────
  static const int onboardingPageCount = 3;

  // ── OTP ────────────────────────────────────────────────
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;

  // ── Stripe ────────────────────────────────────────────
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PK',
    defaultValue: 'pk_test_51RYXLLPM5zo65HVyj5vNSB4z2awbPt8oemY8tgJQ7Kepb6SaR1XVd0a5tmbJuqhGgTYH0wnewoSqlcEJXzwhQQht00hpMFVH1g',
  );

  // ── Location Config ───────────────────────────────────
  /// Set to false before Malta production launch. One-line switch.
  static const bool isTestMode = false;
  static const double defaultLat = isTestMode ? 17.385 : 35.8989;
  static const double defaultLng = isTestMode ? 78.4867 : 14.5146;
  static const String defaultCity = isTestMode ? 'Hyderabad' : 'Valletta';

  // ── App Info ───────────────────────────────────────────
  static const String appName = 'Gozolt';
  static const String appTagline = 'THE SUPER APP';
  static const String defaultCountryCode = '+356';
  static const String defaultCountry = 'MT';
  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'EUR';
  static const String currencySymbol = '€';

  // ── Timeouts ───────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
