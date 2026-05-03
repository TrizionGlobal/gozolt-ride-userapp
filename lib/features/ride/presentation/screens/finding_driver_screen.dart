import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/router/route_names.dart';
import '../providers/active_ride_provider.dart';
import '../providers/ride_booking_state.dart';
import '../providers/ride_providers.dart';

class FindingDriverScreen extends ConsumerStatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  ConsumerState<FindingDriverScreen> createState() =>
      _FindingDriverScreenState();
}

class _FindingDriverScreenState extends ConsumerState<FindingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _radarController;
  Timer? _timeoutTimer;
  StreamSubscription<Map<String, dynamic>>? _rideAcceptedSub;
  StreamSubscription<Map<String, dynamic>>? _noDriverSub;

  static const _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#181818"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Auto-timeout after 30 seconds
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _showNoDriversDialog();
      }
    });

    // Connect socket and listen for ride acceptance
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final socketService = ref.read(socketServiceProvider);
    await socketService.connect();

    // Join the ride room if we have a ride ID
    final booking = ref.read(rideBookingProvider);
    if (booking.createdRideId != null) {
      socketService.joinRide(booking.createdRideId!);
    }

    // Listen for driver acceptance
    _rideAcceptedSub = socketService.onRideAccepted.listen((data) async {
      if (!mounted) return;
      _timeoutTimer?.cancel();

      // Get the stored OTP from booking state
      final bookingState = ref.read(rideBookingProvider);
      final otp = bookingState.createdRideOtp ?? '';

      // Pass OTP in the event data
      await ref.read(activeRideProvider.notifier).initFromSocketEvent({
        ...data,
        'otp': otp,
      });

      // Navigate to active ride screen
      if (mounted) context.goNamed(RouteNames.rideActive);
    });

    // Listen for explicit no-driver event from backend
    _noDriverSub = socketService.onRideStatusUpdate.listen((data) {
      if (!mounted) return;
      if (data['status'] == 'NO_DRIVER') {
        _timeoutTimer?.cancel();
        _showNoDriversDialog();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    _timeoutTimer?.cancel();
    _rideAcceptedSub?.cancel();
    _noDriverSub?.cancel();
    super.dispose();
  }

  void _cancelRequest() {
    ref.read(rideBookingProvider.notifier).cancelFindingDriver();
    context.goNamed(RouteNames.home);
  }

  void _retry() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _showNoDriversDialog();
    });
    ref.read(rideBookingProvider.notifier).confirmBooking();
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(rideBookingProvider);

    // If booking status changed to scheduled, show confirmation and pop
    if (booking.status == BookingStatus.scheduled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showScheduledConfirmation();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Google Map ─────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: booking.pickup != null
                    ? LatLng(booking.pickup!.latitude, booking.pickup!.longitude)
                    : LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
                zoom: 15,
              ),
              style: _darkMapStyle,
              markers: booking.pickup != null
                  ? {
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: LatLng(
                          booking.pickup!.latitude,
                          booking.pickup!.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange),
                        infoWindow:
                            InfoWindow(title: booking.pickup!.address),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),

          // ── Radar Ripple + Pin ───────────────────────────
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple circles
                      for (int i = 0; i < 3; i++)
                        _buildRipple((_radarController.value + i * 0.33) % 1.0),
                      // Center pin
                      Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryGold,
                          size: 48,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Bottom Sheet ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _buildSearchingContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double progress) {
    final size = 40 + (160 * progress);
    final opacity = (1.0 - progress).clamp(0.0, 0.6);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildSearchingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Illustration
        Image.asset(
          AssetPaths.illustrationFindingDriver,
          width: 180,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Icon(
                Icons.local_taxi,
                size: 80,
                color: AppColors.primaryGold
                    .withValues(alpha: 0.5 + _pulseController.value * 0.5),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Finding Your Driver...',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Searching for luxury rides nearby',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _cancelRequest,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderDark, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel Request',
              style: AppTextStyles.button
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  void _showNoDriversDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              'No Drivers Available',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find a driver near your pickup location. You can retry, change your pickup, or try again later.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _retry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(rideBookingProvider.notifier).cancelFindingDriver();
                  context.goNamed(RouteNames.searchDestination);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  side: const BorderSide(color: AppColors.primaryGold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Change Pickup Location'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(rideBookingProvider.notifier).cancelFindingDriver();
                  context.goNamed(RouteNames.home);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try Later'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduledConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.success, size: 56),
            const SizedBox(height: 16),
            Text(
              'Ride Scheduled!',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ride has been scheduled successfully.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(rideBookingProvider.notifier).reset();
                  context.goNamed(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Go to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
