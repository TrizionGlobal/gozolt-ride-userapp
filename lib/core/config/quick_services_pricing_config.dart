class QuickServicesPricingConfig {
  // Default values for any service that doesn't have a specific rate yet
  static const double defaultHourlyRate = 6.00;
  static const double defaultBaseHours = 1.0;
  static const double defaultMaterialCost = 10.00;
  static const double defaultUpfrontBookingFee = 5.00;
  
  // Specific hourly rates per service category (Use these keys in details screens)
  static Map<String, dynamic> serviceRates = {};

  static void updateRates(List<dynamic> rules) {
    for (var rule in rules) {
      final key = rule['serviceKey'];
      if (key != null) {
        serviceRates[key] = {
          'minHourlyRate': (rule['minHourlyRate'] != null) ? double.parse(rule['minHourlyRate'].toString()) : null,
          'upfrontFee': (rule['upfrontFee'] != null) ? double.parse(rule['upfrontFee'].toString()) : null,
          'materialCost': (rule['materialCost'] != null) ? double.parse(rule['materialCost'].toString()) : null,
          'pickupFee': (rule['pickupFee'] != null) ? double.parse(rule['pickupFee'].toString()) : null,
          'estimatedSparePrice': rule['estimatedSparePrice'],
        };
      }
    }
  }

  static double getMinRate(String serviceKey) {
    return serviceRates[serviceKey]?['minHourlyRate'] ?? defaultHourlyRate;
  }

  static double? getMaxRate(String serviceKey) {
    return serviceRates[serviceKey]?['maxHourlyRate'];
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
      if (selectedServiceTitle?.contains('Commercial') == true || selectedServiceTitle?.contains('Lift') == true || selectedServiceTitle?.contains('Events') == true) {
        return 'Mechanic Visit/hr';
      }
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
    return serviceRates[serviceKey]?['materialCost'] ?? defaultMaterialCost;
  }

  static double getUpfrontFee(String serviceKey) {
    return serviceRates[serviceKey]?['upfrontFee'] ?? defaultUpfrontBookingFee;
  }

  static double getPickupFee(String serviceKey) {
    return serviceRates[serviceKey]?['pickupFee'] ?? 10.00;
  }

  static String? getEstimatedSparePrice(String serviceKey) {
    return serviceRates[serviceKey]?['estimatedSparePrice'];
  }
}
