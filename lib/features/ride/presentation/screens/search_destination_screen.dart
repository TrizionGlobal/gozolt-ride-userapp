import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../data/models/location_data.dart';
import '../providers/ride_providers.dart';
import '../providers/ride_booking_state.dart';
import '../../../account/presentation/providers/account_providers.dart';

class SearchDestinationScreen extends ConsumerStatefulWidget {
  const SearchDestinationScreen({super.key});

  @override
  ConsumerState<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState
    extends ConsumerState<SearchDestinationScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  final _pickupFocus = FocusNode();
  final _dropoffFocus = FocusNode();

  // Known Go Places destinations
  static const _goPlacesLocations = {
    'valletta': LocationData(
      address: 'Valletta',
      latitude: 35.8989,
      longitude: 14.5146,
      subtitle: 'Capital City, Malta',
    ),
    'mdina': LocationData(
      address: 'Mdina',
      latitude: 35.8858,
      longitude: 14.4024,
      subtitle: 'Silent City, Malta',
    ),
    'gozo': LocationData(
      address: 'Gozo',
      latitude: 36.0444,
      longitude: 14.2518,
      subtitle: 'Gozo Island, Malta',
    ),
  };

  Future<bool> _ensureLocationEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.location_off, color: AppColors.warning, size: 28),
              const SizedBox(width: 8),
              Text('GPS Required',
                  style: AppTextStyles.titleLarge.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
            ],
          ),
          content: Text(
            'Location services are required to book a ride. Please enable GPS.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to book a ride'),
            backgroundColor: AppColors.warning,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Permission Required',
              style: AppTextStyles.titleLarge.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
          content: Text(
            'Location permission is permanently denied. Please enable it in app settings.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Geolocator.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('Open Settings'),
                ),
              ],
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check GPS before allowing ride booking
      await _ensureLocationEnabled();

      if (!mounted) return;

      // Check for pre-filled destination from Go Places FIRST
      final uri = GoRouterState.of(context).uri;
      final destination = uri.queryParameters['destination'];
      final hasGoPlacesDestination = destination != null && destination.isNotEmpty;

      // If coming from Go Places, reset old booking state
      if (hasGoPlacesDestination) {
        ref.read(rideBookingProvider.notifier).reset();
      }

      // Show "Current Location" immediately, then fetch GPS in background
      _pickupController.text = 'Current Location';
      _fetchAndUpdatePickup();

      // Apply Go Places destination only (don't auto-fill inputs)
      if (hasGoPlacesDestination) {
        final location = _goPlacesLocations[destination.toLowerCase()];
        if (location != null) {
          _applyLocation('dropoff', location);
        }
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    for (final c in _stopControllers) {
      c.dispose();
    }
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.join(', ');
        if (p.name != null && p.name!.isNotEmpty) return p.name!;
      }
    } catch (_) {
      // Geocoding failed — use fallback
    }
    return 'Current Location';
  }

  Future<void> _fetchAndUpdatePickup() async {
    // Step 1: Try last known position for instant result
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final address = await _reverseGeocode(lastKnown.latitude, lastKnown.longitude);
        if (mounted) {
          final location = LocationData(
            address: address,
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            subtitle: '${lastKnown.latitude.toStringAsFixed(4)}, ${lastKnown.longitude.toStringAsFixed(4)}',
          );
          ref.read(rideBookingProvider.notifier).setPickup(location);
          _pickupController.text = address;
        }
      }
    } catch (_) {
      // Last known not available, continue to fresh position
    }

    // Step 2: Get accurate position in background
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        final address = await _reverseGeocode(position.latitude, position.longitude);
        if (mounted) {
          final location = LocationData(
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
            subtitle: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          );
          ref.read(rideBookingProvider.notifier).setPickup(location);
          _pickupController.text = address;
        }
      }
    } catch (_) {
      // If both failed, use fallback only if no position was set
      if (mounted) {
        final currentPickup = ref.read(rideBookingProvider).pickup;
        if (currentPickup == null) {
          ref.read(rideBookingProvider.notifier).setPickup(const LocationData(
            address: 'Current Location',
            latitude: 35.8989,
            longitude: 14.5146,
            subtitle: 'Malta',
          ));
        }
      }
    }
  }

  void _addStop() {
    final booking = ref.read(rideBookingProvider);
    if (booking.stops.length >= 3) return;
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    final booking = ref.read(rideBookingProvider);
    if (index < booking.stops.length) {
      ref.read(rideBookingProvider.notifier).removeStop(index);
    }
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  void _selectLocation(String field, {int? stopIndex}) {
    // For now, use a simple predefined list of Malta locations
    _showLocationPicker(field, stopIndex: stopIndex);
  }

  void _showLocationPicker(String field, {int? stopIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LocationSearchSheet(
        showCurrentLocation: field == 'pickup',
        onSelect: (location) {
          Navigator.of(ctx).pop();
          _applyLocation(field, location, stopIndex: stopIndex);
        },
      ),
    );
  }

  void _applyLocation(String field, LocationData location, {int? stopIndex}) {
    final notifier = ref.read(rideBookingProvider.notifier);
    if (field == 'pickup') {
      _pickupController.text = location.address;
      notifier.setPickup(location);
    } else if (field == 'dropoff') {
      _dropoffController.text = location.address;
      notifier.setDropoff(location);
      ref.read(recentSearchesProvider.notifier).add(location);
    } else if (field == 'stop' && stopIndex != null) {
      _stopControllers[stopIndex].text = location.address;
      // Replace stop or add
      final booking = ref.read(rideBookingProvider);
      if (stopIndex < booking.stops.length) {
        final newStops = List<LocationData>.from(booking.stops);
        newStops[stopIndex] = location;
        // We need a workaround since there's no replaceStop method
        for (int i = booking.stops.length - 1; i >= 0; i--) {
          notifier.removeStop(i);
        }
        for (final s in newStops) {
          notifier.addStop(s);
        }
      } else {
        notifier.addStop(location);
      }
    }

  }

  Widget _connectingLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Future<void> _searchVehicles() async {
    // Ensure GPS is enabled before proceeding
    final gpsOk = await _ensureLocationEnabled();
    if (!gpsOk || !mounted) return;

    final booking = ref.read(rideBookingProvider);

    if (booking.pickup == null) {
      _showErrorSnackBar('Please set a pickup location');
      return;
    }

    if (booking.dropoff == null) {
      _showErrorSnackBar('Please enter a destination');
      return;
    }

    // Distance checks
    final distanceMeters = Geolocator.distanceBetween(
      booking.pickup!.latitude,
      booking.pickup!.longitude,
      booking.dropoff!.latitude,
      booking.dropoff!.longitude,
    );

    if (distanceMeters > 100000) {
      _showErrorDialog(
        'Destination Too Far',
        'The destination is ${(distanceMeters / 1000).toStringAsFixed(0)} km away. Please choose a destination within 100 km.',
      );
      return;
    }

    if (distanceMeters < 500) {
      _showErrorSnackBar('Pickup and destination are too close. Minimum distance is 500m.');
      return;
    }

    await ref.read(rideBookingProvider.notifier).fetchFareEstimate();
    if (mounted) {
      final bookingState = ref.read(rideBookingProvider);
      if (bookingState.status == BookingStatus.error) {
        _showErrorSnackBar(bookingState.errorMessage ?? 'Failed to estimate fare. Please try again.');
      } else {
        context.pushNamed(RouteNames.rideBooking);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFACC15), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardTheme.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Color(0xFFFACC15), size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight, fontSize: 17))),
          ],
        ),
        content: Text(message, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9CA3AF) : AppColors.textSecondaryLight, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addHomeAddress() async {
    final result = await context.pushNamed<LocationData>(RouteNames.mapPinSelection);
    if (result != null && mounted) {
      await ref.read(accountAddressesProvider.notifier).addAddress({
        'label': 'Home',
        'address': result.address,
        'latitude': result.latitude,
        'longitude': result.longitude,
        'isDefault': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home address saved!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(rideBookingProvider);
    final accountAddrs = ref.watch(accountAddressesProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryGold),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
          },
        ),
        title: Text(
          'Search Destination',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Location Input Fields ──────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryGold, width: 1),
            ),
            child: Column(
              children: [
                // Pickup field
                _LocationField(
                  controller: _pickupController,
                  hint: 'Pickup location',
                  dotColor: AppColors.success,
                  onTap: () => _selectLocation('pickup'),
                ),

                // Intermediate stops with connecting lines
                ...List.generate(_stopControllers.length, (index) {
                  return Column(
                    children: [
                      _connectingLine(),
                      _LocationField(
                        controller: _stopControllers[index],
                        hint: 'Stop ${index + 1}',
                        dotColor: AppColors.warning,
                        trailing: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _removeStop(index),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close,
                                color: AppColors.textSecondary, size: 18),
                          ),
                        ),
                        onTap: () =>
                            _selectLocation('stop', stopIndex: index),
                      ),
                    ],
                  );
                }),

                _connectingLine(),

                // Dropoff field
                _LocationField(
                  controller: _dropoffController,
                  hint: 'Where are you going?',
                  dotColor: AppColors.error,
                  onTap: () => _selectLocation('dropoff'),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Add Stop button
                    (booking.stops.length < 3 && _stopControllers.length < 3)
                        ? GestureDetector(
                            onTap: _addStop,
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline,
                                    color: AppColors.primaryGold, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'ADD STOP',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),

                    // Choose on Map button
                    GestureDetector(
                      onTap: () async {
                        final result = await context
                            .pushNamed<LocationData>(RouteNames.mapPinSelection);
                        if (result != null && mounted) {
                          _applyLocation('dropoff', result);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined,
                              color: AppColors.primaryGold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Choose on Map',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Search Vehicles button ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 44, // Smaller height
              child: GozoltButton(
                label: 'Search Vehicles',
                width: double.infinity,
                isLoading: booking.status == BookingStatus.estimating,
                onPressed: _searchVehicles,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Saved Places ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAVED PLACES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (_) {
                    if (accountAddrs.isLoading) {
                      return const SizedBox.shrink();
                    }
                    final addresses = accountAddrs.addresses;
                    final hasHome = addresses.any((a) => a.label.toLowerCase() == 'home');

                    return Column(
                      children: [
                        if (!hasHome)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SavedPlaceTile(
                              icon: Icons.add_home_rounded,
                              title: 'Add Home Address',
                              subtitle: 'Set your home for quick booking',
                              onTap: _addHomeAddress,
                            ),
                          ),
                        ...addresses.map((addr) {
                          final isHome = addr.label.toLowerCase() == 'home';
                          final isWork = addr.label.toLowerCase() == 'work';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SavedPlaceTile(
                              icon: isHome
                                  ? Icons.home_rounded
                                  : isWork
                                      ? Icons.work_rounded
                                      : Icons.location_on_rounded,
                              title: addr.label,
                              subtitle: addr.address,
                              onTap: () {
                                _applyLocation(
                                  'dropoff',
                                  LocationData(
                                    address: addr.address,
                                    latitude: addr.latitude ?? 0,
                                    longitude: addr.longitude ?? 0,
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // ── Recent Searches ────────────────────────
                  if (recentSearches.isNotEmpty) ...[
                    Text(
                      'RECENT SEARCHES',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recentSearches.map((search) => _RecentSearchTile(
                          address: search.address,
                          subtitle: search.subtitle ?? '',
                          onTap: () =>
                              _applyLocation('dropoff', search),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Location Input Field Widget ──────────────────────────

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color dotColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _LocationField({
    required this.controller,
    required this.hint,
    required this.dotColor,
    this.trailing,
    this.onTap,
  });

  String get _label {
    if (dotColor == AppColors.success) return 'PICKUP';
    if (dotColor == AppColors.error) return 'DROP-OFF';
    return 'STOP';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = controller.text.isNotEmpty;
    final fieldBg = isDark
        ? const Color(0xFF1A1F2B)
        : const Color(0xFFF0F2F5);
    final fieldBorder = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final labelColor = dotColor.withOpacity(0.85);

    return Row(
      children: [
        // Colored dot with subtle glow
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasValue
                      ? dotColor.withOpacity(0.35)
                      : fieldBorder,
                  width: hasValue ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label row
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Value / hint
                  Text(
                    hasValue ? controller.text : hint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: hasValue
                          ? (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

// ── Saved Place Tile ─────────────────────────────────────

class _SavedPlaceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SavedPlaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.titleSmall
                          .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Recent Search Tile ───────────────────────────────────

class _RecentSearchTile extends StatelessWidget {
  final String address;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentSearchTile({
    required this.address,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location Search Bottom Sheet (Photon API + Native Fallback) ────

class _LocationSearchSheet extends StatefulWidget {
  final ValueChanged<LocationData> onSelect;
  final bool showCurrentLocation;

  const _LocationSearchSheet({
    required this.onSelect,
    this.showCurrentLocation = false,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _searchController = TextEditingController();
  final _dio = Dio();
  Timer? _debounce;
  List<LocationData> _results = [];
  bool _isSearching = false;
  bool _showingQuickPicks = true;

  static const _maltaQuickPicks = [
    LocationData(
      address: 'Malta International Airport',
      latitude: 35.8575,
      longitude: 14.4775,
      subtitle: 'Luqa, LQA 4000',
    ),
    LocationData(
      address: '24 Luxury Towers, Sliema',
      latitude: 35.9117,
      longitude: 14.5050,
      subtitle: 'Sliema waterfront, Malta',
    ),
    LocationData(
      address: 'Valletta Bus Terminal',
      latitude: 35.8950,
      longitude: 14.5089,
      subtitle: 'Valletta, Malta',
    ),
    LocationData(
      address: 'St. Julian\'s Bay',
      latitude: 35.9186,
      longitude: 14.4893,
      subtitle: 'St. Julian\'s, Malta',
    ),
    LocationData(
      address: 'Mdina Gate',
      latitude: 35.8858,
      longitude: 14.4024,
      subtitle: 'Mdina, Malta',
    ),
    LocationData(
      address: 'Bugibba Square',
      latitude: 35.9512,
      longitude: 14.4157,
      subtitle: 'Bugibba, Malta',
    ),
    LocationData(
      address: 'Marsaxlokk Harbour',
      latitude: 35.8419,
      longitude: 14.5432,
      subtitle: 'Marsaxlokk, Malta',
    ),
    LocationData(
      address: 'University of Malta',
      latitude: 35.9026,
      longitude: 14.4835,
      subtitle: 'Msida, Malta',
    ),
    LocationData(
      address: 'Mater Dei Hospital',
      latitude: 35.8993,
      longitude: 14.4847,
      subtitle: 'Msida, Malta',
    ),
    LocationData(
      address: 'The Point Shopping Mall',
      latitude: 35.9113,
      longitude: 14.5056,
      subtitle: 'Sliema, Malta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _results = _maltaQuickPicks;
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = _maltaQuickPicks;
        _isSearching = false;
        _showingQuickPicks = true;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaceSuggestions(query.trim());
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    // Use current GPS position for location bias, fallback to Malta center
    double biasLat = AppConstants.defaultLat;
    double biasLng = AppConstants.defaultLng;
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        biasLat = pos.latitude;
        biasLng = pos.longitude;
      }
    } catch (_) {}

    List<LocationData> newResults = [];

    // TIER 1: Google Places Autocomplete
    try {
      final googleUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&location=$biasLat%2C$biasLng'
          '&radius=100000'
          '&key=${AppConstants.googleMapsApiKey}';

      final googleRes = await _dio.get(googleUrl);
      final gData = googleRes.data;

      if (gData is Map<String, dynamic> && gData['status'] == 'OK' && gData['predictions'] is List) {
        final predictions = gData['predictions'] as List;
        newResults = predictions.map((p) {
          final structured = p['structured_formatting'] as Map<String, dynamic>?;
          final mainText = structured?['main_text'] as String? ?? p['description'] as String? ?? query;
          final secondaryText = structured?['secondary_text'] as String?;

          return LocationData(
            address: mainText,
            latitude: 0,
            longitude: 0,
            subtitle: secondaryText,
            placeId: p['place_id'] as String?,
          );
        }).toList();
      }
    } catch (_) {}

    // TIER 2: Photon Fallback
    if (newResults.isEmpty) {
      try {
        final url = 'https://photon.komoot.io/api/'
            '?q=${Uri.encodeComponent(query)}'
            '&lat=$biasLat'
            '&lon=$biasLng'
            '&limit=8'
            '&lang=en';

        final response = await _dio.get(url, options: Options(headers: {'User-Agent': 'GozoltApp/1.0', 'Accept': 'application/json'}));
        final data = response.data;

        if (data is Map<String, dynamic> && data['features'] is List) {
          final features = data['features'] as List;
          newResults = features.map((f) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final coords = f['geometry']?['coordinates'] as List?;
            final lng = (coords != null && coords.isNotEmpty) ? (coords[0] as num).toDouble() : 0.0;
            final lat = (coords != null && coords.length > 1) ? (coords[1] as num).toDouble() : 0.0;

            final name = props['name'] as String? ?? '';
            final parts = <String>[
              if ((props['street'] as String?)?.isNotEmpty == true) props['street'] as String,
              if ((props['city'] as String?)?.isNotEmpty == true) props['city'] as String,
              if ((props['state'] as String?)?.isNotEmpty == true) props['state'] as String,
              if ((props['country'] as String?)?.isNotEmpty == true) props['country'] as String,
            ];

            return LocationData(
              address: name.isNotEmpty ? name : parts.firstOrNull ?? query,
              latitude: lat,
              longitude: lng,
              subtitle: parts.isNotEmpty ? parts.join(', ') : null,
            );
          }).toList();
        }
      } catch (_) {}
    }

    // TIER 3: Native Geocoding Fallback
    if (newResults.isEmpty) {
      try {
        final locations = await geocoding.locationFromAddress(query);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          try {
            final placemarks = await geocoding.placemarkFromCoordinates(loc.latitude, loc.longitude);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final address = p.name ?? query;
              final parts = [p.locality, p.administrativeArea, p.country].where((e) => e != null && e.isNotEmpty).join(', ');
              newResults.add(LocationData(
                address: address.isNotEmpty ? address : query,
                latitude: loc.latitude,
                longitude: loc.longitude,
                subtitle: parts.isNotEmpty ? parts : 'Found via native search',
              ));
            } else {
              throw Exception();
            }
          } catch (_) {
            newResults.add(LocationData(
              address: query,
              latitude: loc.latitude,
              longitude: loc.longitude,
              subtitle: 'Found via native search',
            ));
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _showingQuickPicks = false;
      _results = newResults;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search any location...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Current Location special button
            if (_showingQuickPicks && widget.showCurrentLocation)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result = await context.pushNamed<LocationData>(RouteNames.mapPinSelection);
                    if (result != null && mounted) {
                      widget.onSelect(result);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.my_location, color: AppColors.primaryGold, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Confirm via map',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.primaryGold, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            // Section header
            if (_showingQuickPicks && _results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Picks',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            if (!_isSearching && !_showingQuickPicks && _results.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No locations found',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            // Results
            if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final loc = _results[index];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          if (loc.placeId != null && loc.latitude == 0 && loc.longitude == 0) {
                            try {
                              final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json'
                                  '?place_id=${loc.placeId}'
                                  '&fields=geometry'
                                  '&key=${AppConstants.googleMapsApiKey}';
                              final res = await _dio.get(detailsUrl);
                              final dData = res.data;
                              if (dData['status'] == 'OK') {
                                final location = dData['result']['geometry']['location'];
                                final lat = (location['lat'] as num).toDouble();
                                final lng = (location['lng'] as num).toDouble();
                                if (mounted) {
                                  widget.onSelect(loc.copyWith(latitude: lat, longitude: lng));
                                }
                                return;
                              }
                            } catch (_) {
                              // Fallback below
                            }
                          }
                          
                          // Immediately call onSelect — no delay
                          widget.onSelect(loc);
                        },
                        splashColor: AppColors.primaryGold.withOpacity(0.15),
                        highlightColor: AppColors.primaryGold.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _showingQuickPicks
                                      ? (isDark ? const Color(0xFF1C2333) : const Color(0xFFF0F2F5))
                                      : AppColors.primaryGold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _showingQuickPicks
                                      ? Icons.location_on_outlined
                                      : Icons.place_outlined,
                                  color: _showingQuickPicks
                                      ? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)
                                      : AppColors.primaryGold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.address,
                                      style:
                                          AppTextStyles.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (loc.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        loc.subtitle!,
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
