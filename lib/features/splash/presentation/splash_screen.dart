import 'dart:math';
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
import '../../home/presentation/providers/home_providers.dart';
import '../../../core/services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Wave fade-out animation
  late final AnimationController _waveController;
  late final Animation<double> _waveProgress;
  bool _startWaveOut = false;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _waveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Initialize notifications here so the UI is ready to handle permission popups
    ref.read(notificationServiceProvider).initialize();
    
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    // Start wave fade-out animation
    setState(() => _startWaveOut = true);
    _waveController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

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

    if (!mounted) return;

    if (hasTokens) {
      // Check if profile is complete before going to home
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.get('/users/me');
        final data = response.data as Map<String, dynamic>?;
        final firstName = data?['firstName'] as String?;
        final termsAccepted = data?['termsAcceptedAt'];

        if (!mounted) return;

        if (firstName == null || firstName.isEmpty || termsAccepted == null) {
          // Profile incomplete → send to complete profile
          context.goNamed(RouteNames.completeProfile);
          return;
        }
      } catch (_) {
        // API call failed — check if tokens were cleared (401 → interceptor cleared them)
        if (!mounted) return;
        final stillHasTokens = await storage.hasTokens();
        if (!stillHasTokens) {
          // Tokens were invalidated — redirect to login
          if (!mounted) return;
          if (hasSeenOnboarding) {
            context.goNamed(RouteNames.welcome);
          } else {
            context.goNamed(RouteNames.onboarding);
          }
          return;
        }
        // Tokens still exist but API failed (network issue, etc.) — proceed to home
      }
      if (!mounted) return;
      // Force fresh profile/data fetch for the new session
      ref.invalidate(userProfileProvider);
      ref.invalidate(savedAddressesProvider);
      ref.invalidate(unreadNotificationCountProvider);
      // If we are still on the splash screen path, proceed to home.
      // If GoRouter already restored us to a different page, don't force a redirect.
      if (GoRouterState.of(context).matchedLocation == '/') {
        context.goNamed(RouteNames.home);
      }
    } else if (hasSeenOnboarding) {
      // User has seen onboarding but is logged out → show login/register
      context.goNamed(RouteNames.welcome);
    } else {
      // First-time user → show onboarding
      context.goNamed(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              const Spacer(flex: 3),

              // ── Logo with text ─────────────────────
              Image.asset(
                isDark ? AssetPaths.gozoltLogoWithText : AssetPaths.gozoltLogoWithTextLight,
                width: 340,
                fit: BoxFit.contain,
              ),

              const Spacer(flex: 4),

              // ── Footer ───────────────────────────────
              _buildFooter(),

              const SizedBox(height: 40),
            ],
          ),

          // Wave fade-out overlay
          if (_startWaveOut)
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _WaveFadePainter(
                    progress: _waveProgress.value,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Born in Malta row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetPaths.maltaFlag, width: 22, height: 16),
            const SizedBox(width: 8),
            Text(
              'Born in Malta, Loved by Europe',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(AssetPaths.euFlag, width: 22, height: 16),
          ],
        ),

        const SizedBox(height: 10),

        // Powered by PRIMOOO
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Powered By ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            Text(
              'PRIMOOO',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryGold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Image.asset(AssetPaths.primoooLogo, width: 20, height: 20),
          ],
        ),
      ],
    );
  }
}

/// Paints a wave that sweeps from top to bottom, covering the screen
class _WaveFadePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveFadePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();
    // Wave sweeps down as progress goes 0→1
    final waveY = size.height * progress * 1.3;
    final waveAmplitude = 40.0 * (1.0 - progress); // wave flattens out

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, waveY - waveAmplitude);

    // Draw smooth wave curve
    for (double x = size.width; x >= 0; x -= 1) {
      final normalizedX = x / size.width;
      final y = waveY +
          sin(normalizedX * pi * 3 + progress * pi * 2) * waveAmplitude;
      path.lineTo(x, y);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveFadePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
