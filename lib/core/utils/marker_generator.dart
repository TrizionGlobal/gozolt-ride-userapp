import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  static Future<BitmapDescriptor> createPickupMarker() async {
    const int size = 48; // Adjust size for density (e.g., 24dp at 2x)
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.black;
    final Paint paintWhite = Paint()..color = Colors.white;

    // Draw white outer circle (border)
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, paintWhite);
    // Draw black inner circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0 - 4, paint);

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> createDropoffMarker() async {
    const int size = 48; 
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.black;
    final Paint paintWhite = Paint()..color = Colors.white;

    // Draw white outer square (border)
    canvas.drawRect(const Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paintWhite);
    // Draw black inner square
    canvas.drawRect(const Rect.fromLTWH(4, 4, size - 8.0, size - 8.0), paint);

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
