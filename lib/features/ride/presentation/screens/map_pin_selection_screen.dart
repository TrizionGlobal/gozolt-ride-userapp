import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';


import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/location_data.dart';

class MapPinSelectionScreen extends StatefulWidget {
  const MapPinSelectionScreen({super.key});

  @override
  State<MapPinSelectionScreen> createState() => _MapPinSelectionScreenState();
}

class _MapPinSelectionScreenState extends State<MapPinSelectionScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _center = LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  String _address = 'Move pin to select location';
  String? _subtitle;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() => _center = newCenter);
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(newCenter));
    } catch (_) {
      // Use default location
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    if (!_isMoving) {
      setState(() => _isMoving = true);
    }
  }

  void _onCameraIdle() async {
    setState(() => _isMoving = false);
    
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        _center.latitude,
        _center.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final street = p.street ?? '';
        final locality = p.locality ?? '';
        final name = p.name ?? '';
        
        setState(() {
          if (street.isNotEmpty && locality.isNotEmpty) {
            _address = '$street, $locality';
          } else {
            _address = name.isNotEmpty ? name : '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
          }
          _subtitle = 'Selected location';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
          _subtitle = 'Coordinates only';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Google Map ─────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15,
            ),
            style: _darkMapStyle,
            onMapCreated: (controller) {
              _mapController.complete(controller);
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Center Pin ──────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: AnimatedScale(
                scale: _isMoving ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
            ),
          ),

          // ── Back Button ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Icon(Icons.arrow_back,
                    color: AppColors.primaryGold, size: 20),
              ),
            ),
          ),

          // ── My Location Button ──────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Icon(Icons.my_location,
                    color: AppColors.primaryGold, size: 20),
              ),
            ),
          ),

          // ── Bottom Card ─────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SELECTED PICKUP POINT',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _address,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => context.pop(LocationData(
                        address: _address,
                        latitude: _center.latitude,
                        longitude: _center.longitude,
                        subtitle: _subtitle,
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.backgroundDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Location',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}
