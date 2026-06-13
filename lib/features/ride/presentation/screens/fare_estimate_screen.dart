import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/saved_payment_method.dart';
import '../providers/ride_booking_state.dart';
import '../providers/ride_providers.dart';
import '../widgets/fare_breakdown_card.dart';
import '../widgets/payment_brand_icon.dart';
import '../widgets/add_card_sheet.dart';
import '../widgets/stripe_add_card_sheet.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/vehicle_type.dart';
import '../widgets/vehicle_type_selector.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../core/providers/dio_provider.dart';
import '../providers/active_ride_provider.dart';

class FareEstimateScreen extends ConsumerStatefulWidget {
  const FareEstimateScreen({super.key});

  @override
  ConsumerState<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends ConsumerState<FareEstimateScreen> {
  bool _isBottomExpanded = true;
  List<LatLng> _routePoints = [];
  GoogleMapController? _mapController;
  Set<Marker> _driverMarkers = {};
  Set<VehicleType> _availableVehicleTypes = {};
  Timer? _driverRefreshTimer;
  bool _isFocusing = false;

  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRoute();
      _fetchNearbyDrivers();
      _autoSelectDefaultPayment();

      final isScheduleMode = ref.read(isScheduleModeProvider);
      final booking = ref.read(rideBookingProvider);
      if (isScheduleMode && !booking.isScheduled) {
        _showScheduleSheet();
      }
    });
    _driverRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNearbyDrivers();
    });
  }

  /// Pre-select the user's default saved card when the screen loads.
  Future<void> _autoSelectDefaultPayment() async {
    try {
      final methods = await ref.read(paymentMethodsProvider.future);
      if (!mounted) return;
      await ref
          .read(rideBookingProvider.notifier)
          .initDefaultPaymentMethod(methods);
    } catch (_) {
      // If cards can't be loaded, leave Cash as the default
    }
  }

  Future<void> _fetchNearbyDrivers() async {
    final booking = ref.read(rideBookingProvider);
    if (booking.pickup == null) return;

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/rides/nearby-drivers', queryParameters: {
        'lat': booking.pickup!.latitude,
        'lng': booking.pickup!.longitude,
        'radius': 10,
      });

      final drivers = response.data as List<dynamic>? ?? [];
      final markers = <Marker>{};
      final vehicleTypes = <VehicleType>{};

      for (final driver in drivers) {
        final lat = (driver['lat'] as num?)?.toDouble();
        final lng = (driver['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        // Track which vehicle types are available
        final vType = driver['vehicleType'] as String? ?? 'STANDARD';
        vehicleTypes.add(VehicleType.fromApi(vType));

        markers.add(Marker(
          markerId: MarkerId('driver_${driver['id']}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '${driver['vehicleType'] ?? 'Driver'}',
            snippet: '${(driver['distanceKm'] as num?)?.toStringAsFixed(1) ?? '?'} km away',
          ),
        ));
      }

      if (mounted) {
        setState(() {
          _driverMarkers = markers;
          _availableVehicleTypes = vehicleTypes;
        });
      }
    } catch (e) {
      debugPrint('Nearby drivers fetch failed: $e');
    }
  }

  Future<void> _fetchRoute() async {
    final booking = ref.read(rideBookingProvider);
    if (booking.pickup == null || booking.dropoff == null) return;

    try {
      final dio = Dio();

      // Use OSRM (free, no API key needed) for road-following routes
      String coords;
      if (booking.stops.isNotEmpty) {
        final stopCoords = booking.stops.map((s) => '${s.longitude},${s.latitude}').join(';');
        final originCoord = '${booking.pickup!.longitude},${booking.pickup!.latitude}';
        final destCoord = '${booking.dropoff!.longitude},${booking.dropoff!.latitude}';
        coords = '$originCoord;$stopCoords;$destCoord';
      } else {
        coords = '${booking.pickup!.longitude},${booking.pickup!.latitude};${booking.dropoff!.longitude},${booking.dropoff!.latitude}';
      }
      final url = 'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=polyline';

      final response = await dio.get(url);
      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['code'] == 'Ok' &&
          (data['routes'] as List).isNotEmpty) {
        final encodedPolyline = data['routes'][0]['geometry'] as String;
        _routePoints = _decodePolyline(encodedPolyline);
      } else {
        final code = data is Map ? data['code'] : 'unknown';
        final msg = data is Map ? (data['message'] ?? '') : '';
        debugPrint('OSRM route error: $code - $msg');
        _routePoints = _fallbackRoute(booking);
      }
    } catch (e) {
      debugPrint('Route fetch exception: $e');
      final booking = ref.read(rideBookingProvider);
      _routePoints = _fallbackRoute(booking);
    }

    if (mounted) {
      setState(() {});
      _fitMapToRoute();
    }
  }

  List<LatLng> _fallbackRoute(RideBookingState booking) {
    return [
      if (booking.pickup != null)
        LatLng(booking.pickup!.latitude, booking.pickup!.longitude),
      if (booking.dropoff != null)
        LatLng(booking.dropoff!.latitude, booking.dropoff!.longitude),
    ];
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

  void _fitMapToRoute() {
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  /// Focuses the map camera on the user's live GPS, or pickup as fallback.
  Future<void> _focusOnCurrentLocation() async {
    if (_mapController == null) return;
    setState(() => _isFocusing = true);
    HapticFeedback.lightImpact();
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _focusFallbackToPickup();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15),
        ),
      );
    } catch (_) {
      _focusFallbackToPickup();
    } finally {
      if (mounted) setState(() => _isFocusing = false);
    }
  }

  void _focusFallbackToPickup() {
    final booking = ref.read(rideBookingProvider);
    if (booking.pickup != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(booking.pickup!.latitude, booking.pickup!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

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

  Set<Marker> _buildMarkers(RideBookingState booking) {
    final markers = <Marker>{};
    if (booking.pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(booking.pickup!.latitude, booking.pickup!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: booking.pickup!.address),
      ));
    }
    if (booking.dropoff != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(booking.dropoff!.latitude, booking.dropoff!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: booking.dropoff!.address),
      ));
    }
    // Nearby driver markers
    markers.addAll(_driverMarkers);
    return markers;
  }

  LatLng _getMapCenter(RideBookingState booking) {
    if (booking.pickup != null && booking.dropoff != null) {
      return LatLng(
        (booking.pickup!.latitude + booking.dropoff!.latitude) / 2,
        (booking.pickup!.longitude + booking.dropoff!.longitude) / 2,
      );
    }
    if (booking.pickup != null) {
      return LatLng(booking.pickup!.latitude, booking.pickup!.longitude);
    }
    return LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  }

  // ── Inline Payment Method Sheet ───────────────────────────
  void _showPaymentMethodSheet() {
    final booking = ref.read(rideBookingProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingPaymentSheet(
        currentType: booking.paymentMethodType,
        currentCardId: booking.selectedCardId,
        onConfirm: (type, {String? cardId}) {
          ref.read(rideBookingProvider.notifier).setPaymentMethod(
                type,
                cardId: cardId,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(rideBookingProvider);
    final isLoading = booking.status == BookingStatus.estimating;

    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    SavedPaymentMethod? selectedCard;
    if (booking.paymentMethodType == PaymentMethodType.card && booking.selectedCardId != null) {
      final methods = paymentMethodsAsync.value ?? [];
      try {
        selectedCard = methods.firstWhere((m) => m.id == booking.selectedCardId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Map Placeholder + Trip Summary Bar ──────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _getMapCenter(booking),
                    zoom: 13,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (mounted) {
                      setState(() {
                        _isMapReady = true;
                      });
                    }
                  },
                  style: Theme.of(context).brightness == Brightness.dark ? _darkMapStyle : null,
                  markers: _isMapReady ? _buildMarkers(booking) : {},
                  polylines: _isMapReady && _routePoints.isNotEmpty
                      ? {
                          Polyline(
                            polylineId: const PolylineId('route_glow'),
                            points: _routePoints,
                            color: const Color(0x4DFACC15),
                            width: 8,
                          ),
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: _routePoints,
                            color: const Color(0xFFFACC15),
                            width: 4,
                          ),
                        }
                      : {},
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),

                // Back button — consistent with active_ride_screen style
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: Semantics(
                    label: 'Go back',
                    button: true,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color?.withOpacity(0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).iconTheme.color ?? AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // Trip Summary bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 60,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRIP SUMMARY',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.stops.isEmpty
                                    ? '${_truncate(booking.pickup?.address ?? 'Pickup', 18)} → ${_truncate(booking.dropoff?.address ?? 'Dropoff', 18)}'
                                    : '${_truncate(booking.pickup?.address ?? 'Pickup', 14)} → ${booking.stops.length} stop${booking.stops.length > 1 ? 's' : ''} → ${_truncate(booking.dropoff?.address ?? 'Dropoff', 14)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: 'Edit trip',
                          button: true,
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'EDIT',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Focus / My Location Button ──────────────────
                Positioned(
                  bottom: 14,
                  right: 12,
                  child: Semantics(
                    label: 'Focus on current location',
                    button: true,
                    child: GestureDetector(
                      onTap: _focusOnCurrentLocation,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color?.withOpacity(0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isFocusing
                            ? Padding(
                                padding: const EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: AppColors.primaryGold,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Bottom Section ──────────────────
          Expanded(
            flex: _isBottomExpanded ? 5 : 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle chevron
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBottomExpanded = !_isBottomExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Icon(
                            _isBottomExpanded ? Icons.expand_more : Icons.expand_less,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Surge banner
                    if (booking.fareEstimate?.hasSurge == true)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt,
                                color: AppColors.primaryGold, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Higher Demand than usual. Fares are Slightly Elevated',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Vehicle selector
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: ShimmerWrap(
                                child: ShimmerBox(
                                  width: double.infinity,
                                  height: 80,
                                  borderRadius: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      VehicleTypeSelector(
                        selected: booking.vehicleType,
                        estimate: booking.fareEstimate,
                        availableTypes: _availableVehicleTypes.isNotEmpty
                            ? _availableVehicleTypes
                            : null,
                        onSelect: (type) {
                          HapticFeedback.selectionClick();
                          ref.read(rideBookingProvider.notifier).setVehicleType(type);
                        },
                      ),

                    const SizedBox(height: 16),

                    // Fare breakdown
                    if (booking.fareEstimate != null)
                      FareBreakdownCard(
                        estimate: booking.fareEstimate!,
                        promoDiscount: booking.promoDiscount,
                        coinsDiscount: booking.coinsDiscount,
                        useCoins: booking.useCoins,
                        isScheduled: booking.isScheduled,
                        scheduledAtText: booking.scheduledAt != null ? _formatSchedule(booking.scheduledAt!) : null,
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Bar ─────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment + GoCoins row
            Row(
              children: [
                // Payment method selector
                Semantics(
                  label: 'Select payment method',
                  button: true,
                  child: GestureDetector(
                    onTap: () => _showPaymentMethodSheet(),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            booking.paymentMethodType == PaymentMethodType.cash
                                ? Icons.payments_outlined
                                : Icons.credit_card,
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            booking.paymentMethodType == PaymentMethodType.cash
                                ? 'Cash'
                                : selectedCard != null
                                    ? selectedCard.displayName
                                    : 'Card',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more,
                              color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Use Coins toggle
                Semantics(
                  label: 'Use GoCoins',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      _showDiscountSheet();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: booking.useCoins
                            ? AppColors.primaryGold.withOpacity(0.2)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: booking.useCoins
                              ? AppColors.primaryGold
                              : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AssetPaths.iconGoCoin,
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Use Coins',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: booking.useCoins
                                  ? AppColors.primaryGold
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Find my Go partner button + schedule icon
            Builder(
              builder: (context) {
                return Row(
                  children: [
                    // Main CTA
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (booking.fareEstimate != null && booking.status != BookingStatus.booking)
                              ? () => _onSelectRide()
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                            disabledBackgroundColor:
                                AppColors.textMuted.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: booking.status == BookingStatus.booking
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).scaffoldBackgroundColor,
                                    ),
                                  ),
                                )
                              : Text(
                                  booking.isScheduled ? 'Schedule Ride' : 'Find my Go partner',
                                  style: AppTextStyles.button.copyWith(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                ),
                        ),
                      ),
                    ),

                const SizedBox(width: 10),

                // Schedule / share icon
                Semantics(
                  label: 'Schedule ride',
                  button: true,
                  child: GestureDetector(
                    onTap: () => _showScheduleSheet(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, width: 0.5),
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primaryGold, size: 20),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

            // Total now shown inside fare breakdown card
          ],
        ),
      ),
    );
  }

  Future<void> _onSelectRide() async {
    HapticFeedback.mediumImpact();
    final booking = ref.read(rideBookingProvider);

    if (booking.isScheduled && booking.scheduledAt != null) {
      // Scheduled ride — confirm, add notification, go home
      await ref.read(rideBookingProvider.notifier).confirmBooking();

      // Add notification for the scheduled ride
      ref.read(notificationsProvider.notifier).addScheduledRideNotification(
        pickup: booking.pickup?.address ?? '',
        dropoff: booking.dropoff?.address ?? '',
        scheduledAt: booking.scheduledAt!,
        fare: '€${booking.fareEstimate?.estimatedFare.toStringAsFixed(2) ?? '0.00'}',
        vehicleType: booking.vehicleType.name.toUpperCase(),
      );

      // Show brief confirmation snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ride to ${booking.dropoff?.address ?? 'destination'} scheduled!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Invalidate ride history so scheduled tab shows the new ride
      ref.invalidate(rideHistoryProvider);

      // Reset and go home
      ref.read(rideBookingProvider.notifier).reset();
      if (mounted) context.goNamed(RouteNames.home);
      return;
    }

    // Immediate ride — await the API call before navigating
    await ref.read(rideBookingProvider.notifier).confirmBooking();
    final updatedBooking = ref.read(rideBookingProvider);
    if (updatedBooking.status == BookingStatus.error) {
      // Clear the error state so user can retry without stale error
      ref.read(rideBookingProvider.notifier).clearError();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    updatedBooking.errorMessage ?? 'Failed to book ride. Please try again.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    if (mounted) {
      ref.read(activeRideProvider.notifier).initSearching(
        updatedBooking.createdRideId!,
        updatedBooking,
      );
      context.pushNamed(RouteNames.rideActive);
    }
  }

  void _showDiscountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.surfaceDark 
          : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _DiscountBottomSheet(),
    );
  }

  Future<void> _showScheduleSheet() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(minutes: 30));

    // Step 1: Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 7)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryGold,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimary,
                )
              : const ColorScheme.light(
                  primary: AppColors.primaryGold,
                  onSurface: AppColors.textPrimaryLight,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    // Step 2: Pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minDate.hour, minute: minDate.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryGold,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimary,
                )
              : const ColorScheme.light(
                  primary: AppColors.primaryGold,
                  onSurface: AppColors.textPrimaryLight,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          timePickerTheme: TimePickerThemeData(
            hourMinuteTextStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            dayPeriodTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: Transform.scale(
          scale: 0.85,
          child: child!,
        ),
      ),
    );
    if (pickedTime == null || !mounted) return;

    // Round to nearest 5 minutes
    int roundedMinute = ((pickedTime.minute / 5).round() * 5);
    int finalHour = pickedTime.hour;
    if (roundedMinute >= 60) {
      roundedMinute = 0;
      finalHour = (finalHour + 1) % 24;
    }

    final scheduledAt = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      finalHour, roundedMinute,
    );

    if (scheduledAt.isBefore(minDate)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule must be at least 30 minutes from now'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Step 3: Confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, color: AppColors.primaryGold, size: 48),
            const SizedBox(height: 16),
            Text(
              'Confirm Schedule',
              style: AppTextStyles.headlineSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              _formatSchedule(scheduledAt),
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryGold),
            ),
            const SizedBox(height: 8),
            Text(
              'A scheduling fee of €2.00 applies\nYou\'ll be notified 15 minutes before your ride',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('Cancel',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                  ),
                  child: Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      ref.read(rideBookingProvider.notifier).setScheduled(true, scheduledAt: scheduledAt);
      
      // Automatically trigger the booking process which navigates home and shows confirmation
      await _onSelectRide();
    }
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  String _formatSchedule(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${months[dt.month - 1]} ${dt.day}, $hour12:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _driverRefreshTimer?.cancel();
    super.dispose();
  }
}

// ── Discount Bottom Sheet (GoCoins + Coupon) ────────────

class _DiscountBottomSheet extends ConsumerWidget {
  const _DiscountBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(rideBookingProvider);
    final rewardsAsync = ref.watch(userRewardsPointsProvider);
    final rewardSummaryAsync = ref.watch(rewardSummaryProvider);

    double getTierConversionRate(String tier) {
      switch (tier.toUpperCase()) {
        case 'PLATINUM': return 100.0;
        case 'GOLD': return 133.33;
        case 'SILVER': return 200.0;
        default: return 400.0;
      }
    }

    final currentTier = rewardSummaryAsync.value?.tier ?? 'BRONZE';
    final conversionRate = getTierConversionRate(currentTier);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: AppColors.textSecondary),
            ),
          ),

          // ── Use GOZOLT Coins ──────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.cardDark 
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color ?? 
                    (Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use GOZOLT Coins',
                        style: AppTextStyles.titleSmall
                            .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 2),
                      rewardsAsync.when(
                        data: (points) {
                          final eurValue = points / conversionRate;
                          final remainingFare = (booking.fareEstimate?.estimatedFare ?? 0.0) - (booking.promoDiscount ?? 0.0);
                          final appliedEurValue = eurValue > remainingFare && remainingFare >= 0 ? remainingFare : eurValue;

                          return Text(
                            'save €${appliedEurValue.toStringAsFixed(2)} on your ride',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                rewardsAsync.when(
                  data: (points) {
                    final eurValue = points / conversionRate;
                    final remainingFare = (booking.fareEstimate?.estimatedFare ?? 0.0) - (booking.promoDiscount ?? 0.0);
                    final appliedEurValue = eurValue > remainingFare && remainingFare >= 0 ? remainingFare : eurValue;
                    final coinsUsed = (appliedEurValue * conversionRate).round();
                    
                    return Row(
                      children: [
                        Text(
                          '$coinsUsed',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primaryGold),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(AssetPaths.iconGoCoin,
                            width: 18, height: 18),
                        const SizedBox(width: 10),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch.adaptive(
                            value: booking.useCoins,
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(rideBookingProvider.notifier)
                                  .toggleUseCoins(val, discount: val ? appliedEurValue : 0);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Booking Payment Method Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingPaymentSheet extends ConsumerStatefulWidget {
  final PaymentMethodType currentType;
  final String? currentCardId;
  final void Function(PaymentMethodType type, {String? cardId}) onConfirm;

  const _BookingPaymentSheet({
    required this.currentType,
    this.currentCardId,
    required this.onConfirm,
  });

  @override
  ConsumerState<_BookingPaymentSheet> createState() =>
      _BookingPaymentSheetState();
}

class _BookingPaymentSheetState extends ConsumerState<_BookingPaymentSheet> {
  late PaymentMethodType _selectedType;
  String? _selectedCardId;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
    _selectedCardId = widget.currentCardId;
  }

  void _confirm() {
    widget.onConfirm(_selectedType, cardId: _selectedCardId);
    Navigator.of(context).pop();
  }

  void _addCard() {
    

    final ds = ref.read(paymentRemoteDatasourceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StripeAddCardSheet(
        datasource: ds,
        onCardAdded: (paymentMethodId) async {
          if (paymentMethodId != null) {
            try {
              await ds.confirmSetupIntent(paymentMethodId);
            } catch (_) {}
            ref.invalidate(paymentMethodsProvider);
            setState(() {
              _selectedType = PaymentMethodType.card;
              _selectedCardId = paymentMethodId;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card saved successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardTheme.color;
    final borderColor =
        Theme.of(context).dividerTheme.color ?? AppColors.borderDark;
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 20),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Options
          paymentMethodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryGold)),
            ),
            error: (_, __) => _buildOptions(
                [], cardColor, borderColor, textColor, secondaryTextColor),
            data: (methods) => _buildOptions(
                methods, cardColor, borderColor, textColor, secondaryTextColor),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm',
                  style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(
    List<SavedPaymentMethod> methods,
    Color? cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Cash option
          _buildOptionTile(
            icon: Icons.payments_outlined,
            title: 'Cash',
            subtitle: 'Pay the driver directly',
            isSelected: _selectedType == PaymentMethodType.cash,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => setState(() {
              _selectedType = PaymentMethodType.cash;
              _selectedCardId = null;
            }),
          ),
          const SizedBox(height: 10),

          // Saved cards
          ...methods.map((pm) {
            final isSelected = _selectedType == PaymentMethodType.card &&
                _selectedCardId == pm.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedType = PaymentMethodType.card;
                  _selectedCardId = pm.id;
                }),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primaryGold : borderColor,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      PaymentBrandIcon(brand: pm.brand),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pm.displayName,
                                style: AppTextStyles.titleSmall
                                    .copyWith(color: textColor)),
                            Text(
                                pm.isDefault ? 'Default card' : 'Saved card',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: secondaryTextColor)),
                          ],
                        ),
                      ),
                      if (pm.isDefault)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      _radioCircle(isSelected),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Add New Card
          _buildOptionTile(
            icon: Icons.add_circle_outline,
            title: 'Add New Card',
            subtitle: 'Credit / Debit Card',
            isSelected: false,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: _addCard,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color? cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : borderColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                  size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTextStyles.titleSmall.copyWith(color: textColor)),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: secondaryTextColor)),
                ],
              ),
            ),
            _radioCircle(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold,
                ),
              ),
            )
          : null,
    );
  }
}
