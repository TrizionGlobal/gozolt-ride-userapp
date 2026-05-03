import 'package:flutter_test/flutter_test.dart';
import 'package:gozolt_user_app/features/ride/data/models/saved_payment_method.dart';

void main() {
  group('CardBrand.fromString', () {
    test('returns visa for "visa"', () {
      expect(CardBrand.fromString('visa'), CardBrand.visa);
    });

    test('returns visa for "Visa" (case-insensitive)', () {
      expect(CardBrand.fromString('Visa'), CardBrand.visa);
    });

    test('returns mastercard for "mastercard"', () {
      expect(CardBrand.fromString('mastercard'), CardBrand.mastercard);
    });

    test('returns amex for "amex"', () {
      expect(CardBrand.fromString('amex'), CardBrand.amex);
    });

    test('returns amex for "american_express"', () {
      expect(CardBrand.fromString('american_express'), CardBrand.amex);
    });

    test('returns unknown for null', () {
      expect(CardBrand.fromString(null), CardBrand.unknown);
    });

    test('returns unknown for unrecognized string', () {
      expect(CardBrand.fromString('discover'), CardBrand.unknown);
    });
  });

  group('SavedPaymentMethod.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'id': 'pm_123',
        'brand': 'visa',
        'last4': '4242',
        'expMonth': 12,
        'expYear': 2026,
        'isDefault': true,
      };

      final pm = SavedPaymentMethod.fromJson(json);

      expect(pm.id, 'pm_123');
      expect(pm.brand, CardBrand.visa);
      expect(pm.last4, '4242');
      expect(pm.expMonth, 12);
      expect(pm.expYear, 2026);
      expect(pm.isDefault, true);
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 'pm_456',
        'brand': null,
        'last4': null,
        'expMonth': null,
        'expYear': null,
      };

      final pm = SavedPaymentMethod.fromJson(json);

      expect(pm.brand, CardBrand.unknown);
      expect(pm.last4, '****');
      expect(pm.expMonth, 0);
      expect(pm.expYear, 0);
      expect(pm.isDefault, false);
    });
  });

  group('SavedPaymentMethod getters', () {
    test('displayName formats correctly for Visa', () {
      const pm = SavedPaymentMethod(
        id: 'pm_1',
        brand: CardBrand.visa,
        last4: '4242',
        expMonth: 12,
        expYear: 2026,
      );
      expect(pm.displayName, 'Visa ···· 4242');
    });

    test('displayName formats correctly for Mastercard', () {
      const pm = SavedPaymentMethod(
        id: 'pm_2',
        brand: CardBrand.mastercard,
        last4: '5567',
        expMonth: 6,
        expYear: 2027,
      );
      expect(pm.displayName, 'Mastercard ···· 5567');
    });

    test('displayName formats correctly for unknown brand', () {
      const pm = SavedPaymentMethod(
        id: 'pm_3',
        brand: CardBrand.unknown,
        last4: '9999',
        expMonth: 1,
        expYear: 2025,
      );
      expect(pm.displayName, 'Card ···· 9999');
    });

    test('maskedNumber returns correct format', () {
      const pm = SavedPaymentMethod(
        id: 'pm_1',
        brand: CardBrand.visa,
        last4: '4242',
        expMonth: 12,
        expYear: 2026,
      );
      expect(pm.maskedNumber, 'XXXX XXXX XXXX 4242');
    });
  });
}
