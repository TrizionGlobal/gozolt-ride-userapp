class PromoValidation {
  final bool isValid;
  final String? code;
  final String? description;
  final double? discountAmount;
  final double? discountPercent;
  final double? maxDiscount;
  final String? validUntil;
  final String? errorMessage;

  const PromoValidation({
    required this.isValid,
    this.code,
    this.description,
    this.discountAmount,
    this.discountPercent,
    this.maxDiscount,
    this.validUntil,
    this.errorMessage,
  });

  factory PromoValidation.fromJson(Map<String, dynamic> json) {
    return PromoValidation(
      isValid: json['isValid'] as bool? ?? false,
      code: json['code'] as String?,
      description: json['description'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      validUntil: json['validUntil'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
