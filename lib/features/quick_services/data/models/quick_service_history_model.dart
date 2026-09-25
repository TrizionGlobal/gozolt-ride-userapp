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
      bookingDate: json['bookingDate'] != null ? DateTime.parse(json['bookingDate']) : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      options: parsedOptions,
      addOns: parsedAddOns,
      upfrontFee: double.tryParse(json['upfrontFee']?.toString() ?? '') ?? 0.0,
      materialCost: double.tryParse(json['materialCost']?.toString() ?? '') ?? 0.0,
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? '') ?? 0.0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0.0,
      estimatedPrice: json['estimatedPrice'],
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      supplier: json['supplier'],
      requirements: json['requirements'],
      images: parsedImages,
      location: json['location'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      userEmail: json['userEmail'],
    );
  }
}
