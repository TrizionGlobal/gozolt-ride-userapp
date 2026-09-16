import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/booking_payment_sheet.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../../../ride/presentation/widgets/payment_brand_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ride/presentation/providers/ride_providers.dart';

class QuickServicesPaymentSelector extends ConsumerWidget {
  final QuickServiceBookingData bookingData;
  final ValueChanged<QuickServiceBookingData> onChanged;

  const QuickServicesPaymentSelector({
    super.key,
    required this.bookingData,
    required this.onChanged,
  });

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingPaymentSheet(
        currentType: bookingData.paymentMethodType,
        currentCardId: bookingData.paymentMethodId,
        isQuickService: true,
        onConfirm: (type, {cardId}) {
          final updatedData = bookingData.copyWith(
            paymentMethodType: type,
            paymentMethodId: cardId,
          );
          onChanged(updatedData);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // We need to resolve the saved card info if they selected card
    SavedPaymentMethod? selectedSavedCard;
    if (bookingData.paymentMethodType == PaymentMethodType.card && bookingData.paymentMethodId != null) {
      final methodsAsync = ref.watch(paymentMethodsProvider);
      methodsAsync.whenData((methods) {
        try {
          selectedSavedCard = methods.firstWhere((m) => m.id == bookingData.paymentMethodId);
        } catch (_) {}
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => _showPaymentSheet(context),
                child: Text(
                  'Change',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bookingData.paymentMethodType == PaymentMethodType.cash)
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primaryGold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay After Service', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Postpaid', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          else if (bookingData.paymentMethodType == PaymentMethodType.card && selectedSavedCard != null)
            Row(
              children: [
                PaymentBrandIcon(brand: selectedSavedCard!.brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedSavedCard!.displayName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Prepaid (Pay now)', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          else 
            Row(
              children: [
                const Icon(Icons.credit_card, color: AppColors.primaryGold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card Payment', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Prepaid (Pay now)', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}
