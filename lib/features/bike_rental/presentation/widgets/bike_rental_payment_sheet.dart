import 'package:flutter/material.dart';
import '../../../../core/widgets/service_payment_sheet.dart';

typedef BikeRentalPaymentOption = ServicePaymentOption;

class BikeRentalPaymentSheet extends StatelessWidget {
  final double amount;
  final String? initialCardId;
  final BikeRentalPaymentOption initialOption;
  final Future<bool> Function(BikeRentalPaymentOption option, {String? cardId}) onConfirm;

  const BikeRentalPaymentSheet({
    super.key,
    required this.amount,
    this.initialCardId,
    this.initialOption = BikeRentalPaymentOption.card,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ServicePaymentSheet(
      amount: amount,
      serviceTitle: 'Bike Rental',
      initialCardId: initialCardId,
      initialOption: initialOption,
      onConfirm: onConfirm,
    );
  }
}
