import 'package:flutter/material.dart';
import '../../data/models/saved_payment_method.dart';

/// Styled widget-based brand icons since no image assets are available.
/// Supports all CardBrand enum values at a consistent 24x24 default size.
class PaymentBrandIcon extends StatelessWidget {
  final CardBrand brand;
  final double size;

  const PaymentBrandIcon({
    super.key,
    required this.brand,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.65,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            color: _textColor,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Color get _bgColor => switch (brand) {
        CardBrand.visa => const Color(0xFF1A1F71),
        CardBrand.mastercard => const Color(0xFF2D2D2D),
        CardBrand.amex => const Color(0xFF2E77BC),
        CardBrand.unknown => const Color(0xFF3D3D3D),
      };

  Color get _textColor => switch (brand) {
        CardBrand.visa => Colors.white,
        CardBrand.mastercard => const Color(0xFFFF5F00),
        CardBrand.amex => Colors.white,
        CardBrand.unknown => Colors.white70,
      };

  String get _label => switch (brand) {
        CardBrand.visa => 'VISA',
        CardBrand.mastercard => 'MC',
        CardBrand.amex => 'AMEX',
        CardBrand.unknown => 'CARD',
      };
}

/// Convenience widget for rendering a payment icon from a string brand name.
/// Useful for the account-side SavedPaymentMethod which uses String brand.
class PaymentBrandIconFromString extends StatelessWidget {
  final String brand;
  final double size;

  const PaymentBrandIconFromString({
    super.key,
    required this.brand,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return PaymentBrandIcon(
      brand: _parseBrand(brand),
      size: size,
    );
  }

  static CardBrand _parseBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
        return CardBrand.mastercard;
      case 'amex':
        return CardBrand.amex;
      default:
        return CardBrand.unknown;
    }
  }
}
