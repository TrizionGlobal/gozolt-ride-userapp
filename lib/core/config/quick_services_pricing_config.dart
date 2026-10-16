import 'package:flutter/foundation.dart';

class QuickServicesPricingConfig {
  // Notifier to trigger automatic UI re-renders whenever rates are updated
  static final ValueNotifier<int> ratesVersion = ValueNotifier<int>(0);

  // Default values for any service that doesn't have a specific rate yet
  static const double defaultHourlyRate = 6.00;
  static const double defaultBaseHours = 1.0;
  static const double defaultMaterialCost = 10.00;
  static const double defaultUpfrontBookingFee = 5.00;
  
  // Specific hourly rates per service category (Use these keys in details screens)
  static Map<String, dynamic> serviceRates = {};

  static void updateRates(List<dynamic> rules) {
    for (var rule in rules) {
      final key = rule['serviceKey']?.toString();
      if (key != null) {
        final rate = {
          'minHourlyRate': (rule['minHourlyRate'] != null) ? double.tryParse(rule['minHourlyRate'].toString()) : null,
          'upfrontFee': (rule['upfrontFee'] != null) ? double.tryParse(rule['upfrontFee'].toString()) : null,
          'materialCost': (rule['materialCost'] != null) ? double.tryParse(rule['materialCost'].toString()) : null,
          'pickupFee': (rule['pickupFee'] != null) ? double.tryParse(rule['pickupFee'].toString()) : null,
          'estimatedSparePrice': rule['estimatedSparePrice'],
        };
        serviceRates[key] = rate;
        // Also register normalized key variants
        serviceRates[key.toLowerCase()] = rate;
        serviceRates[key.toLowerCase().replaceAll('_', ' ')] = rate;
      }
    }
    ratesVersion.value++;
  }

  static Map<String, dynamic>? findRate(String serviceKey) {
    if (serviceRates.containsKey(serviceKey)) {
      return serviceRates[serviceKey];
    }
    
    // Normalize: lowercase, replace spaces, slashes, ampersands, dashes with underscore
    final normalized = serviceKey
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
        
    if (serviceRates.containsKey(normalized)) {
      return serviceRates[normalized];
    }

    // Common category/subservice mappings to DB serviceKey
    const aliases = {
      'appliance_repair': 'appliance_repair',
      'appliance': 'appliance_repair',
      'plumbing': 'plumber',
      'plumber': 'plumber',
      'carpenter': 'carpenter',
      'carpentry': 'carpenter',
      'cleaning': 'home_cleaning',
      'home_cleaning': 'home_cleaning',
      'home_services': 'home_cleaning',
      'home_service': 'home_cleaning',
      'gardening': 'gardening',
      'pest_control': 'pest_control',
      'painter': 'painter',
      'painting': 'painter',
      'beauty': 'beauty_wellness',
      'wellness': 'beauty_wellness',
      'beautician': 'beauty_wellness',
      'beautician_wellness': 'beauty_wellness',
      'beauty_wellness': 'beauty_wellness',
      'hire_person': 'hire_person',
      'hire_a_person': 'hire_person',
      'security': 'security_personnel',
      'bouncer': 'security_personnel',
      'security_bouncer': 'security_personnel',
      'security_personnel': 'security_personnel',
      'computer': 'computer_repair',
      'laptop': 'computer_repair',
      'pc_mobile': 'computer_repair',
      'pc_mobile_repair': 'computer_repair',
      'computer_repair': 'computer_repair',
      'mobile': 'mobile_repair',
      'mobile_repair': 'mobile_repair',
      'printer': 'printer_scanner',
      'printer_scanner': 'printer_scanner',
      'car_mechanic': 'car_mechanic',
      'bike_mechanic': 'bike_mechanic',
      'truck_mechanic': 'truck_mechanic',
      'vehicle_mechanic': 'car_mechanic',
      'car_wash': 'car_wash',
      'bike_wash': 'bike_wash',
      'truck_wash': 'truck_wash',
      'vehicle_wash': 'car_wash',
      'home_electric': 'home_electric',
      'electrical': 'home_electric',
      'electrical_repair': 'home_electric',
      'commercial_electric': 'commercial_electric',
      'events_electric': 'events_electric',
      'lift_elevator_mechanic': 'commercial_electric',
      'laundry': 'laundry',
      'hospital_laundry': 'hospital_laundry',
      'hotel_laundry': 'hotel_laundry',
      'commercial_laundry': 'commercial_laundry',
      'event_organisers': 'event_organisers',
      'suppliers': 'suppliers',
      'other_services': 'event_organisers',
    };

    if (aliases.containsKey(normalized)) {
      final targetKey = aliases[normalized]!;
      if (serviceRates.containsKey(targetKey)) {
        return serviceRates[targetKey];
      }
    }

    // Try fuzzy/substring matching across keys
    for (var entry in serviceRates.entries) {
      final k = entry.key.toLowerCase();
      if (normalized.contains(k) || k.contains(normalized)) {
        return entry.value;
      }
    }

    return null;
  }

  static double getMinRate(String serviceKey) {
    final rate = findRate(serviceKey);
    return rate?['minHourlyRate'] ?? defaultHourlyRate;
  }

  static double? getMaxRate(String serviceKey) {
    final rate = findRate(serviceKey);
    return rate?['maxHourlyRate'];
  }

  static String expertVisitName(String category, {String? selectedServiceTitle}) {
    final lowerCat = category.toLowerCase();
    final lowerTitle = selectedServiceTitle?.toLowerCase() ?? '';
    
    if (lowerTitle == 'painter' || lowerTitle == 'event organisers' || lowerTitle == 'suppliers' || lowerCat == 'other services') {
      return 'Service Agent/hr';
    }
    
    if (lowerCat.contains('beauty') || lowerCat.contains('wellness')) {
      return 'Specialist Visit/hr';
    }
    
    if (lowerCat.contains('security') || lowerCat.contains('bouncer') || lowerCat.contains('hire') || lowerCat.contains('person')) {
      return 'Hiring Person/hr';
    } else if (lowerCat.contains('mechanic')) {
      return 'Mechanic Visit/hr';
    } else if (lowerCat.contains('electric')) {
      return 'Expert Visit/hr';
    } else if (lowerCat.contains('engineer') || 
               lowerCat.contains('computer') ||
               lowerCat.contains('printer') ||
               lowerCat.contains('mobile') ||
               lowerCat.contains('technician')) {
      return 'Engineer Visit/hr';
    } else if (lowerCat.contains('wash')) {
      return 'Service Agent Visit/hr';
    }
    return 'Expert Visit/hr';
  }

  static double getMaterialCost(String serviceKey) {
    final rate = findRate(serviceKey);
    return rate?['materialCost'] ?? defaultMaterialCost;
  }

  static double getUpfrontFee(String serviceKey) {
    final rate = findRate(serviceKey);
    return rate?['upfrontFee'] ?? defaultUpfrontBookingFee;
  }

  static double getPickupFee(String serviceKey) {
    final rate = findRate(serviceKey);
    return rate?['pickupFee'] ?? 10.00;
  }

  static String? getEstimatedSparePrice(String serviceKey) {
    final rate = findRate(serviceKey);
    return rate?['estimatedSparePrice'];
  }
}
