import 'package:flutter/material.dart';
import '../../../ride/data/models/location_data.dart';

class QuickServicesBookingDraft {
  static DateTime? selectedDate;
  static TimeOfDay? selectedTime;
  static LocationData? selectedLocation;

  static String? userName;
  static String? userPhone;
  static String? userEmail;

  static void reset() {
    selectedDate = null;
    selectedTime = null;
    selectedLocation = null;
    userName = null;
    userPhone = null;
    userEmail = null;
  }

  static bool validate(BuildContext context) {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service date.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service time.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service location.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }
}
