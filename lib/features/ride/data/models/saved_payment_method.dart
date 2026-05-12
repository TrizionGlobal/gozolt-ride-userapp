enum CardBrand {
  visa,
  mastercard,
  amex,
  unknown;

  static CardBrand fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
        return CardBrand.mastercard;
      case 'amex':
      case 'american_express':
        return CardBrand.amex;
      default:
        return CardBrand.unknown;
    }
  }
}

enum PaymentMethodType {
  cash,
  card,
  upi,
  wallet;
}

class SavedPaymentMethod {
  final String id;
  final CardBrand brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  const SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  String get displayName {
    final brandName = switch (brand) {
      CardBrand.visa => 'Visa',
      CardBrand.mastercard => 'Mastercard',
      CardBrand.amex => 'Amex',
      CardBrand.unknown => 'Card',
    };
    return '$brandName ···· $last4';
  }

  String get maskedNumber => 'XXXX XXXX XXXX $last4';

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String,
      brand: CardBrand.fromString(json['brand'] as String?),
      last4: json['last4'] as String? ?? '****',
      expMonth: (json['expMonth'] as num?)?.toInt() ?? 0,
      expYear: (json['expYear'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
