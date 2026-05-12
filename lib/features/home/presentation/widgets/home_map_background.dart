import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/nearby_drivers_provider.dart';

class HomeMapBackground extends ConsumerStatefulWidget {
  const HomeMapBackground({super.key});

  @override
  ConsumerState<HomeMapBackground> createState() => _HomeMapBackgroundState();
}

class _HomeMapBackgroundState extends ConsumerState<HomeMapBackground> {
  final Completer<GoogleMapController> _mapController = Completer();
  BitmapDescriptor? _carIcon;
  
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
    _loadMarkerIcon();
  }

  Future<void> _loadMarkerIcon() async {
    const size = 36.0; // Smaller icon for home screen
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      10,
      Paint()..color = Colors.white,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(size / 2, size / 2), width: 8, height: 14),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF2C2C2C),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (mounted) {
      setState(() {
        _carIcon = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(nearbyDriversProvider);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
        zoom: 14.5,
      ),
      style: _darkMapStyle,
      onMapCreated: (controller) => _mapController.complete(controller),
      markers: drivers.map((d) => Marker(
        markerId: MarkerId(d.latitude.toString() + d.longitude.toString()),
        position: LatLng(d.latitude, d.longitude),
        icon: _carIcon ?? BitmapDescriptor.defaultMarker,
        rotation: d.heading ?? 0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      )).toSet(),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}
