class QuickServicesPricingConfig {
  // Default values for any service that doesn't have a specific rate yet
  static const double defaultHourlyRate = 6.00;
  static const double defaultBaseHours = 1.0;
  static const double defaultMaterialCost = 10.00;
  static const double defaultUpfrontBookingFee = 5.00;
  
  // Specific hourly rates per service category (Use these keys in details screens)
  static const Map<String, dynamic> serviceRates = {
    // Technical Services
    'electrical_technician': {'minHourlyRate': 6.00},
    'ac_installer': {'minHourlyRate': 6.00},
    'plumber': {'minHourlyRate': 20.00, 'upfrontFee': 5.00, 'materialCost': 10.00},
    
    // Fallbacks
    'home_cleaning': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 10.00},
    'carpenter': {'minHourlyRate': 20.00, 'upfrontFee': 5.00, 'materialCost': 10.00},

    'pest_control': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 5.00},
    'gardening': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 5.00},
    'computer_repair': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'materialCost': 0.00, 'estimatedSparePrice': '€50 - €110'},
    'vehicle_mechanic': {'minHourlyRate': 6.00},
    'truck_wash': {'minHourlyRate': 8.00, 'upfrontFee': 5.00, 'materialCost': 15.00, 'pickupFee': 8.00},
    'car_wash': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 8.00, 'pickupFee': 6.00},
    'bike_wash': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 5.00, 'pickupFee': 6.00},
    'commercial_electric': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'estimatedSparePrice': '€5 - €25'},
    'home_electric': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'estimatedSparePrice': '€5 - €25'},
    'events_electric': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'estimatedSparePrice': '€5 - €25'},
    'lift_elevator_mechanic': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'estimatedSparePrice': '€5 - €25'},
    'security_personnel': {'minHourlyRate': 7.00, 'upfrontFee': 5.00, 'materialCost': 0.00},
    'hotel_laundry': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 15.00, 'pickupFee': 10.00},
    'commercial_laundry': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 10.00, 'pickupFee': 10.00},
    'hospital_laundry': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 15.00, 'pickupFee': 10.00},
    'laundry': {'minHourlyRate': 6.00, 'upfrontFee': 5.00, 'materialCost': 5.00, 'pickupFee': 10.00},
    'appliance_repair': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'estimatedSparePrice': '€20 - €40'},
    'painter': {'minHourlyRate': 6.00},
    'suppliers': {'minHourlyRate': 6.00},
    'event_organisers': {'minHourlyRate': 6.00},
    'printer_scanner': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'materialCost': 0.00, 'estimatedSparePrice': '€25 - €50'},
    'mobile_repair': {'minHourlyRate': 10.00, 'upfrontFee': 5.00, 'materialCost': 0.00, 'estimatedSparePrice': '€40 - €80'},
    'bike_mechanic': {'minHourlyRate': 8.00, 'upfrontFee': 5.00, 'materialCost': 10.00, 'estimatedSparePrice': '€25 - €50'},
    'car_mechanic': {'minHourlyRate': 9.00, 'upfrontFee': 5.00, 'materialCost': 10.00, 'estimatedSparePrice': '€50 - €110'},
    'truck_mechanic': {'minHourlyRate': 9.00, 'upfrontFee': 5.00, 'materialCost': 10.00, 'estimatedSparePrice': '€50 - €110'},
    'hire_person': {'minHourlyRate': 7.00, 'upfrontFee': 5.00, 'materialCost': 0.00},
    'other_services': {'minHourlyRate': 6.00},
  };

  static double getMinRate(String serviceKey) {
    return serviceRates[serviceKey]?['minHourlyRate'] ?? defaultHourlyRate;
  }

  static double? getMaxRate(String serviceKey) {
    return serviceRates[serviceKey]?['maxHourlyRate'];
  }

  static String expertVisitName(String category, {String? selectedServiceTitle}) {
    final lowerCat = category.toLowerCase();
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
