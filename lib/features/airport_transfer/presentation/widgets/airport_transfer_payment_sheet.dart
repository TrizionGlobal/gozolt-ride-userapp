import 'package:flutter/material.dart';
import '../../../../core/widgets/service_payment_sheet.dart';

typedef AirportPaymentOption = ServicePaymentOption;

class AirportTransferPaymentSheet extends StatelessWidget {
  final double amount;
  final String? initialCardId;
  final AirportPaymentOption initialOption;
  final Future<bool> Function(AirportPaymentOption option, {String? cardId}) onConfirm;

  const AirportTransferPaymentSheet({
    super.key,
    required this.amount,
    this.initialCardId,
    this.initialOption = AirportPaymentOption.card,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ServicePaymentSheet(
      amount: amount,
      serviceTitle: 'Airport Transfer',
      initialCardId: initialCardId,
      initialOption: initialOption,
      onConfirm: onConfirm,
    );
  }
}
