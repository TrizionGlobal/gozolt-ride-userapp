import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
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
import '../providers/auth_redirect_provider.dart';
import '../providers/storage_provider.dart';
import 'route_names.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final redirectNotifier = ref.watch(authRedirectProvider);
  final storage = ref.read(secureStorageProvider);

  return GoRouter(
    initialLocation: '/',
    restorationScopeId: 'router',
    debugLogDiagnostics: true,
    refreshListenable: redirectNotifier,
    redirect: (context, state) async {
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

      // ── Onboarding ─────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ── Welcome ────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
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
    ],
  );
});
