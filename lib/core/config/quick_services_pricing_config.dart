class QuickServicesPricingConfig {
  // Default values for any service that doesn't have a specific rate yet
  static const double defaultHourlyRate = 13.50;
  static const double defaultBaseHours = 1.0;
  
  // Specific hourly rates per service category (Use these keys in details screens)
  static const Map<String, dynamic> serviceRates = {
    // Technical Services
    'electrical_technician': {'minHourlyRate': 13.50},
    'ac_installer': {'minHourlyRate': 13.50},
    'plumber': {'minHourlyRate': 10.50, 'maxHourlyRate': 13.50},
    
    // Fallbacks
    'home_cleaning': {'minHourlyRate': 13.50},
    'carpenter': {'minHourlyRate': 13.50},
    'handyman': {'minHourlyRate': 13.50},
    'pest_control': {'minHourlyRate': 13.50},
    'gardening': {'minHourlyRate': 13.50},
    'computer_repair': {'minHourlyRate': 13.50},
    'vehicle_mechanic': {'minHourlyRate': 13.50},
    'truck_wash': {'minHourlyRate': 13.50},
    'car_wash': {'minHourlyRate': 13.50},
    'home_electric': {'minHourlyRate': 13.50},
    'lift_elevator_mechanic': {'minHourlyRate': 13.50},
    'security_personnel': {'minHourlyRate': 13.50},
    'hotel_laundry': {'minHourlyRate': 13.50},
    'commercial_laundry': {'minHourlyRate': 13.50},
    'hospital_laundry': {'minHourlyRate': 13.50},
    'laundry': {'minHourlyRate': 13.50},
    'appliance_repair': {'minHourlyRate': 13.50},
    'painter': {'minHourlyRate': 13.50},
    'suppliers': {'minHourlyRate': 13.50},
    'event_organisers': {'minHourlyRate': 13.50},
    'printer_scanner': {'minHourlyRate': 13.50},
    'mobile_repair': {'minHourlyRate': 13.50},
    'bike_mechanic': {'minHourlyRate': 13.50},
    'car_mechanic': {'minHourlyRate': 13.50},
    'truck_mechanic': {'minHourlyRate': 13.50},
    'hire_person': {'minHourlyRate': 13.50},
    'other_services': {'minHourlyRate': 13.50},
  };

  static double getMinRate(String serviceKey) {
    return serviceRates[serviceKey]?['minHourlyRate'] ?? defaultHourlyRate;
  }

  static double? getMaxRate(String serviceKey) {
    return serviceRates[serviceKey]?['maxHourlyRate'];
  }
}
