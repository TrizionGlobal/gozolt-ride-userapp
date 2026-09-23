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
  final double totalAmount;
  final String paymentMethod;
  final Map<String, dynamic>? supplier;

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
    required this.totalAmount,
    required this.paymentMethod,
    this.supplier,
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

    return QuickServiceHistoryModel(
      id: json['id'] ?? '',
      serviceCategory: json['serviceCategory'] ?? '',
      serviceTitle: json['serviceTitle'] ?? '',
      bookingDate: json['bookingDate'] != null ? DateTime.parse(json['bookingDate']) : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      options: parsedOptions,
      addOns: parsedAddOns,
      upfrontFee: (json['upfrontFee'] ?? 0.0).toDouble(),
      materialCost: (json['materialCost'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      supplier: json['supplier'],
    );
  }
}
