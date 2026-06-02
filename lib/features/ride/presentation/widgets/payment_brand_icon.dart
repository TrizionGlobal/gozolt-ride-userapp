import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/models/saved_payment_method.dart';

/// Styled widget-based brand icons since no image assets are available.
/// Supports all CardBrand enum values at a consistent 24x24 default size.
class PaymentBrandIcon extends StatelessWidget {
  final CardBrand brand;
  final double size;

  const PaymentBrandIcon({
    super.key,
    required this.brand,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = _getPrimaryColor(brand, isDark);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: _buildDynamicLogo(primaryColor),
      ),
    );
  }

  Widget _buildDynamicLogo(Color primaryColor) {
    switch (brand) {
      case CardBrand.visa:
        return FaIcon(FontAwesomeIcons.ccVisa, color: primaryColor, size: size * 0.55);
      case CardBrand.mastercard:
        return FaIcon(FontAwesomeIcons.ccMastercard, color: primaryColor, size: size * 0.55);
      case CardBrand.amex:
        return FaIcon(FontAwesomeIcons.ccAmex, color: primaryColor, size: size * 0.55);
      default:
        return Icon(Icons.credit_card, color: primaryColor, size: size * 0.50);
    }
  }

  Color _getPrimaryColor(CardBrand brand, bool isDark) {
    return switch (brand) {
      CardBrand.visa => isDark ? const Color(0xFF90CAF9) : const Color(0xFF1A1F71),
      CardBrand.mastercard => const Color(0xFFFF5F00),
      CardBrand.amex => isDark ? const Color(0xFF90CAF9) : const Color(0xFF2E77BC),
      CardBrand.unknown => isDark ? Colors.grey[300]! : Colors.grey[800]!,
    };
  }


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
