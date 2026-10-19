import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';

class QuickServicesPaymentDetails {
  final double subtotal;
  final double potentialDiscount;
  final double discount;
  final double finalTotal;
  final int coinsUsed;
  final int potentialCoins;
  final int balance;
  final int conversionRate;

  const QuickServicesPaymentDetails({
    required this.subtotal,
    required this.potentialDiscount,
    required this.discount,
    required this.finalTotal,
    required this.coinsUsed,
    required this.potentialCoins,
    required this.balance,
    required this.conversionRate,
  });
}

class QuickServicesCoinsHelper {
  static int getBalance(dynamic ref, {bool isWatching = false}) {
    final rewardSummary = isWatching
        ? ref.watch(rewardSummaryProvider).value
        : ref.read(rewardSummaryProvider).value;
    return rewardSummary?.currentPoints.toInt() ?? 0;
  }

  static int getConversionRate(dynamic ref, {bool isWatching = false}) {
    final rules = isWatching
        ? ref.watch(rewardRulesProvider).value
        : ref.read(rewardRulesProvider).value;
    return (rules?.redemption.pointsToEurRatio ?? 400.0).toInt();
  }

  static QuickServicesPaymentDetails getPaymentDetails({
    required dynamic ref,
    required double upfrontRaw,
    required bool useGoCoins,
    bool isWatching = false,
  }) {
    final int balance = getBalance(ref, isWatching: isWatching);
    final int conversionRate = getConversionRate(ref, isWatching: isWatching);

    final double maxEurValue = conversionRate > 0 ? (balance / conversionRate) : 0.0;
    final double appliedEurValue = maxEurValue > upfrontRaw ? upfrontRaw : maxEurValue;
    final int coinsUsed = (appliedEurValue * conversionRate).round();

    final double discount = useGoCoins ? appliedEurValue : 0.0;
    final double finalTotal = (upfrontRaw - discount).clamp(0.0, double.infinity);

    return QuickServicesPaymentDetails(
      subtotal: upfrontRaw,
      potentialDiscount: appliedEurValue,
      discount: discount,
      finalTotal: finalTotal,
      coinsUsed: useGoCoins ? coinsUsed : 0,
      potentialCoins: coinsUsed,
      balance: balance,
      conversionRate: conversionRate,
    );
  }
}
