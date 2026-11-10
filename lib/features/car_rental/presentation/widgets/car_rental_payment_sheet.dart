import 'package:flutter/material.dart';
import '../../../../core/widgets/service_payment_sheet.dart';

typedef RentalPaymentOption = ServicePaymentOption;

class CarRentalPaymentSheet extends StatelessWidget {
  final double amount;
  final String? initialCardId;
  final RentalPaymentOption initialOption;
  final Future<bool> Function(RentalPaymentOption option, {String? cardId}) onConfirm;

  const CarRentalPaymentSheet({
    super.key,
    required this.amount,
    this.initialCardId,
    this.initialOption = RentalPaymentOption.card,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ServicePaymentSheet(
      amount: amount,
      serviceTitle: 'Car Rental',
      initialCardId: initialCardId,
      initialOption: initialOption,
      onConfirm: onConfirm,
    );
  }
}
