import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/quick_services/data/models/quick_service_history_model.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/splash/presentation/force_update_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/link_phone_screen.dart';
import '../../features/auth/presentation/screens/verify_link_phone_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/privacy_policy_screen.dart';
import '../../features/home/presentation/screens/navigation_shell.dart';
import '../../features/ride/presentation/screens/search_destination_screen.dart';
import '../../features/ride/presentation/screens/map_pin_selection_screen.dart';
import '../../features/ride/presentation/screens/fare_estimate_screen.dart';
import '../../features/ride/presentation/screens/payment_method_screen.dart';
import '../../features/ride/presentation/screens/active_ride_screen.dart';
import '../../features/ride/presentation/screens/ride_complete_screen.dart';
import '../../features/ride/presentation/screens/chat_screen.dart';
import '../../features/rewards/presentation/screens/rewards_info_screen.dart';
import '../../features/history/presentation/screens/trip_summary_screen.dart';
import '../../features/history/presentation/screens/quick_service_history_details_screen.dart';
import '../../features/history/presentation/screens/receipt_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/account/presentation/screens/edit_profile_screen.dart';
import '../../features/account/presentation/screens/saved_places_screen.dart';
import '../../features/account/presentation/screens/payment_methods_screen.dart';
import '../../features/account/presentation/screens/emergency_contacts_screen.dart';
import '../../features/account/presentation/screens/delete_account_screen.dart';
import '../../features/account/presentation/screens/help_center_screen.dart';
import '../../features/support/presentation/screens/ticket_list_screen.dart';
import '../../features/support/presentation/screens/create_ticket_screen.dart';
import '../../features/support/presentation/screens/ticket_detail_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_search_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_list_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_details_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_packages_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_addons_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_review_screen.dart';
import '../../features/car_rental/presentation/screens/car_rental_confirmation_screen.dart';
import '../../features/car_rental/domain/models/car_model.dart';
import '../../features/bike_rental/presentation/screens/bike_rental_search_screen.dart';
import '../../features/bike_rental/presentation/screens/bike_rental_list_screen.dart';
import '../../features/bike_rental/presentation/screens/bike_rental_details_screen.dart';
import '../../features/bike_rental/presentation/screens/bike_rental_packages_screen.dart';
import '../../features/bike_rental/presentation/screens/bike_rental_review_screen.dart';
import '../../features/bike_rental/presentation/screens/bike_rental_confirmation_screen.dart';
import '../../features/bike_rental/domain/models/bike_model.dart';

// Quick Services
import '../../features/quick_services/presentation/screens/service_location_screen.dart';
import '../../features/quick_services/presentation/screens/quick_services_list_screen.dart';
import '../../features/quick_services/presentation/screens/shared_quick_service_confirmation_screen.dart';
import '../../features/quick_services/presentation/screens/shared_quick_service_failed_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/home_cleaning_details_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/home_cleaning_review_screen.dart';

import '../../features/quick_services/presentation/screens/home_services/plumbing_details_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/plumbing_review_screen.dart';

import '../../features/quick_services/presentation/screens/home_services/carpenter_details_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/carpenter_review_screen.dart';

import '../../features/quick_services/presentation/screens/appliance_repair/appliance_repair_details_screen.dart';
import '../../features/quick_services/presentation/screens/appliance_repair/appliance_repair_review_screen.dart';

import '../../features/quick_services/presentation/screens/vehicle_mechanic/bike_mechanic_details_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_mechanic/bike_mechanic_review_screen.dart';

import '../../features/quick_services/presentation/screens/vehicle_mechanic/car_mechanic_details_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_mechanic/car_mechanic_review_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_mechanic/truck_mechanic_details_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_mechanic/truck_mechanic_review_screen.dart';

import '../../features/quick_services/presentation/screens/electrical_mechanic/lift_elevator_mechanic_details_screen.dart';
import '../../features/quick_services/presentation/screens/electrical_mechanic/lift_elevator_mechanic_review_screen.dart';

import '../../features/quick_services/presentation/screens/electrical_mechanic/home_electric_details_screen.dart';
import '../../features/quick_services/presentation/screens/electrical_mechanic/home_electric_review_screen.dart';
import '../../features/quick_services/presentation/screens/electrical_mechanic/events_electric_details_screen.dart';
import '../../features/quick_services/presentation/screens/electrical_mechanic/events_electric_review_screen.dart';



import '../../features/quick_services/presentation/screens/hire_person/hire_person_details_screen.dart';
import '../../features/quick_services/presentation/screens/hire_person/hire_person_review_screen.dart';

import '../../features/quick_services/presentation/screens/security_personnel/security_personnel_details_screen.dart';
import '../../features/quick_services/presentation/screens/security_personnel/security_personnel_review_screen.dart';

import '../../features/quick_services/presentation/screens/pc_mobile/mobile_repair_details_screen.dart';
import '../../features/quick_services/presentation/screens/pc_mobile/mobile_repair_review_screen.dart';

import '../../features/quick_services/presentation/screens/pc_mobile/computer_repair_details_screen.dart';
import '../../features/quick_services/presentation/screens/pc_mobile/computer_repair_review_screen.dart';

import '../../features/quick_services/presentation/screens/vehicle_wash/car_wash_details_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_wash/car_wash_review_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_wash/truck_wash_details_screen.dart';
import '../../features/quick_services/presentation/screens/vehicle_wash/truck_wash_review_screen.dart';

import '../../features/quick_services/presentation/screens/laundry_worker/laundry_details_screen.dart';
import '../../features/quick_services/presentation/screens/laundry_worker/hospital_laundry_details_screen.dart';
import '../../features/quick_services/presentation/screens/laundry_worker/hotel_laundry_details_screen.dart';
import '../../features/quick_services/presentation/screens/laundry_worker/commercial_laundry_details_screen.dart';
import '../../features/quick_services/presentation/screens/laundry_worker/laundry_review_screen.dart';

import '../../features/quick_services/presentation/screens/other_services/painter_details_screen.dart';
import '../../features/quick_services/presentation/screens/other_services/event_organisers_details_screen.dart';
import '../../features/quick_services/presentation/screens/other_services/suppliers_details_screen.dart';
import '../../features/quick_services/presentation/screens/other_services/other_services_review_screen.dart';

import '../../features/quick_services/presentation/screens/beauty_wellness/beauty_wellness_details_screen.dart';
import '../../features/quick_services/presentation/screens/beauty_wellness/beauty_wellness_review_screen.dart';

import '../../features/quick_services/presentation/screens/home_services/gardening_details_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/gardening_review_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/pest_control_details_screen.dart';
import '../../features/quick_services/presentation/screens/home_services/pest_control_review_screen.dart';
import '../../features/quick_services/presentation/screens/pc_mobile/printer_scanner_details_screen.dart';
import '../../features/quick_services/presentation/screens/pc_mobile/printer_scanner_review_screen.dart';

import '../../features/quick_services/data/models/quick_service_booking_data.dart';
import '../../features/ride/data/models/location_data.dart';
import '../providers/auth_redirect_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/theme_provider.dart';
import '../router/startup_provider.dart';
import 'route_names.dart';

final _dummyBookingData = QuickServiceBookingData(
  scheduleDate: DateTime.now(),
  scheduleTime: const TimeOfDay(hour: 10, minute: 0),
  location: const LocationData(
    latitude: 35.8989,
    longitude: 14.5146,
    address: '22 Triq il-Kbira, Sliema, Malta',
  ),
  userName: 'Test User',
  userPhone: '+356 7712 3456',
  userEmail: 'test@example.com',
);

final routerProvider = Provider<GoRouter>((ref) {
  final redirectNotifier = ref.read(authRedirectProvider);
  final startupNotifier = ref.read(startupProvider);
  final storage = ref.read(secureStorageProvider);

  final prefs = ref.read(sharedPrefsProvider);
  final lastRoute = prefs.getString('last_route');

  final router = GoRouter(
    initialLocation: lastRoute ?? '/',
    restorationScopeId: 'router',
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([startupNotifier, redirectNotifier]),
    redirect: (context, state) async {
      final isInitialized = startupNotifier.value;
      final isGoingToSplash = state.uri.path == '/';

      if (!isInitialized && !isGoingToSplash) {
        // If not initialized and trying to go somewhere else (like when OS restores app),
        // intercept and go to splash, remembering where they wanted to go.
        return '/?from=${state.uri.path}';
      }

      if (!isInitialized) return null;

      if (state.matchedLocation == '/force-update') {
        return null;
      }

      final hasTokens = await storage.hasTokens();
      final hasSeenOnboarding = await storage.hasSeenOnboarding();

      final isAuthPath = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/phone-entry' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/complete-profile' ||
          state.matchedLocation == '/';

      if (!hasTokens) {
        if (!isAuthPath) {
          return hasSeenOnboarding ? '/welcome' : '/onboarding';
        }
        return null;
      }

      // If logged in and on an auth page, go home (unless it's splash or onboarding)
      if (hasTokens && isAuthPath && state.matchedLocation != '/' && state.matchedLocation != '/onboarding' && state.matchedLocation != '/complete-profile') {
        return '/home';
      }

      return null;
    },
    routes: [
      // ── Splash ─────────────────────────────────────────
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/force-update',
        name: 'forceUpdate',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return ForceUpdateScreen(
            iosStoreUrl: extras['iosStoreUrl'] ?? '',
            androidStoreUrl: extras['androidStoreUrl'] ?? '',
          );
        },
      ),

      // ── Onboarding ─────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Welcome ────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // ── Login (alias → welcome) ────────────────────────
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ── Phone Entry ────────────────────────────────────
      GoRoute(
        path: '/phone-entry',
        name: RouteNames.phoneEntry,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneEntryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── OTP ────────────────────────────────────────────
      GoRoute(
        path: '/otp',
        name: RouteNames.otp,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OtpScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Link Phone ─────────────────────────────────────
      GoRoute(
        path: '/link-phone',
        name: RouteNames.linkPhone,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LinkPhoneScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Verify Link Phone ──────────────────────────────
      GoRoute(
        path: '/verify-link-phone',
        name: RouteNames.verifyLinkPhone,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VerifyLinkPhoneScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Complete Profile ───────────────────────────────
      GoRoute(
        path: '/complete-profile',
        name: RouteNames.completeProfile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CompleteProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Privacy Policy ─────────────────────────────────
      GoRoute(
        path: '/privacy-policy',
        name: RouteNames.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // ── Terms of Service ───────────────────────────────
      GoRoute(
        path: '/terms',
        name: RouteNames.terms,
        builder: (context, state) => const PrivacyPolicyScreen(isTerms: true),
      ),

      // ── Home (Navigation Shell with 4 tabs) ─────────────
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const NavigationShell(),
      ),

      // ── Ride Booking Flow ─────────────────────────────────

      GoRoute(
        path: '/search-destination',
        name: RouteNames.searchDestination,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchDestinationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/map-pin-selection',
        name: RouteNames.mapPinSelection,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MapPinSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/ride-booking',
        name: RouteNames.rideBooking,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FareEstimateScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/payment-methods-select',
        name: RouteNames.paymentMethods,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PaymentMethodScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Active Ride Experience ──────────────────────────────

      GoRoute(
        path: '/ride-active',
        name: RouteNames.rideActive,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ActiveRideScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      GoRoute(
        path: '/ride-complete',
        name: RouteNames.rideComplete,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RideCompleteScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      GoRoute(
        path: '/ride-chat',
        name: RouteNames.rideChat,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Rewards ─────────────────────────────────────────

      GoRoute(
        path: '/rewards-info',
        name: RouteNames.rewardsInfo,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RewardsInfoScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Trip Summary ────────────────────────────────────

      GoRoute(
        path: '/quick-service-history-details',
        name: RouteNames.quickServiceHistoryDetails,
        pageBuilder: (context, state) {
          final booking = state.extra as QuickServiceHistoryModel;
          return CustomTransitionPage(
            key: state.pageKey,
            child: QuickServiceHistoryDetailsScreen(booking: booking),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),

      GoRoute(
        path: '/trip-summary',
        name: RouteNames.tripSummary,
        pageBuilder: (context, state) {
          final rideId = state.extra as String? ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: TripSummaryScreen(rideId: rideId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),

      // ── Receipt ────────────────────────────────────

      GoRoute(
        path: '/receipt',
        name: RouteNames.receipt,
        pageBuilder: (context, state) {
          final rideId = state.extra as String? ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ReceiptScreen(rideId: rideId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),

      // ── Notifications ───────────────────────────────────

      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/notification-preferences',
        name: RouteNames.notificationPreferences,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationPreferencesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      // ── Account Sub-screens ─────────────────────────────

      GoRoute(
        path: '/edit-profile',
        name: RouteNames.editProfile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/saved-places',
        name: RouteNames.savedPlaces,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SavedPlacesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/account-payment-methods',
        name: RouteNames.accountPaymentMethods,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PaymentMethodsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/emergency-contacts',
        name: RouteNames.emergencyContacts,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmergencyContactsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/delete-account',
        name: RouteNames.deleteAccount,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DeleteAccountScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/help-center',
        name: RouteNames.helpCenter,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HelpCenterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),
      // ── Support Tickets ─────────────────────────────────

      GoRoute(
        path: '/support',
        name: RouteNames.support,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TicketListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),

      GoRoute(
        path: '/create-ticket',
        name: RouteNames.createTicket,
        pageBuilder: (context, state) {
          final rideId = state.extra as String?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CreateTicketScreen(rideId: rideId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),

      GoRoute(
        path: '/ticket-detail',
        name: RouteNames.ticketDetail,
        pageBuilder: (context, state) {
          final ticketId = state.extra as String? ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: TicketDetailScreen(ticketId: ticketId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/car-rental-search',
        name: RouteNames.carRentalSearch,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CarRentalSearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/car-rental-list',
        name: RouteNames.carRentalList,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CarRentalListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/car-rental-details',
        name: RouteNames.carRentalDetails,
        pageBuilder: (context, state) {
          final car = state.extra as CarModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CarRentalDetailsScreen(car: car),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: '/car-rental-packages',
        name: RouteNames.carRentalPackages,
        pageBuilder: (context, state) {
          final car = state.extra as CarModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CarRentalPackagesScreen(car: car),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/car-rental-addons',
        name: RouteNames.carRentalAddons,
        pageBuilder: (context, state) {
          final car = state.extra as CarModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CarRentalAddonsScreen(car: car),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/car-rental-review',
        name: RouteNames.carRentalReview,
        pageBuilder: (context, state) {
          final car = state.extra as CarModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CarRentalReviewScreen(car: car),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/car-rental-confirmation',
        name: RouteNames.carRentalConfirmation,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final car = extra['car'] as CarModel?;
          final bookingId = extra['bookingId'] as String?;
          final earnedCoins = extra['earnedCoins'] as int?;
          final totalAmount = extra['totalAmount'] as double?;
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: CarRentalConfirmationScreen(car: car, bookingId: bookingId, earnedCoins: earnedCoins, totalAmount: totalAmount),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      // ── Bike Rental ─────────────────────────────────────
      GoRoute(
        path: '/bike-rental-search',
        name: RouteNames.bikeRentalSearch,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BikeRentalSearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/bike-rental-list',
        name: RouteNames.bikeRentalList,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BikeRentalListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/bike-rental-details',
        name: RouteNames.bikeRentalDetails,
        pageBuilder: (context, state) {
          final bike = state.extra as BikeModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BikeRentalDetailsScreen(bike: bike),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: '/bike-rental-packages',
        name: RouteNames.bikeRentalPackages,
        pageBuilder: (context, state) {
          final bike = state.extra as BikeModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BikeRentalPackagesScreen(bike: bike),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/bike-rental-review',
        name: RouteNames.bikeRentalReview,
        pageBuilder: (context, state) {
          final bike = state.extra as BikeModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BikeRentalReviewScreen(bike: bike),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: '/bike-rental-confirmation',
        name: RouteNames.bikeRentalConfirmation,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final bike = extra['bike'] as BikeModel?;
          final bookingId = extra['bookingId'] as String?;
          final earnedCoins = extra['earnedCoins'] as int?;
          final totalAmount = extra['totalAmount'] as double?;
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: BikeRentalConfirmationScreen(bike: bike, bookingId: bookingId, earnedCoins: earnedCoins, totalAmount: totalAmount),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),

      // ── Quick Services ──────────────────────────────────────
      GoRoute(
        path: '/quick-services-location',
        name: RouteNames.quickServicesLocation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ServiceLocationScreen(
            bookingData: extra['bookingData'] as QuickServiceBookingData?,
            nextRoute: extra['nextRoute'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/quick-services-list',
        name: RouteNames.quickServicesList,
        builder: (context, state) => QuickServicesListScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-home-cleaning',
        name: RouteNames.quickServicesHomeCleaning,
        builder: (context, state) => HomeCleaningDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-home-cleaning-review',
        name: RouteNames.quickServicesHomeCleaningReview,
        builder: (context, state) => HomeCleaningReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-home-cleaning-confirmation',
        name: RouteNames.quickServicesHomeCleaningConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.cleaning_services, defaultTitle: 'Home Cleaning'),
      ),

      GoRoute(
        path: '/quick-services-plumbing',
        name: RouteNames.quickServicesPlumbing,
        builder: (context, state) => PlumbingDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-plumbing-review',
        name: RouteNames.quickServicesPlumbingReview,
        builder: (context, state) => PlumbingReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-plumbing-confirmation',
        name: RouteNames.quickServicesPlumbingConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.plumbing, defaultTitle: 'Plumbing'),
      ),

      GoRoute(
        path: '/quick-services-carpenter',
        name: RouteNames.quickServicesCarpenter,
        builder: (context, state) => CarpenterDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-carpenter-review',
        name: RouteNames.quickServicesCarpenterReview,
        builder: (context, state) => CarpenterReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-carpenter-confirmation',
        name: RouteNames.quickServicesCarpenterConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.carpenter, defaultTitle: 'Carpenter'),
      ),

      GoRoute(
        path: '/quick-services-appliance-repair',
        name: RouteNames.quickServicesApplianceRepair,
        builder: (context, state) => ApplianceRepairDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-appliance-repair-review',
        name: RouteNames.quickServicesApplianceRepairReview,
        builder: (context, state) => ApplianceRepairReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-appliance-repair-confirmation',
        name: RouteNames.quickServicesApplianceRepairConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.ac_unit, defaultTitle: 'AC & Appliance Repair'),
      ),
      GoRoute(
        path: '/quick-services-car-mechanic',
        name: RouteNames.quickServicesCarMechanic,
        builder: (context, state) => CarMechanicDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-car-mechanic-review',
        name: RouteNames.quickServicesCarMechanicReview,
        builder: (context, state) => CarMechanicReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-car-mechanic-confirmation',
        name: RouteNames.quickServicesCarMechanicConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.build, defaultTitle: 'Mechanic'),
      ),

      GoRoute(
        path: '/quick-services-bike-mechanic',
        name: RouteNames.quickServicesBikeMechanic,
        builder: (context, state) => BikeMechanicDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-bike-mechanic-review',
        name: RouteNames.quickServicesBikeMechanicReview,
        builder: (context, state) => BikeMechanicReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),

      GoRoute(
        path: '/quick-services-truck-mechanic',
        name: RouteNames.quickServicesTruckMechanic,
        builder: (context, state) => TruckMechanicDetailsScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-truck-mechanic-review',
        name: RouteNames.quickServicesTruckMechanicReview,
        builder: (context, state) => TruckMechanicReviewScreen(
          bookingData: state.extra as QuickServiceBookingData? ?? _dummyBookingData,
        ),
      ),
      GoRoute(
        path: '/quick-services-truck-mechanic-confirmation',
        name: RouteNames.quickServicesTruckMechanicConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.build, defaultTitle: 'Mechanic'),
      ),
      GoRoute(
        path: '/lift-elevator',
        name: RouteNames.quickServicesLiftElevator,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return LiftElevatorMechanicDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/lift-elevator-review',
        name: RouteNames.quickServicesLiftElevatorReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return LiftElevatorMechanicReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/lift-elevator-confirmation',
        name: RouteNames.quickServicesLiftElevatorConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.elevator, defaultTitle: 'Lift / Elevator');
        },
      ),
      GoRoute(
        path: '/electrical',
        name: RouteNames.quickServicesElectrical,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return HomeElectricDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/electrical-review',
        name: RouteNames.quickServicesElectricalReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return HomeElectricReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/electrical-confirmation',
        name: RouteNames.quickServicesElectricalConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.electrical_services, defaultTitle: 'Electrical');
        },
      ),
      GoRoute(
        path: '/events-electric',
        name: RouteNames.quickServicesEventsElectric,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return EventsElectricDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/events-electric-review',
        name: RouteNames.quickServicesEventsElectricReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return EventsElectricReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/events-electric-confirmation',
        name: RouteNames.quickServicesEventsElectricConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.event, defaultTitle: 'Events Electric');
        },
      ),

      GoRoute(
        path: '/hire-person',
        name: RouteNames.quickServicesHirePerson,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return HirePersonDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/hire-person-review',
        name: RouteNames.quickServicesHirePersonReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return HirePersonReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/hire-person-confirmation',
        name: RouteNames.quickServicesHirePersonConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.person_outline, defaultTitle: 'Hire a Person');
        },
      ),
      GoRoute(
        path: '/security-personnel',
        name: RouteNames.quickServicesSecurityPersonnel,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SecurityPersonnelDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/security-personnel-review',
        name: RouteNames.quickServicesSecurityPersonnelReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SecurityPersonnelReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/security-personnel-confirmation',
        name: RouteNames.quickServicesSecurityPersonnelConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.security, defaultTitle: 'Security Personnel');
        },
      ),
      GoRoute(
        path: '/mobile-repair',
        name: RouteNames.quickServicesMobileRepair,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return MobileRepairDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/mobile-repair-review',
        name: RouteNames.quickServicesMobileRepairReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return MobileRepairReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/mobile-repair-confirmation',
        name: RouteNames.quickServicesMobileRepairConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.smartphone, defaultTitle: 'Mobile Repair');
        },
      ),
      GoRoute(
        path: '/computer-repair',
        name: RouteNames.quickServicesComputerRepair,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return ComputerRepairDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/computer-repair-review',
        name: RouteNames.quickServicesComputerRepairReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return ComputerRepairReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/computer-repair-confirmation',
        name: RouteNames.quickServicesComputerRepairConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.laptop, defaultTitle: 'Computer Repair');
        },
      ),
      GoRoute(
        path: '/payment-failed',
        name: RouteNames.quickServicesPaymentFailed,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final bookingData = extra['bookingData'] as QuickServiceBookingData;
          final serviceIcon = extra['serviceIcon'] as IconData;
          final defaultTitle = extra['defaultTitle'] as String;
          final onRetrySuccessRouteName = extra['onRetrySuccessRouteName'] as String;
          return SharedQuickServiceFailedScreen(
            bookingData: bookingData,
            serviceIcon: serviceIcon,
            defaultTitle: defaultTitle,
            onRetrySuccessRouteName: onRetrySuccessRouteName,
          );
        },
      ),
      GoRoute(
        path: '/car-wash',
        name: RouteNames.quickServicesCarWash,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return CarWashDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/car-wash-review',
        name: RouteNames.quickServicesCarWashReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return CarWashReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/car-wash-confirmation',
        name: RouteNames.quickServicesCarWashConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.local_car_wash, defaultTitle: 'Vehicle Wash');
        },
      ),
      GoRoute(
        path: '/truck-wash',
        name: RouteNames.quickServicesTruckWash,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return TruckWashDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/truck-wash-review',
        name: RouteNames.quickServicesTruckWashReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return TruckWashReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/truck-wash-confirmation',
        name: RouteNames.quickServicesTruckWashConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.local_car_wash, defaultTitle: 'Vehicle Wash');
        },
      ),
      GoRoute(
        path: '/laundry-details',
        name: RouteNames.quickServicesLaundry,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return LaundryDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/hospital-laundry-details',
        name: RouteNames.quickServicesHospitalLaundry,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return HospitalLaundryDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/hotel-laundry-details',
        name: RouteNames.quickServicesHotelLaundry,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return HotelLaundryDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/commercial-laundry-details',
        name: RouteNames.quickServicesCommercialLaundry,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return CommercialLaundryDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/laundry-review',
        name: RouteNames.quickServicesLaundryReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return LaundryReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/laundry-confirmation',
        name: RouteNames.quickServicesLaundryConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.local_laundry_service, defaultTitle: 'Laundry');
        },
      ),
      GoRoute(
        path: '/painter',
        name: RouteNames.quickServicesPainter,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return PainterDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/event-organisers',
        name: RouteNames.quickServicesEventOrganisers,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return EventOrganisersDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/suppliers',
        name: RouteNames.quickServicesSuppliers,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SuppliersDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/other-services-review',
        name: RouteNames.quickServicesOtherServicesReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return OtherServicesReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/other-services-confirmation',
        name: RouteNames.quickServicesOtherServicesConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.miscellaneous_services, defaultTitle: 'Other Services');
        },
      ),
      GoRoute(
        path: '/beauty-wellness-details',
        name: RouteNames.quickServicesBeautyWellness,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return BeautyWellnessDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/beauty-wellness-review',
        name: RouteNames.quickServicesBeautyWellnessReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return BeautyWellnessReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/beauty-wellness-confirmation',
        name: RouteNames.quickServicesBeautyWellnessConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.spa, defaultTitle: 'Beauty & Wellness');
        },
      ),
      GoRoute(
        path: '/gardening-details',
        name: RouteNames.quickServicesGardening,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return GardeningDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/gardening-review',
        name: RouteNames.quickServicesGardeningReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return GardeningReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/gardening-confirmation',
        name: RouteNames.quickServicesGardeningConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.yard, defaultTitle: 'Gardening');
        },
      ),
      GoRoute(
        path: '/pest-control-details',
        name: RouteNames.quickServicesPestControl,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return PestControlDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/pest-control-review',
        name: RouteNames.quickServicesPestControlReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return PestControlReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/pest-control-confirmation',
        name: RouteNames.quickServicesPestControlConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.pest_control, defaultTitle: 'Pest Control');
        },
      ),
      GoRoute(
        path: '/printer-scanner-details',
        name: RouteNames.quickServicesPrinterScanner,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return PrinterScannerDetailsScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/printer-scanner-review',
        name: RouteNames.quickServicesPrinterScannerReview,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return PrinterScannerReviewScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/printer-scanner-confirmation',
        name: RouteNames.quickServicesPrinterScannerConfirmation,
        builder: (context, state) {
          final bookingData = state.extra as QuickServiceBookingData? ?? _dummyBookingData;
          return SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.print, defaultTitle: 'Printer / Scanner');
        },
      ),
      GoRoute(
        path: '/quick-services-bike-mechanic-confirmation',
        name: RouteNames.quickServicesBikeMechanicConfirmation,
        builder: (context, state) => SharedQuickServiceConfirmationScreen(bookingData: state.extra as QuickServiceBookingData, serviceIcon: Icons.build, defaultTitle: 'Mechanic'),
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    // Don't save transient/auth routes
    if (location != '/' &&
        location != '/welcome' &&
        location != '/login' &&
        location != '/phone-entry' &&
        location != '/otp' &&
        location != '/onboarding' &&
        location != '/complete-profile') {
      prefs.setString('last_route', location);
    }
  });

  return router;
});
