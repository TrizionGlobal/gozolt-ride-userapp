# Gozolt User App

Ride-hailing user application for Malta/EU built with Flutter.

## Overview

Gozolt is a super app providing ride-hailing and transport services in Malta and the EU region. This is the user-facing mobile application that allows passengers to book rides, track drivers, manage payments, and earn rewards.

## Features

- **Onboarding** — Guided introduction screens for new users
- **Authentication** — Phone number login with OTP, Google Sign-In, and Sign in with Apple
- **Home** — Transport service grid, promo banners, saved addresses, and rewards overview
- **Ride Booking** — Search destinations, select vehicle type (Standard, Comfort, XL, Luxury, Accessible), view fare estimates, add stops, and apply promo codes
- **Active Ride** — Real-time driver tracking, driver info, ride status updates, in-ride chat, ride sharing, and cancellation
- **Finding Driver** — Animated driver matching screen
- **Ride History** — Past ride records with details
- **Rewards** — Tier-based rewards system (Bronze, Silver, Gold, Platinum), points earning/redemption, and referral program
- **Notifications** — Ride updates, promotions, and system notifications
- **Account Management** — Profile, saved payment methods, and settings

## Tech Stack

- **Framework:** Flutter 3.41+ / Dart 3.11+
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Networking:** Dio
- **Secure Storage:** Flutter Secure Storage
- **Local Storage:** Shared Preferences
- **Serialization:** Freezed + JSON Serializable
- **Social Login:** Google Sign-In, Sign in with Apple
- **UI:** Material Design 3, Shimmer loading, Cached Network Image

## Project Structure

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # App widget with ProviderScope & GoRouter
├── core/
│   ├── constants/             # Colors, text styles, API endpoints, asset paths
│   ├── theme/                 # App theme configuration
│   ├── network/               # API result wrapper
│   ├── storage/               # Secure storage service & keys
│   ├── providers/             # Global providers (Dio, storage, theme)
│   ├── router/                # Route names & configuration
│   └── widgets/               # Shared widgets (GozoltButton, etc.)
└── features/
    ├── splash/                # Splash screen
    ├── onboarding/            # Onboarding flow
    ├── auth/                  # Authentication (welcome, phone, OTP, social)
    ├── home/                  # Home screen & widgets
    ├── ride/                  # Ride booking, active ride, chat, driver matching
    ├── rewards/               # Rewards system, tiers, referrals
    ├── history/               # Ride history
    ├── notifications/         # Notifications
    └── account/               # Account management
```

Each feature follows a clean architecture pattern:
```
feature/
├── data/
│   ├── models/                # Data models (Freezed)
│   ├── datasources/           # Remote data sources (Dio)
│   └── repositories/          # Repository implementations
└── presentation/
    ├── providers/             # Riverpod providers & state
    ├── screens/               # Screen widgets
    └── widgets/               # Feature-specific widgets
```

## Getting Started

### Prerequisites

- Flutter SDK 3.41 or higher
- Dart SDK 3.11 or higher
- Android Studio / Xcode
- Android SDK (API 36) for Android builds
- Xcode 26+ for iOS builds

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/primooo-global-ltd/gozolt-new-userapp-repo.git
   cd gozolt-new-userapp-repo
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (for Freezed models):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   # Android
   flutter run

   # iOS
   cd ios && pod install && cd ..
   flutter run -d ios
   ```

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

- **API Base URL:** Configured in `lib/core/constants/api_constants.dart`
- **App Colors & Theme:** Configured in `lib/core/constants/app_colors.dart` and `lib/core/theme/app_theme.dart`
- **Android Package:** `com.gozolt.gozolt_user_app`
- **Min Android SDK:** Defined by Flutter defaults
- **iOS Deployment Target:** 13.0

## Future Integrations

The following are planned for upcoming phases (dependencies commented in `pubspec.yaml`):

- Google Maps (`google_maps_flutter`)
- Geolocation (`geolocator`)
- Real-time updates (`socket_io_client`)
- Stripe Payments (`flutter_stripe`)
- Image picker (`image_picker`)
- Share functionality (`share_plus`)
- Permission handling (`permission_handler`)
