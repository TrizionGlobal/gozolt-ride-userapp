import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/food_grocery_delivery_verification_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryDeliveryArrivalScreen extends ConsumerStatefulWidget {
  const FoodGroceryDeliveryArrivalScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryDeliveryArrivalScreen> createState() =>
      _FoodGroceryDeliveryArrivalScreenState();
}

class _FoodGroceryDeliveryArrivalScreenState
    extends ConsumerState<FoodGroceryDeliveryArrivalScreen> {
  Future<void> _confirmOrderReceived() async {
    final state = ref.read(
      foodGroceryDeliveryVerificationProvider,
    );

    if (state.paymentStatus == FoodGroceryDeliveryPaymentStatus.cashDue) {
      context.pushReplacementNamed(
        RouteNames.foodGroceryOrderCompleted,
      );

      return;
    }

    await ref
        .read(
          foodGroceryDeliveryVerificationProvider.notifier,
        )
        .confirmOrderReceived();

    if (!mounted) {
      return;
    }

    context.pushReplacementNamed(
      RouteNames.foodGroceryOrderCompleted,
    );
  }

  void _markTemporaryCashCollected() {
    ref
        .read(
          foodGroceryDeliveryVerificationProvider.notifier,
        )
        .markCashCollected();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Cash payment marked as collected for UI testing.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final verificationState = ref.watch(
      foodGroceryDeliveryVerificationProvider,
    );

    final orderReference = verificationState.orderId.trim().isEmpty
        ? 'Pending'
        : verificationState.orderId;

    final qrData = '''
GOZOLT FOOD & GROCERY
Order Reference: $orderReference
Delivery PIN: ${verificationState.verificationCode}
Delivery Status: Partner Arrived
'''
        .trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Delivery Arrival',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                28,
              ),
              children: [
                _ArrivalStatusCard(
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _VerificationCard(
                  isDark: isDark,
                  orderReference: orderReference,
                  verificationCode: verificationState.verificationCode,
                  qrData: qrData,
                ),
                const SizedBox(height: 14),
                _PaymentStatusCard(
                  isDark: isDark,
                  state: verificationState,
                  onTemporaryCashCollected: _markTemporaryCashCollected,
                ),
                const SizedBox(height: 14),
                _SafetyNoticeCard(
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: verificationState.isConfirming ||
                      verificationState.isOrderReceived
                  ? null
                  : _confirmOrderReceived,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                disabledBackgroundColor:
                    isDark ? AppColors.surfaceDark : Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: verificationState.isConfirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.backgroundDark,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          verificationState.isOrderReceived
                              ? Icons.check_circle_outline_rounded
                              : Icons.inventory_2_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          verificationState.isOrderReceived
                              ? 'ORDER RECEIVED'
                              : 'CONFIRM ORDER RECEIVED',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrivalStatusCard extends StatelessWidget {
  const _ArrivalStatusCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(
          alpha: isDark ? 0.14 : 0.10,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 31,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Your delivery has arrived',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Meet your GOZOLT delivery partner and verify the order.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.isDark,
    required this.orderReference,
    required this.verificationCode,
    required this.qrData,
  });

  final bool isDark;
  final String orderReference;
  final String verificationCode;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'DELIVERY VERIFICATION',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryGoldDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            orderReference,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.primaryGold.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primaryGoldDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'OR SHARE THIS DELIVERY PIN',
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: verificationCode
                .split('')
                .map(
                  (number) => Container(
                    width: 42,
                    height: 48,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: AppColors.primaryGold,
                      ),
                    ),
                    child: Text(
                      number,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.backgroundDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 11),
          Text(
            'Show the QR code or tell the PIN only after receiving your complete order.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  const _PaymentStatusCard({
    required this.isDark,
    required this.state,
    required this.onTemporaryCashCollected,
  });

  final bool isDark;
  final FoodGroceryDeliveryVerificationState state;
  final VoidCallback onTemporaryCashCollected;

  @override
  Widget build(BuildContext context) {
    final String paymentMethod;
    final String paymentStatus;
    final IconData paymentIcon;
    final Color statusColor;

    switch (state.paymentStatus) {
      case FoodGroceryDeliveryPaymentStatus.paidOnline:
        paymentMethod = 'Card';
        paymentStatus = 'Paid online';
        paymentIcon = Icons.credit_card_rounded;
        statusColor = AppColors.success;

      case FoodGroceryDeliveryPaymentStatus.cashDue:
        paymentMethod = 'Cash';
        paymentStatus = '€${state.amount.toStringAsFixed(2)} to be paid';
        paymentIcon = Icons.payments_outlined;
        statusColor = AppColors.primaryGoldDark;

      case FoodGroceryDeliveryPaymentStatus.cashCollected:
        paymentMethod = 'Cash';
        paymentStatus = 'Cash payment completed';
        paymentIcon = Icons.check_circle_outline_rounded;
        statusColor = AppColors.success;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _DeliveryInformationRow(
            isDark: isDark,
            icon: paymentIcon,
            label: 'Payment method',
            value: paymentMethod,
            valueColor:
                isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          _DeliveryInformationRow(
            isDark: isDark,
            icon: Icons.verified_outlined,
            label: 'Payment status',
            value: paymentStatus,
            valueColor: statusColor,
          ),
          if (state.paymentStatus ==
              FoodGroceryDeliveryPaymentStatus.cashDue) ...[
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: onTemporaryCashCollected,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGoldDark,
                  side: const BorderSide(
                    color: AppColors.primaryGold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'TEST: CASH COLLECTED',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryInformationRow extends StatelessWidget {
  const _DeliveryInformationRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          child: Icon(
            icon,
            size: 19,
            color: AppColors.primaryGoldDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SafetyNoticeCard extends StatelessWidget {
  const _SafetyNoticeCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(
          alpha: isDark ? 0.14 : 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Check your order before sharing the delivery PIN. Never share the PIN before the delivery partner arrives.',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
