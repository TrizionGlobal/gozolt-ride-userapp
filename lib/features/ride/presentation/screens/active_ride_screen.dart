import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/active_ride_provider.dart';
import '../providers/active_ride_state.dart';
import '../widgets/driver_en_route_view.dart';
import '../widgets/driver_arrived_view.dart';
import '../widgets/ride_in_progress_view.dart';
import '../widgets/ride_status_bar.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/cancel_ride_sheet.dart';
import '../widgets/change_destination_sheet.dart';
import '../widgets/ride_details_sheet.dart';
import '../widgets/share_ride_sheet.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  static final _defaultCenter = LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _dropoffIcon;

  // Cached route points from Google Directions API
  List<LatLng>? _driverToPickupRoute;
  List<LatLng>? _driverToDropoffRoute;
  String? _lastRouteKey; // track which route we last fetched

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

  Set<Marker> _buildMarkers(ActiveRideState rideState) {
    final markers = <Marker>{};
    if (rideState.ride == null) return markers;
    final ride = rideState.ride!;

    // Driver marker — white car with heading rotation
    if (rideState.driverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(
          rideState.driverLocation!.latitude,
          rideState.driverLocation!.longitude,
        ),
        icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        rotation: rideState.driverLocation!.heading ?? 0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: InfoWindow(title: rideState.driverInfo?.name ?? 'Driver'),
      ));
    }

    // User/Pickup marker — golden arrowhead
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(ride.pickupLat, ride.pickupLng),
      icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: ride.pickupAddress),
    ));

    // Dropoff marker — green flag
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(ride.dropoffLat, ride.dropoffLng),
      icon: _dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      anchor: const Offset(0.5, 1.0),
      infoWindow: InfoWindow(title: ride.dropoffAddress),
    ));

    return markers;
  }

  Future<void> _fetchDirectionsRoute(LatLng origin, LatLng destination, {required bool isPickupRoute}) async {
    final routeKey = '${isPickupRoute ? 'pickup' : 'dropoff'}_${origin.latitude.toStringAsFixed(3)},${origin.longitude.toStringAsFixed(3)}_${destination.latitude.toStringAsFixed(3)},${destination.longitude.toStringAsFixed(3)}';
    if (_lastRouteKey == routeKey) return;
    _lastRouteKey = routeKey;

    try {
      final dio = Dio();
      // Use OSRM (free, no API key needed) for road-following routes
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=polyline';

      final response = await dio.get(url);
      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['code'] == 'Ok' &&
          (data['routes'] as List).isNotEmpty) {
        final encodedPolyline = data['routes'][0]['geometry'] as String;
        final points = _decodePolyline(encodedPolyline);
        if (mounted) {
          setState(() {
            if (isPickupRoute) {
              _driverToPickupRoute = points;
            } else {
              _driverToDropoffRoute = points;
            }
          });
        }
      } else {
        debugPrint('OSRM route error: ${data is Map ? data['code'] : 'unknown'}');
      }
    } catch (e) {
      debugPrint('Route fetch failed: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Set<Polyline> _buildPolylines(ActiveRideState rideState) {
    final polylines = <Polyline>{};
    if (rideState.ride == null || rideState.driverLocation == null) {
      return polylines;
    }
    final ride = rideState.ride!;
    final driverPos = LatLng(
      rideState.driverLocation!.latitude,
      rideState.driverLocation!.longitude,
    );

    if (rideState.status == ActiveRideStatus.driverEnRoute) {
      final pickupPos = LatLng(ride.pickupLat, ride.pickupLng);
      final routePoints = _driverToPickupRoute ?? [driverPos, pickupPos];
      polylines.add(Polyline(
        polylineId: const PolylineId('driverToPickup'),
        points: routePoints,
        color: AppColors.primaryGold,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
      // Fetch route if not cached
      if (_driverToPickupRoute == null) {
        _fetchDirectionsRoute(driverPos, pickupPos, isPickupRoute: true);
      }
    } else if (rideState.status == ActiveRideStatus.inProgress) {
      final dropoffPos = LatLng(ride.dropoffLat, ride.dropoffLng);
      final routePoints = _driverToDropoffRoute ?? [driverPos, dropoffPos];
      polylines.add(Polyline(
        polylineId: const PolylineId('toDropoff'),
        points: routePoints,
        color: const Color(0xFF4CAF50),
        width: 4,
      ));
      // Fetch route if not cached
      if (_driverToDropoffRoute == null) {
        _fetchDirectionsRoute(driverPos, dropoffPos, isPickupRoute: false);
      }
    }

    return polylines;
  }

  Future<void> _animateToBounds(LatLng a, LatLng b) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
    // Initialize the ride with the ride ID passed from finding driver screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideState = ref.read(activeRideProvider);
      if (rideState.ride == null) {
        ref.read(activeRideProvider.notifier).initializeRide('dev-ride-001');
      }
    });
  }

  Future<void> _createCustomMarkers() async {
    _carIcon = await _createCarIcon();
    _userIcon = await _createUserArrowIcon();
    _dropoffIcon = await _createDropoffIcon();
    if (mounted) setState(() {});
  }

  /// Small white car icon for driver (Uber-style, ~48px)
  Future<BitmapDescriptor> _createCarIcon() async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Subtle shadow
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      16,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // White circle
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      14,
      Paint()..color = Colors.white,
    );

    // Car body (top-down)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(size / 2, size / 2), width: 12, height: 18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2C2C2C),
    );

    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(size / 2, size / 2 - 4), width: 8, height: 4),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF5BA3E0),
    );

    // Rear window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(size / 2, size / 2 + 5), width: 7, height: 3),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF5BA3E0),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Small golden arrowhead for user (~40px)
  Future<BitmapDescriptor> _createUserArrowIcon() async {
    const size = 40.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Subtle glow
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 2,
      Paint()
        ..color = AppColors.primaryGold.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Golden arrowhead
    final path = Path()
      ..moveTo(size / 2, 6)
      ..lineTo(size / 2 + 10, size - 10)
      ..lineTo(size / 2, size - 14)
      ..lineTo(size / 2 - 10, size - 10)
      ..close();

    canvas.drawPath(path, Paint()
      ..color = AppColors.primaryGold
      ..style = PaintingStyle.fill);

    canvas.drawPath(path, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Small green flag/pin for dropoff (~44px)
  Future<BitmapDescriptor> _createDropoffIcon() async {
    const size = 44.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const green = Color(0xFF4CAF50);

    // Pin pole
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(size / 2, size / 2 + 6), width: 2.5, height: 22),
        const Radius.circular(1),
      ),
      Paint()..color = green,
    );

    // Flag
    final flagPath = Path()
      ..moveTo(size / 2 + 1, 6)
      ..lineTo(size / 2 + 14, 10)
      ..lineTo(size / 2 + 1, 18)
      ..close();
    canvas.drawPath(flagPath, Paint()..color = green);

    // Small circle at base
    canvas.drawCircle(
      Offset(size / 2, size - 5),
      3,
      Paint()..color = green,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(activeRideProvider);

    // If ride exists but driver info is missing, re-fetch from API
    if (rideState.ride != null && rideState.driverInfo == null && !rideState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeRideProvider.notifier).initFromSocketEvent({
          'rideId': rideState.ride!.id,
        });
      });
    }

    // Navigate on completion or cancellation, auto-zoom on status change
    ref.listen<ActiveRideState>(activeRideProvider, (prev, next) {
      if (next.isCompleted && prev?.isCompleted != true) {
        context.pushReplacementNamed(RouteNames.rideComplete);
      }
      if (next.isCancelled && prev?.isCancelled != true) {
        _showRideCancelledDialog();
      }
      // Clear cached route when status changes so new route is fetched
      if (prev?.status != next.status) {
        _lastRouteKey = null;
        if (next.status == ActiveRideStatus.inProgress) {
          _driverToPickupRoute = null;
        }
      }
      // Clear cached route when dropoff changes (destination change accepted)
      if (prev?.ride?.dropoffLat != next.ride?.dropoffLat ||
          prev?.ride?.dropoffLng != next.ride?.dropoffLng) {
        _driverToDropoffRoute = null;
        _lastRouteKey = null;
      }
      // Show error messages (e.g. destination change rejected by driver)
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        // Clear the error after showing
        ref.read(activeRideProvider.notifier).clearError();
      }
      // Auto-zoom map on status changes
      if (prev?.status != next.status && next.driverLocation != null && next.ride != null) {
        final driver = LatLng(next.driverLocation!.latitude, next.driverLocation!.longitude);
        LatLng target;
        if (next.status == ActiveRideStatus.driverEnRoute || next.status == ActiveRideStatus.driverArrived) {
          target = LatLng(next.ride!.pickupLat, next.ride!.pickupLng);
        } else {
          target = LatLng(next.ride!.dropoffLat, next.ride!.dropoffLng);
        }
        _animateToBounds(driver, target);
      }
    });

    if (rideState.isLoading && rideState.ride == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Map area
          Expanded(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: rideState.driverLocation != null
                        ? LatLng(
                            rideState.driverLocation!.latitude,
                            rideState.driverLocation!.longitude,
                          )
                        : _defaultCenter,
                    zoom: 15,
                  ),
                  style: _darkMapStyle,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _buildMarkers(rideState),
                  polylines: _buildPolylines(rideState),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),

                // Top bar with back + actions
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleButton(
                          icon: Icons.arrow_back,
                          onTap: () => context.goNamed(RouteNames.home),
                          semanticLabel: 'Go back',
                        ),
                        Row(
                          children: [
                            _buildCircleButton(
                              icon: Icons.info_outline,
                              onTap: () => _showRideDetails(context),
                              semanticLabel: 'Ride details',
                            ),
                            const SizedBox(width: 8),
                            _buildCircleButton(
                              icon: Icons.share_outlined,
                              onTap: () => _showShareSheet(context),
                              semanticLabel: 'Share ride',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom panel
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status bar
                    RideStatusBar(status: rideState.status),
                    const SizedBox(height: 16),

                    // Ride PIN display
                    if (rideState.otpPin != null &&
                        rideState.status != ActiveRideStatus.completed &&
                        rideState.status != ActiveRideStatus.cancelled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.primaryGold.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pin,
                                  color: AppColors.primaryGold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Ride PIN: ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                rideState.otpPin!,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Driver info card
                    if (rideState.driverInfo != null)
                      DriverInfoCard(
                        driverInfo: rideState.driverInfo!,
                        onCall: () => _callDriver(),
                        onMessage: () => _openChat(context),
                      ),
                    const SizedBox(height: 16),

                    // Status-specific content
                    _buildStatusContent(rideState),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(ActiveRideState rideState) {
    switch (rideState.status) {
      case ActiveRideStatus.driverEnRoute:
        return DriverEnRouteView(
          etaMinutes: rideState.etaMinutes ?? 0,
          onCancel: () => _showCancelSheet(context),
        );
      case ActiveRideStatus.driverArrived:
        return DriverArrivedView(
          otpPin: rideState.otpPin ?? '----',
        );
      case ActiveRideStatus.inProgress:
        // Calculate remaining distance
        double? remainingKm;
        if (rideState.driverLocation != null && rideState.ride != null) {
          remainingKm = _calcDistanceKm(
            rideState.driverLocation!.latitude,
            rideState.driverLocation!.longitude,
            rideState.ride!.dropoffLat,
            rideState.ride!.dropoffLng,
          );
        }
        return RideInProgressView(
          etaMinutes: rideState.etaMinutes ?? 0,
          remainingKm: remainingKm,
          dropoffAddress: rideState.ride?.dropoffAddress ?? 'Destination',
          onSos: () => _showSosConfirmation(context),
          onCancel: () => _showCancelSheet(context),
          onChangeDestination: () => _showChangeDestinationSheet(context),
        );
      case ActiveRideStatus.completed:
      case ActiveRideStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    final driver = ref.read(activeRideProvider).driverInfo;
    if (driver == null || driver.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number not available')),
      );
      return;
    }
    final uri = Uri.parse('tel:${driver.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openChat(BuildContext context) {
    final ride = ref.read(activeRideProvider).ride;
    if (ride == null) return;
    context.pushNamed(RouteNames.rideChat);
  }

  void _showRideDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RideDetailsSheet(),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareRideSheet(),
    );
  }

  void _showCancelSheet(BuildContext context) {
    final status = ref.read(activeRideProvider).status;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelRideSheet(currentStatus: status),
    );
  }

  void _showChangeDestinationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangeDestinationSheet(),
    );
  }

  void _showSosConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            Text('Emergency SOS',
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.error)),
          ],
        ),
        content: Text(
          'This will alert Gozolt safety team and allow you to call emergency services (112).\n\nAre you sure you want to proceed?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeRideProvider.notifier).triggerSos(AppConstants.defaultLat, AppConstants.defaultLng);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS alert sent. Calling 112...'),
                  backgroundColor: AppColors.error,
                ),
              );
              // In production: url_launcher to tel:112
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call 112'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRideCancelledDialog() {
    final reason = ref.read(activeRideProvider).cancelReason;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0x33E53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 12),
            const Text('Ride Cancelled', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(
          reason ?? 'Your ride has been cancelled.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(activeRideProvider.notifier).reset();
                context.goNamed(RouteNames.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Home', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(activeRideProvider.notifier).reset();
                context.goNamed(RouteNames.searchDestination);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderDark),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book Another Ride'),
            ),
          ),
        ],
      ),
    );
  }

  double _calcDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
