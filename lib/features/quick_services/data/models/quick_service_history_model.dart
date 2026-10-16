import 'dart:convert';

class QuickServiceHistoryModel {
  final String id;
  final String serviceCategory;
  final String serviceTitle;
  final DateTime bookingDate;
  final String status;
  final Map<String, dynamic> options;
  final List<dynamic> addOns;
  final double upfrontFee;
  final double materialCost;
  final double discountAmount;
  final double totalAmount;
  final String? estimatedPrice;
  final String paymentMethod;
  final String? paymentMethodType;
  final Map<String, dynamic>? supplier;
  final String? requirements;
  final List<String>? images;
  final String? location;
  final String? userName;
  final String? userPhone;
  final String? userEmail;

  QuickServiceHistoryModel({
    required this.id,
    required this.serviceCategory,
    required this.serviceTitle,
    required this.bookingDate,
    required this.status,
    required this.options,
    required this.addOns,
    required this.upfrontFee,
    required this.materialCost,
    required this.discountAmount,
    required this.totalAmount,
    this.estimatedPrice,
    required this.paymentMethod,
    this.paymentMethodType,
    this.supplier,
    this.requirements,
    this.images,
    this.location,
    this.userName,
    this.userPhone,
    this.userEmail,
  });

  factory QuickServiceHistoryModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedOptions = {};
    if (json['options'] != null) {
      if (json['options'] is String) {
        try {
          parsedOptions = jsonDecode(json['options']);
        } catch (_) {}
      } else if (json['options'] is Map) {
        parsedOptions = Map<String, dynamic>.from(json['options']);
      }
    }

    List<dynamic> parsedAddOns = [];
    if (json['addOns'] != null) {
      if (json['addOns'] is String) {
        try {
          parsedAddOns = jsonDecode(json['addOns']);
        } catch (_) {}
      } else if (json['addOns'] is List) {
        parsedAddOns = List<dynamic>.from(json['addOns']);
      }
    }

    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is String) {
        try {
          final decoded = jsonDecode(json['images']);
          if (decoded is List) parsedImages = List<String>.from(decoded);
        } catch (_) {}
      } else if (json['images'] is List) {
        parsedImages = List<String>.from(json['images']);
      }
    }

    return QuickServiceHistoryModel(
      id: json['id'] ?? '',
      serviceCategory: json['serviceCategory'] ?? '',
      serviceTitle: json['serviceTitle'] ?? '',
      bookingDate: json['bookingDate'] != null ? DateTime.parse(json['bookingDate']).toLocal() : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      options: parsedOptions,
      addOns: parsedAddOns,
      upfrontFee: double.tryParse(json['upfrontFee']?.toString() ?? '') ?? 0.0,
      materialCost: double.tryParse(json['materialCost']?.toString() ?? '') ?? 0.0,
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? '') ?? 0.0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0.0,
      estimatedPrice: json['estimatedPrice'],
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      paymentMethodType: json['paymentMethodType'],
      supplier: json['supplier'],
      requirements: json['requirements'],
      images: parsedImages,
      location: json['location'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      userEmail: json['userEmail'],
    );
  }

  QuickServiceHistoryModel copyWith({
    String? status,
    String? paymentMethod,
    String? paymentMethodType,
    double? totalAmount,
    double? materialCost,
    Map<String, dynamic>? supplier,
    Map<String, dynamic>? options,
  }) {
    return QuickServiceHistoryModel(
      id: id,
      serviceCategory: serviceCategory,
      serviceTitle: serviceTitle,
      bookingDate: bookingDate,
      status: status ?? this.status,
      options: options ?? this.options,
      addOns: addOns,
      upfrontFee: upfrontFee,
      materialCost: materialCost ?? this.materialCost,
      discountAmount: discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      estimatedPrice: estimatedPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      supplier: supplier ?? this.supplier,
      requirements: requirements,
      images: images,
      location: location,
      userName: userName,
      userPhone: userPhone,
      userEmail: userEmail,
    );
  }

  String get displayTitle {
    final cat = serviceCategory.trim().toLowerCase();
    final title = serviceTitle.trim();
    final lowerTitle = title.toLowerCase();

    // 1. Vehicle Mechanic
    if (cat.contains('mechanic')) {
      if (lowerTitle == 'car' || lowerTitle == 'car mechanic' || lowerTitle.contains('car mechanic')) {
        return 'Car Mechanic';
      }
      if (lowerTitle == 'bike' || lowerTitle == 'bike mechanic' || lowerTitle.contains('bike mechanic')) {
        return 'Bike Mechanic';
      }
      if (lowerTitle == 'truck' || lowerTitle == 'truck mechanic' || lowerTitle.contains('truck mechanic')) {
        return 'Truck Mechanic';
      }

      final vehicles = options['Vehicles'];
      if (vehicles is List && vehicles.isNotEmpty && vehicles.first is Map) {
        final type = (vehicles.first['Type'] ?? '').toString().toLowerCase();
        if (type.contains('bike')) return 'Bike Mechanic';
        if (type.contains('truck')) return 'Truck Mechanic';
        if (type.contains('car')) return 'Car Mechanic';
      }
      if (options['Bike Type'] != null) return 'Bike Mechanic';
      if (options['Truck Type'] != null) return 'Truck Mechanic';
      if (options['Car Type'] != null) return 'Car Mechanic';

      return title.isNotEmpty && title.toLowerCase() != 'vehicle mechanic' ? title : 'Car Mechanic';
    }

    // 2. Vehicle Wash
    if (cat.contains('wash')) {
      if (lowerTitle == 'car' || lowerTitle == 'car wash' || lowerTitle.contains('car wash')) {
        return 'Car Wash';
      }
      if (lowerTitle == 'bike' || lowerTitle == 'bike wash' || lowerTitle.contains('bike wash')) {
        return 'Bike Wash';
      }
      if (lowerTitle == 'truck' || lowerTitle == 'truck wash' || lowerTitle.contains('truck wash')) {
        return 'Truck Wash';
      }

      final washVehicles = options['Car Wash Vehicles'];
      if (washVehicles is List && washVehicles.isNotEmpty && washVehicles.first is Map) {
        final type = (washVehicles.first['Type'] ?? '').toString().toLowerCase();
        if (type.contains('bike')) return 'Bike Wash';
        if (type.contains('truck')) return 'Truck Wash';
        if (type.contains('car')) return 'Car Wash';
      }
      if (options['Bike Type'] != null) return 'Bike Wash';
      if (options['Truck Type'] != null) return 'Truck Wash';
      if (options['Car Type'] != null) return 'Car Wash';

      return title.isNotEmpty && title.toLowerCase() != 'vehicle wash' ? title : 'Car Wash';
    }

    // Fallbacks if serviceTitle is just 'car', 'bike', 'truck'
    if (lowerTitle == 'car') return cat.contains('wash') ? 'Car Wash' : 'Car Mechanic';
    if (lowerTitle == 'bike') return cat.contains('wash') ? 'Bike Wash' : 'Bike Mechanic';
    if (lowerTitle == 'truck') return cat.contains('wash') ? 'Truck Wash' : 'Truck Mechanic';

    // 3. PC & Mobile Repair
    if (cat.contains('pc') || cat.contains('mobile')) {
      if (lowerTitle == 'mobile' || lowerTitle == 'mobile repair' || lowerTitle.contains('mobile')) {
        return 'Mobile Repair';
      }
      if (lowerTitle.contains('laptop') || lowerTitle.contains('computer')) {
        return 'Computer & Laptop Repair';
      }
      if (lowerTitle.contains('printer') || lowerTitle.contains('scanner')) {
        return 'Printer & Scanner Repair';
      }
      if (options['Mobile Devices'] != null) return 'Mobile Repair';
      if (options['Computer Devices'] != null) return 'Computer & Laptop Repair';
      if (options['Printer Devices'] != null) return 'Printer & Scanner Repair';
    }

    // 4. Laundry
    if (cat.contains('laundry')) {
      if (lowerTitle == 'home' || lowerTitle == 'home laundry') return 'Home Laundry';
      if (lowerTitle == 'hospital' || lowerTitle == 'hospital laundry') return 'Hospital Laundry';
      if (lowerTitle == 'hotel' || lowerTitle == 'hotel laundry') return 'Hotel Laundry';
      if (lowerTitle.contains('commercial')) return 'Commercial Laundry';
      if (title.isNotEmpty) return lowerTitle.endsWith('laundry') ? title : '$title Laundry';
    }

    // 5. Electrical Repair
    if (cat.contains('electrical') || cat.contains('electric')) {
      if (lowerTitle == 'home' || lowerTitle == 'home electric') return 'Home Electric';
      if (lowerTitle.contains('commercial') || lowerTitle.contains('lift') || lowerTitle.contains('elevator')) {
        return 'Commercial Electric';
      }
      if (lowerTitle.contains('event')) return 'Events Electric';
    }

    // 6. Beauty & Wellness
    if (cat.contains('beauty') || cat.contains('wellness') || lowerTitle.contains('beauty') || lowerTitle.contains('wellness')) {
      if (title.contains('•')) return title;
      if (lowerTitle == 'female' || lowerTitle == 'male' || lowerTitle == 'kids' || lowerTitle == 'others') {
        return 'Beauty & Wellness • $title';
      }
      return 'Beauty & Wellness';
    }

    if (title.isNotEmpty) return title;
    return serviceCategory.isNotEmpty ? serviceCategory : 'Quick Service';
  }
}

