import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/startup_provider.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/app_version_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:io';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _initialize();
  }

  Future<void> _initialize() async {
    // Hard fail-safe: Force navigation after 6 seconds no matter what
    Future.delayed(const Duration(seconds: 6)).then((_) async {
      if (mounted && !_navigated) {
        debugPrint('SplashScreen: Hard fail-safe triggered');
        final hasTokens = await ref.read(secureStorageProvider).hasTokens();
        if (hasTokens) {
          _navigate(RouteNames.home);
        } else {
          _navigate(RouteNames.onboarding);
        }
      }
    });

    // Normal flow
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted || _navigated) return;

    final storage = ref.read(secureStorageProvider);

    bool hasTokens = false;
    bool hasSeenOnboarding = false;
    try {
      hasTokens = await storage.hasTokens();
      hasSeenOnboarding = await storage.hasSeenOnboarding();
    } catch (_) {
      // Storage corrupted — treat as logged out
      await storage.clearAll();
    }
    
    // Mark as initialized so GoRouter knows it can proceed to other routes
    ref.read(startupProvider).markInitialized();

    if (!mounted || _navigated) return;

    // --- Version Check ---
    final versionService = ref.read(appVersionServiceProvider);
    final config = await versionService.fetchAppVersionConfig();
    
    if (config != null) {
      final requiresUpdate = await versionService.isUpdateRequired(config.minimumVersion);
      if (requiresUpdate) {
        if (mounted && !_navigated) {
          setState(() => _navigated = true);
          context.go('/force-update', extra: {
            'iosStoreUrl': config.iosStoreUrl,
            'androidStoreUrl': config.androidStoreUrl,
          });
        }
        return;
      }
    }
    // ----------------------

    if (hasTokens) {
      // Check if profile is complete before going to home
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.get('/users/me');
        final data = response.data as Map<String, dynamic>?;
        final firstName = data?['firstName'] as String?;
        final termsAccepted = data?['termsAcceptedAt'];

        if (!mounted || _navigated) return;

        if (firstName == null || firstName.isEmpty || termsAccepted == null) {
          // Profile incomplete → send to complete profile
          _navigate(RouteNames.completeProfile);
          return;
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 404) {
          // User account was likely deleted or not found
          await storage.clearTokens();
          if (!mounted || _navigated) return;
          if (hasSeenOnboarding) {
            _navigate(RouteNames.welcome);
          } else {
            _navigate(RouteNames.onboarding);
          }
          return;
        }

        // API call failed — check if tokens were cleared (401 → interceptor cleared them)
        if (!mounted || _navigated) return;
        final stillHasTokens = await storage.hasTokens();
        if (!stillHasTokens) {
          // Tokens were invalidated — redirect to login
          if (hasSeenOnboarding) {
            _navigate(RouteNames.welcome);
          } else {
            _navigate(RouteNames.onboarding);
          }
          return;
        }
        // Tokens still exist but API failed (network issue, etc.) — proceed to home
      }
      
      if (!mounted || _navigated) return;
      // Force fresh profile/data fetch for the new session
      ref.invalidate(userProfileProvider);
      ref.invalidate(savedAddressesProvider);
      ref.invalidate(unreadNotificationCountProvider);
      
      String? intendedRoute = GoRouterState.of(context).uri.queryParameters['from'];
      if (intendedRoute == '/force-update') {
        intendedRoute = RouteNames.home;
      }
      _navigate(intendedRoute ?? RouteNames.home);
    } else if (hasSeenOnboarding) {
      // User has seen onboarding but is logged out → show login/register
      _navigate(RouteNames.welcome);
    } else {
      // First-time user → show onboarding
      _navigate(RouteNames.onboarding);
    }
  }

  void _navigate(String route) {
    if (_navigated || !mounted) return;
    setState(() => _navigated = true);

    if (route == RouteNames.splash) {
      route = RouteNames.home;
    }

    // We use context.go to ensure the route stack is replaced
    if (route.startsWith('/')) {
      context.go(route);
    } else {
      context.goNamed(route);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.white,
      body: const SafeArea(
        child: Center(
          child: _SplashContent(),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Image.asset(
      isDark
          ? 'assets/images/gozolt_logo_with_text.png'
          : 'assets/images/light_gozolt_logo_with_text.png',
      width: 250,
      fit: BoxFit.contain,
    );
  }
}
