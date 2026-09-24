import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../../../ride/data/models/saved_payment_method.dart';


class BeautyWellnessReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const BeautyWellnessReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<BeautyWellnessReviewScreen> createState() => _BeautyWellnessReviewScreenState();
}

class _BeautyWellnessReviewScreenState extends ConsumerState<BeautyWellnessReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool _useGoCoins = false;
  bool _isBooking = false;

  final Map<String, double> _treatmentPrices = {
    'Haircut & Styling': 25.0,
    'Hair Colouring': 45.0,
    'Facial Treatment': 30.0,
    'Manicure': 20.0,
    'Pedicure': 25.0,
    'Waxing': 15.0,
    'Threading': 10.0,
    'Makeup Service': 35.0,
    'Massage & Relaxation': 40.0,
    "Men's Grooming": 20.0,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _bookingData;

    final String formattedDate = DateFormat('dd MMM yyyy').format(data.scheduleDate);
    final String formattedTime = data.scheduleTime.format(context);

    final selectedTreatments = data.beautySelectedTreatments ?? [];
    final peopleCount = data.peopleCount ?? 1;

    double subtotal = 0.0;
    for (final t in selectedTreatments) {
      subtotal += (_treatmentPrices[t] ?? 0.0);
    }
    subtotal *= peopleCount;

    final double goCoinsDiscount = _useGoCoins ? 2.0 : 0.0;
    final double estimatedTotal = (subtotal - goCoinsDiscount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: 'Beauty & Wellness',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Services Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.spa, color: AppColors.primaryGold, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Beauty & Wellness',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        Text(
                          'Selected Services',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),

                        ...selectedTreatments.map((treatment) {
                          final price = _treatmentPrices[treatment] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(treatment, style: AppTextStyles.bodyMedium),
                                ),
                                Text(
                                  'Inspection',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 8),
                        _buildDetailRow('Number of People', '$peopleCount'),
                        _buildDetailRow('Professional Preference', data.professionalPreference ?? 'Any Professional'),
                        _buildDetailRow('Date & Time', '$formattedDate • $formattedTime', icon: Icons.calendar_today_outlined),
                        _buildDetailRow('Address', data.location.address.isNotEmpty ? data.location.address : '8 Triq Santa Rita, Sliema, Malta', icon: Icons.location_on_outlined),
                        _buildDetailRow('Customer', data.userName.isNotEmpty ? data.userName : 'Justin Camilleri', icon: Icons.person_outline),
                        
                        if (data.whatYouNeed != null && data.whatYouNeed!.isNotEmpty)
                          _buildDetailRow('Tell Us', data.whatYouNeed!, icon: Icons.note_outlined),
                        if (data.describeIssue != null && data.describeIssue!.isNotEmpty)
                          _buildDetailRow('Description', data.describeIssue!, icon: Icons.description_outlined),

                        if (data.uploadedImages != null && data.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primaryGold),
                              const SizedBox(width: 10),
                              Text(
                                'Reference Photos (${data.uploadedImages!.length})',
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.uploadedImages!.length,
                              itemBuilder: (context, index) {
                                return QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Summary Card
                  Text(
                    'Price Summary',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        ...selectedTreatments.map((treatment) {
                          final price = (_treatmentPrices[treatment] ?? 0.0) * peopleCount;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(treatment, style: AppTextStyles.bodyMedium),
                                Text(
                                  'Inspection',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text('€${subtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // GO Coins Discount Box
                        
                        // ── GoCoins Redeem Section ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _useGoCoins ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                              width: _useGoCoins ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(AssetPaths.iconGoCoin, width: 24, height: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Redeem GoCoins', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Balance: 250 Coins',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                    if (_useGoCoins)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Save €2.00 with 200 coins',
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch.adaptive(
                                  value: _useGoCoins,
                                  activeColor: AppColors.backgroundDark,
                                  activeTrackColor: AppColors.primaryGold,
                                  inactiveTrackColor: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                                  onChanged: (val) => setState(() => _useGoCoins = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_useGoCoins) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('GoCoins Discount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold))),
                              Text(
                                '-€2.00',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],


                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Estimated Total', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '€${estimatedTotal.toStringAsFixed(2)}',
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: _isBooking ? null : () async {

                  final finalTotal = ((_bookingData.upfrontBookingFee + _bookingData.materialCost) - (_useGoCoins ? (_bookingData.upfrontBookingFee + _bookingData.materialCost).clamp(0.0, 6.0) : 0.0)).clamp(0.0, double.infinity);
                      
                  if (finalTotal <= 0.0) {
                    final updatedData = _bookingData.copyWith(
                      paymentMethodType: PaymentMethodType.cash,
                      useGoCoins: _useGoCoins,
                    );
                    
                      setState(() => _isBooking = true);
                      final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                      if (mounted) setState(() => _isBooking = false);
                      if (bookingId != null && mounted) {
                        context.pushNamed(RouteNames.quickServicesBeautyWellnessConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
                      } else {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                      }
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => BookingPaymentSheet(
                          currentType: _bookingData.paymentMethodType,
                          currentCardId: _bookingData.paymentMethodId,
                          isQuickService: true,
                          amount: finalTotal,
                          onConfirm: (type, {cardId}) async {
                            final updatedData = _bookingData.copyWith(
                            paymentMethodType: type,
                            paymentMethodId: cardId,
                            useGoCoins: _useGoCoins,
                          );
                            final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                            if (bookingId != null && mounted) {
                              context.pushNamed(RouteNames.quickServicesBeautyWellnessConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
                              return true;
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                              return false;
                            }
                          },
                        ),
                      );
                    }
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isBooking ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primaryGold),
            const SizedBox(width: 8),
          ],
          Text('$label:', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
