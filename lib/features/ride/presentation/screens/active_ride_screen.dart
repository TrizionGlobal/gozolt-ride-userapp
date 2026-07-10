import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/saved_payment_method.dart';
import '../providers/ride_providers.dart';
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
import '../widgets/safety_bottom_sheet.dart';
import '../widgets/contact_selection_sheet.dart';
import '../widgets/malta_emergency_sheet.dart';
import '../../../home/presentation/providers/home_providers.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  late AnimationController _posController;
  late AnimationController _rotController;
  LatLng? _oldPos;
  LatLng? _newPos;
  double _oldRot = 0;
  double _newRot = 0;
  double _selectedExtraFare = 0;
  late AnimationController _radarController;
  late AnimationController _pulseController;

  int _elapsedSearchTime = 0;
  int _searchingMessageIndex = 0;
  Timer? _searchingMessageTimer;
  final List<String> _searchingMessages = [
    'Contacting nearby drivers...',
    'Matching you with the best driver...',
    'Requesting drivers in your area...',
    'Still searching for a ride...',
    'Expanding search radius...',
    'Waiting for drivers to accept...',
  ];

  // Ghost cars
  List<LatLng> _ghostCarPositions = [];
  List<double> _ghostCarHeadings = [];
  Timer? _ghostCarTimer;
  final Random _random = Random();

  static final _defaultCenter = LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  bool _isMapReady = false;
  BitmapDescriptor? _carIconLight;
  BitmapDescriptor? _carIconDark;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _dropoffIcon;

  // Cached route points from Google Directions API
  List<LatLng>? _driverToPickupRoute;
  List<LatLng>? _driverToDropoffRoute;
  String? _lastRouteKey; // track which route we last fetched

  /// One-shot guard: only attempt to re-fetch missing driver info once per screen lifetime.
  bool _driverFetchAttempted = false;

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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final currentCarIcon = isDark ? _carIconDark : _carIconLight;
      final currentPos = _newPos ?? LatLng(rideState.driverLocation!.latitude, rideState.driverLocation!.longitude);
      final lerpPos = _oldPos != null
          ? LatLng(
              ui.lerpDouble(_oldPos!.latitude, _newPos!.latitude, _posController.value)!,
              ui.lerpDouble(_oldPos!.longitude, _newPos!.longitude, _posController.value)!,
            )
          : currentPos;

      final lerpRot = ui.lerpDouble(_oldRot, _newRot, _rotController.value) ?? _newRot;

      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: lerpPos,
        icon: currentCarIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        rotation: lerpRot,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: InfoWindow(title: rideState.driverInfo?.name ?? 'Driver'),
      ));
    }

    // User/Pickup marker — golden arrowhead
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(ride.pickupLat, ride.pickupLng),
      icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: ride.pickupAddress),
    ));

    // Dropoff marker — green flag
    markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(ride.dropoffLat, ride.dropoffLng),
      icon: _dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      anchor: const Offset(0.5, 1.0),
      infoWindow: InfoWindow(title: ride.dropoffAddress),
    ));

    // Ghost cars logic removed as per user request

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
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
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
        color: AppColors.primaryGold,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
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
    _posController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _posController.addListener(() => setState(() {}));
    _rotController.addListener(() => setState(() {}));

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _searchingMessageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        final state = ref.read(activeRideProvider);
        if (state.status == ActiveRideStatus.searching) {
          _elapsedSearchTime += 4;

          // Auto-cancel after 2.25 minutes (135s)
          if (_elapsedSearchTime >= 135) {
            timer.cancel();
            ref.read(activeRideProvider.notifier).cancelRide('All of our drivers are currently busy. Please try booking again in a few minutes.');
            return;
          }
        } else {
          // Reset timer counter if status is no longer searching
          _elapsedSearchTime = 0;
        }
      }
    });

    _ghostCarTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        final state = ref.read(activeRideProvider);
        if (state.status == ActiveRideStatus.searching && state.ride != null) {
          if (_ghostCarPositions.isEmpty) {
            // Initialize 3 ghost cars around the pickup location
            for(int i = 0; i < 3; i++) {
              double latOffset = (_random.nextDouble() - 0.5) * 0.015;
              double lngOffset = (_random.nextDouble() - 0.5) * 0.015;
              _ghostCarPositions.add(LatLng(state.ride!.pickupLat + latOffset, state.ride!.pickupLng + lngOffset));
              _ghostCarHeadings.add(_random.nextDouble() * 360);
            }
          }
          setState(() {
            for (int i = 0; i < _ghostCarPositions.length; i++) {
              double headingRad = _ghostCarHeadings[i] * pi / 180;
              double dist = 0.0003; // small distance per tick
              double newLat = _ghostCarPositions[i].latitude + dist * cos(headingRad);
              double newLng = _ghostCarPositions[i].longitude + dist * sin(headingRad);
              _ghostCarPositions[i] = LatLng(newLat, newLng);
              _ghostCarHeadings[i] += (_random.nextDouble() - 0.5) * 60; // turn slightly
            }
          });
        } else if (state.status != ActiveRideStatus.searching && _ghostCarPositions.isNotEmpty) {
          _ghostCarPositions.clear();
          _ghostCarHeadings.clear();
        }
      }
    });

    _createCustomMarkers();
    // Initialize the ride with the ride ID passed from finding driver screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideState = ref.read(activeRideProvider);
      if (rideState.ride == null) {
        ref.read(activeRideProvider.notifier).initializeRide('dev-ride-001');
      }
    });
  }

  @override
  void dispose() {
    _searchingMessageTimer?.cancel();
    _ghostCarTimer?.cancel();
    _posController.dispose();
    _rotController.dispose();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createCustomMarkers() async {
    _carIconLight = await _createCarIcon(isDark: false);
    _carIconDark = await _createCarIcon(isDark: true);
    _userIcon = await _createUserArrowIcon();
    _dropoffIcon = await _createDropoffIcon();
    if (mounted) setState(() {});
  }

  /// Top-down 2D car icon asset (Uber-style) for driver location
  Future<BitmapDescriptor> _createCarIcon({required bool isDark}) async {
    try {
      final ByteData data = await rootBundle.load('assets/images/map_navigator_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 50,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      return BitmapDescriptor.bytes(bytes);
    } catch (e) {
      debugPrint('Error loading custom car marker asset: $e');
      const size = 48.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Subtle shadow
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        16,
        Paint()
          ..color = Colors.black.withOpacity(isDark ? 0.4 : 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // White circle (Dark background for dark mode)
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        14,
        Paint()..color = isDark ? const Color(0xFF1E1E1E) : Colors.white,
      );

      // Car body (top-down)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(size / 2, size / 2), width: 12, height: 18),
          const Radius.circular(3),
        ),
        Paint()..color = isDark ? Colors.white : const Color(0xFF2C2C2C),
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
      ..color = AppColors.success
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

    const dropoffColor = AppColors.error;

    // Pin pole
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(size / 2, size / 2 + 6), width: 2.5, height: 22),
        const Radius.circular(1),
      ),
      Paint()..color = dropoffColor,
    );

    // Flag
    final flagPath = Path()
      ..moveTo(size / 2 + 1, 6)
      ..lineTo(size / 2 + 14, 10)
      ..lineTo(size / 2 + 1, 18)
      ..close();
    canvas.drawPath(flagPath, Paint()..color = dropoffColor);

    // Small circle at base
    canvas.drawCircle(
      Offset(size / 2, size - 5),
      3,
      Paint()..color = dropoffColor,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(activeRideProvider);

    String formattedPaymentMethod = rideState.ride?.paymentMethod ?? 'Cash';
    if (formattedPaymentMethod.toUpperCase() == 'CARD' && rideState.ride?.paymentMethodId != null) {
      final pmState = ref.watch(paymentMethodsProvider);
      final methods = pmState.value ?? [];
      try {
        final card = methods.firstWhere((m) => m.id == rideState.ride!.paymentMethodId);
        formattedPaymentMethod = card.displayName;
      } catch (_) {
        formattedPaymentMethod = 'Card';
      }
    }

    if (rideState.ride == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If ride exists, expects a driver, but driver info is missing, re-fetch from API.
    // Guards:
    //  1. Only for statuses where a driver is actually assigned (not scheduled)
    //  2. Only attempt once per screen lifetime to avoid rebuild loops
    final expectsDriver = rideState.status == ActiveRideStatus.driverEnRoute ||
        rideState.status == ActiveRideStatus.driverArrived ||
        rideState.status == ActiveRideStatus.inProgress;

    if (!_driverFetchAttempted &&
        rideState.ride != null &&
        expectsDriver &&
        rideState.driverInfo == null &&
        !rideState.isLoading) {
      _driverFetchAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeRideProvider.notifier).initFromSocketEvent({
            'rideId': rideState.ride!.id,
          });
        }
      });
    }

    // Navigate on completion or cancellation, auto-zoom on status change
    ref.listen<ActiveRideState>(activeRideProvider, (prev, next) {
      if (next.isCompleted && prev?.isCompleted != true) {
        context.goNamed(RouteNames.rideComplete);
      }
      if (next.isCancelled && prev?.isCancelled != true) {
        final reason = next.cancelReason ?? '';
        
        // System cancellation reasons
        final isSystemCancel = reason.contains('driver cancelled') || 
                               reason.contains('has been cancelled.') ||
                               reason.contains('No drivers') ||
                               reason.contains('All of our drivers');

        if (isSystemCancel) {
          // System cancellation (no drivers, timeout, driver cancelled) — show dialog
          _showRideCancelledDialog();
        }
        // If the user cancelled it locally, the `cancel_ride_sheet.dart` will show the success dialog.
        // We shouldn't automatically navigate to Home or show another dialog here.
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
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

      // Smooth marker movement when driver location updates
      if (next.driverLocation != null &&
          (prev?.driverLocation?.latitude != next.driverLocation?.latitude ||
           prev?.driverLocation?.longitude != next.driverLocation?.longitude)) {
        
        final nextPos = LatLng(next.driverLocation!.latitude, next.driverLocation!.longitude);
        final nextRot = next.driverLocation!.heading ?? 0;

        if (_newPos == null) {
          _newPos = nextPos;
          _newRot = nextRot;
        } else {
          _oldPos = _newPos;
          _newPos = nextPos;
          _posController.forward(from: 0);

          _oldRot = _newRot;
          _newRot = nextRot;
          _rotController.forward(from: 0);
        }
      }
    });

    if (rideState.isLoading && rideState.ride == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        : (rideState.ride != null
                            ? LatLng(rideState.ride!.pickupLat, rideState.ride!.pickupLng)
                            : _defaultCenter),
                    zoom: 15,
                  ),
                  style: Theme.of(context).brightness == Brightness.dark ? _darkMapStyle : null,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                    if (mounted) {
                      setState(() {
                        _isMapReady = true;
                      });
                    }
                  },
                  markers: _isMapReady ? _buildMarkers(rideState) : {},
                  polylines: _isMapReady ? _buildPolylines(rideState) : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),

                if (rideState.status == ActiveRideStatus.searching)
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
                              for (int i = 0; i < 3; i++)
                                _buildRadarRipple((_radarController.value + i * 0.33) % 1.0),
                              Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.1),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.success,
                                  size: 48,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                // Top bar with back + actions
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCircleButton(
                          icon: Icons.arrow_back,
                          onTap: () => context.goNamed(RouteNames.home),
                          semanticLabel: 'Go back',
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildCircleButton(
                              icon: Icons.my_location_rounded,
                              onTap: () => _focusCurrentLocation(),
                              semanticLabel: 'Focus location',
                            ),
                            if (rideState.status == ActiveRideStatus.driverEnRoute ||
                                rideState.status == ActiveRideStatus.driverArrived ||
                                rideState.status == ActiveRideStatus.inProgress) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _showSafetyBottomSheet(context),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
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
          if (!rideState.isCancelled && rideState.status != ActiveRideStatus.completed)
            Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
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
                        color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status bar removed as per user request

                    // Ride PIN — only show after driver has accepted the ride
                    if (rideState.otpPin != null &&
                        (rideState.status == ActiveRideStatus.driverEnRoute ||
                         rideState.status == ActiveRideStatus.driverArrived))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            if (rideState.etaMinutes != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Pick-up in ${rideState.etaMinutes} min',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Share PIN',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.backgroundDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Row(
                                    children: rideState.otpPin!.split('').map((digit) => Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundDark,
                                          borderRadius: BorderRadius.circular(13),
                                        ),
                                        child: Text(
                                          digit,
                                          style: AppTextStyles.titleSmall.copyWith(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Driver info card and Trip details
                    if (rideState.driverInfo != null)
                      Column(
                        children: [
                          DriverInfoCard(
                            driverInfo: rideState.driverInfo!,
                            onCall: () => _callDriver(),
                            onMessage: () => _openChat(context),
                            pickupAddress: rideState.ride?.pickupAddress ?? '',
                            dropoffAddress: rideState.ride?.dropoffAddress ?? '',
                            paymentMethod: formattedPaymentMethod,
                            onCancel: (rideState.status == ActiveRideStatus.driverEnRoute ||
                                    rideState.status == ActiveRideStatus.driverArrived)
                                ? () => _showCancelSheet(context)
                                : null,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Status-specific content
                    _buildStatusContent(rideState, formattedPaymentMethod),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(ActiveRideState rideState, String formattedPaymentMethod) {
    switch (rideState.status) {
      case ActiveRideStatus.searching:
        return _buildSearchingContent(rideState, formattedPaymentMethod);
      case ActiveRideStatus.scheduled:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                'Your partner will be assigned shortly before departure.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Cancel Scheduled Ride'),
                ),
              ),
            ],
          ),
        );
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
        // Calculate remaining distance dynamically
        double? remainingKm;
        if (rideState.ride != null) {
          final lat1 = rideState.driverLocation?.latitude ?? rideState.ride!.pickupLat;
          final lng1 = rideState.driverLocation?.longitude ?? rideState.ride!.pickupLng;
          remainingKm = _calcDistanceKm(
            lat1,
            lng1,
            rideState.ride!.dropoffLat,
            rideState.ride!.dropoffLng,
          );
        }
        
        final dynamicEtaMinutes = (remainingKm != null) ? (remainingKm * 2.5).ceil() : (rideState.etaMinutes ?? 0);

        return RideInProgressView(
          etaMinutes: dynamicEtaMinutes,
          remainingKm: remainingKm,
          dropoffAddress: rideState.ride?.dropoffAddress ?? 'Destination',
          onSos: null, // Moved to floating map button
          onCancel: null, // Removed from the bottom bar
          onChangeDestination: null, // Disabled changing location after ride accept
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
            color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
          ),
          child: Icon(icon, color: Theme.of(context).iconTheme.color ?? AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    final driver = ref.read(activeRideProvider).driverInfo;
    if (driver == null || driver.phone.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number not available')),
      );
      return;
    }
    final uri = Uri.parse('tel:${driver.phone}');
    try {
      final launched = await launchUrl(uri);
      if (launched) return;
    } catch (_) {
      // Fallback below
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${driver.name}...'),
          backgroundColor: AppColors.primaryGold,
        ),
      );
    }
  }

  void _openChat(BuildContext context) {
    if (!mounted) return;
    final ride = ref.read(activeRideProvider).ride;
    if (ride == null) return;
    context.pushNamed(RouteNames.rideChat);
  }

  Future<void> _focusCurrentLocation() async {
    final rideState = ref.read(activeRideProvider);
    if (rideState.ride == null) return;
    
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    
    // Focus strictly on the rider's pickup location
    final pickup = LatLng(rideState.ride!.pickupLat, rideState.ride!.pickupLng);
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: pickup, zoom: 16),
    ));
  }

  void _showRideDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const RideDetailsSheet(),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const ShareRideSheet(),
      ),
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

  void _showSafetyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafetyBottomSheet(
        onShareTrip: () => _showWhatsAppShareSheet(context),
        onCallEmergency: () => _showMaltaEmergencySheet(context),
        onAlertContacts: () => _showAlertContactsSheet(context),
        onContactSupport: () {
          final rideId = ref.read(activeRideProvider).ride?.id;
          context.pushNamed(RouteNames.createTicket, extra: rideId);
        },
      ),
    );
  }

  void _showMaltaEmergencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaltaEmergencySheet(
        onCallSelected: (name, phone) async {
          ref.read(activeRideProvider.notifier).triggerSos(
                AppConstants.defaultLat,
                AppConstants.defaultLng,
              );
          final url = Uri.parse("tel:$phone");
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not launch dialer for $name.')),
              );
            }
          }
        },
      ),
    );
  }

  void _showAlertContactsSheet(BuildContext context) {
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final contacts = userProfile?.emergencyContacts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactSelectionSheet(
        mode: ContactSelectionMode.call,
        emergencyContacts: contacts,
        onContactSelected: (name, phone) {
          ref.read(activeRideProvider.notifier).triggerSos(
                AppConstants.defaultLat,
                AppConstants.defaultLng,
              );
        },
      ),
    );
  }

  void _showWhatsAppShareSheet(BuildContext context) async {
    final rideState = ref.read(activeRideProvider);
    final destination = rideState.ride?.dropoffAddress ?? 'my destination';
    final driver = rideState.driverInfo;
    final driverName = driver?.name ?? 'my driver';
    final plate = driver?.formattedPlate ?? '';
    final vehicleColor = driver?.vehicleColor ?? '';
    final vehicleDesc = driver?.vehicleDescription ?? '';
    final vehicleType = driver?.vehicleType ?? '';
    final rating = driver?.rating != null ? driver!.rating.toStringAsFixed(1) : '';

    // Get the cached tracking URL if already generated, else fetch it
    final trackingUrl = rideState.shareTrackingUrl;
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final contacts = userProfile?.emergencyContacts;

    // Get current GPS location for a Google Maps link
    String currentLocationLine = '';
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final lat = position.latitude;
      final lng = position.longitude;
      currentLocationLine =
          '\n📍 My current location: https://maps.google.com/?q=$lat,$lng';
    } catch (_) {
      // If GPS fails, skip the current location line
    }

    if (!mounted) return;

    void openContactSheet(String? url) {
      // Build driver details block
      final driverDetails = StringBuffer();
      driverDetails.write('👤 Driver: $driverName');
      if (rating.isNotEmpty) driverDetails.write(' ⭐ $rating');
      driverDetails.write('\n');
      if (vehicleDesc.isNotEmpty) driverDetails.write('🚗 Vehicle: $vehicleDesc');
      if (vehicleColor.isNotEmpty) driverDetails.write(' ($vehicleColor)');
      if (vehicleType.isNotEmpty) driverDetails.write(' [$vehicleType]');
      if (plate.isNotEmpty) driverDetails.write('\n🔤 Plate: $plate');

      // Build tracking link
      final trackingLine = url != null && url.isNotEmpty
          ? '\n🔗 Live tracking: $url'
          : '';

      final message =
          '🚖 I\'m on a Gozolt ride!\n'
          '${driverDetails.toString()}\n'
          '📌 Heading to: $destination'
          '$currentLocationLine'
          '$trackingLine';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ContactSelectionSheet(
          mode: ContactSelectionMode.whatsapp,
          locationMessage: message,
          emergencyContacts: contacts,
        ),
      );
    }

    if (trackingUrl != null) {
      openContactSheet(trackingUrl);
    } else {
      // Generate the tracking link first, then open the contact sheet
      ref.read(activeRideProvider.notifier).shareRide().then((url) {
        if (mounted) openContactSheet(url);
      });
    }
  }


  void _showRideCancelledDialog() {
    final reason = ref.read(activeRideProvider).cancelReason;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // Prevent back button closing
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with soft glowing background
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.no_crash_outlined,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Ride Unavailable',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              
              // Reason text
              Text(
                reason ?? 'Unfortunately, your ride has been cancelled.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              if (reason != null && (reason.toLowerCase().contains('no driver') || reason.toLowerCase().contains('all of our drivers')) && ref.read(activeRideProvider).ride?.paymentMethod == 'card') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF233227) : const Color(0xFFF1F8F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your pre-authorization hold has been successfully cancelled. The debited amount will be credited back to your account shortly.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 32),
              ],

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(activeRideProvider.notifier).reset();
                    context.goNamed(RouteNames.searchDestination);
                  },
                  child: Text(
                    'Book Another Ride',
                    style: AppTextStyles.button.copyWith(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(activeRideProvider.notifier).reset();
                    context.goNamed(RouteNames.home);
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: AppTextStyles.button.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarRipple(double progress) {
    final size = 40 + (160 * progress);
    final opacity = (1.0 - progress).clamp(0.0, 0.6);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildSearchingContent(ActiveRideState rideState, String formattedPaymentMethod) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ride = rideState.ride;
    final paymentMethod = formattedPaymentMethod;
    final extraFareAdded = rideState.extraFareAdded ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Finding drivers nearby',
          style: AppTextStyles.headlineSmall.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Text(
                'Requesting drivers in your area...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Trip details card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Meet at pickup point',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.money, color: Colors.green, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      paymentMethod.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Add extra fare card
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Icon(Icons.flash_on, color: AppColors.primaryGold, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Add extra to get a faster ride',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Show confirmed extra badge
                  if (extraFareAdded > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withOpacity(0.4), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            '+€${extraFareAdded.toStringAsFixed(0)} added',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '100% of the extra amount goes to your driver',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),

              // Compact chip-style amount buttons
              Row(
                children: [5.0, 10.0, 15.0].map((amount) {
                  final isSelected = _selectedExtraFare == amount;
                  return Padding(
                    padding: EdgeInsets.only(right: amount != 15.0 ? 8.0 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedExtraFare = isSelected ? 0 : amount;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryGold
                              : (isDark ? const Color(0xFF3A3A3A) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryGold
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isSelected ? 0 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.primaryGold.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          '+€${amount.toInt()}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.black
                                : (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_selectedExtraFare > 0) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = _selectedExtraFare;
                      ref.read(activeRideProvider.notifier).addExtraFare(amount);
                      setState(() { _selectedExtraFare = 0; });
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.flash_on, color: Colors.black, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '+€${amount.toInt()} offer sent to nearby drivers!',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primaryGold,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Offer +€${_selectedExtraFare.toInt()} to drivers',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => _showCancelSheet(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel Request',
              style: AppTextStyles.button,
            ),
          ),
        ),
      ],
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
