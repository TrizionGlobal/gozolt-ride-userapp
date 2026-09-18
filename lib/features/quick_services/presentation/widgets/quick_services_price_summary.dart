import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/quick_service_booking_data.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_paths.dart';

class QuickServicesPriceSummary extends StatelessWidget {
  final QuickServiceBookingData bookingData;
  final String? note;
  final bool useGoCoins;
  final ValueChanged<bool>? onGoCoinsChanged;

  const QuickServicesPriceSummary({
    super.key,
    required this.bookingData,
    this.note,
    this.useGoCoins = false,
    this.onGoCoinsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (bookingData.selectedAddons.isNotEmpty || bookingData.describeIssue?.trim().isNotEmpty == true || bookingData.uploadedImages?.isNotEmpty == true) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (bookingData.selectedAddons.isNotEmpty && (bookingData.describeIssue?.trim().isNotEmpty == true || bookingData.uploadedImages?.isNotEmpty == true))
                      ? 'Selected Add-ons & Details'
                      : (bookingData.selectedAddons.isNotEmpty)
                          ? 'Selected Add-ons'
                          : 'Additional Details',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (bookingData.selectedAddons.isNotEmpty) ...[
                  ...bookingData.selectedAddons.map((addon) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              addon.count > 1 ? '${addon.name} (x${addon.count})' : addon.name,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Text(
                            addon.isFixedPrice
                                ? '€${addon.totalPrice.toStringAsFixed(2)}'
                                : '${addon.totalHours.toStringAsFixed(1)} hrs',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (bookingData.wallType != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Wall Type', style: AppTextStyles.bodyMedium),
                        ),
                        Text(bookingData.wallType!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                if ((bookingData.selectedAddons.isNotEmpty || bookingData.wallType != null) && (bookingData.describeIssue?.trim().isNotEmpty == true || bookingData.uploadedImages?.isNotEmpty == true))
                  const Divider(height: 24),
                if (bookingData.describeIssue?.trim().isNotEmpty == true) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Issue description: ${bookingData.describeIssue!}',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  if (bookingData.uploadedImages?.isNotEmpty == true) const SizedBox(height: 10),
                ],
                if (bookingData.uploadedImages?.isNotEmpty == true) ...[
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text('Attached Photo (${bookingData.uploadedImages!.length})', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: bookingData.uploadedImages!.length,
                          itemBuilder: (context, index) {
                            final path = bookingData.uploadedImages![index];
                            return Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(path),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Summary',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (bookingData.baseEstimatedHours > 0) ...[
                Builder(builder: (context) {
                  String label = 'Base / Inspection Time';
                  if (bookingData.laundryQuantityKg != null &&
                      bookingData.laundryQuantityKg! > 0) {
                    final rate = bookingData.baseEstimatedHours /
                        bookingData.laundryQuantityKg!;
                    label =
                        'Est. Time (${bookingData.laundryQuantityKg} kg @ ${rate.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")} hr/kg)';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          '${bookingData.baseEstimatedHours.toStringAsFixed(1)} hrs',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (bookingData.selectedAddons.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Estimated Hours',
                        style: AppTextStyles.bodyMedium),
                    Text(
                      '${bookingData.totalEstimatedHours.toStringAsFixed(1)} hrs',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (bookingData.category != 'Vehicle Wash') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hourly Rate', style: AppTextStyles.bodyMedium),
                    Text(
                      bookingData.hasRateRange
                          ? '€${bookingData.minHourlyRate.toStringAsFixed(2)} - €${bookingData.maxHourlyRate!.toStringAsFixed(2)}/hr'
                          : '€${bookingData.minHourlyRate.toStringAsFixed(2)}/hr',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Service Charge',
                        style: AppTextStyles.bodyMedium),
                    Text(
                      bookingData.hasRateRange
                          ? '€${(bookingData.totalEstimatedHours * bookingData.minHourlyRate).toStringAsFixed(2)} - €${(bookingData.totalEstimatedHours * bookingData.maxHourlyRate!).toStringAsFixed(2)}'
                          : '€${(bookingData.totalEstimatedHours * bookingData.minHourlyRate).toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              if (bookingData.category != 'Vehicle Wash')
                const Divider(height: 24),
              if (bookingData.fixedAddonCosts > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text('Fixed Add-ons',
                            style: AppTextStyles.bodyMedium)),
                    Text(
                      '€${bookingData.fixedAddonCosts.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (bookingData.subtotal > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                            bookingData.category == 'Vehicle Wash'
                                ? 'Total Vehicles Charges'
                                : 'Service Subtotal',
                            style: AppTextStyles.bodyMedium)),
                    Text(
                      '€${bookingData.subtotal.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (bookingData.materialCost > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                            bookingData.materialPreference?.toLowerCase().contains('tool') == true
                                ? 'Tools Included Charge'
                                : 'Materials Included Charge',
                            style: AppTextStyles.bodyMedium)),
                    Text(
                      '€${bookingData.materialCost.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (bookingData.pickupAndReturnFee != null && bookingData.pickupAndReturnFee! > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                            (bookingData.category == 'Vehicle Wash' && bookingData.carWashVehicles != null && bookingData.carWashVehicles!.isNotEmpty)
                                ? 'Pickup & Return Fee (x${bookingData.carWashVehicles!.length})'
                                : 'Pickup & Return Fee',
                            style: AppTextStyles.bodyMedium)),
                    Text(
                      '€${bookingData.pickupAndReturnFee!.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Estimated Amount',
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    bookingData.hasRateRange
                        ? '€${bookingData.estimatedTotalMin.toStringAsFixed(2)} - €${bookingData.estimatedTotalMax.toStringAsFixed(2)}'
                        : '€${bookingData.estimatedTotalMin.toStringAsFixed(2)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Paid after the service is completed',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upfront Payment',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text('Upfront Booking Fee',
                          style: AppTextStyles.bodyMedium)),
                  Text('€10.00',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              // ── GoCoins Redeem Section ──
              if (onGoCoinsChanged != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: useGoCoins
                          ? AppColors.primaryGold
                          : (Theme.of(context).dividerTheme.color ??
                              AppColors.borderDark),
                      width: useGoCoins ? 1.5 : 0.5,
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
                        child: Image.asset(AssetPaths.iconGoCoin,
                            width: 24, height: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Redeem GoCoins',
                                style: AppTextStyles.titleSmall
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Balance: 250 Coins',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch.adaptive(
                          value: useGoCoins,
                          activeColor: AppColors.backgroundDark,
                          activeTrackColor: AppColors.primaryGold,
                          inactiveTrackColor:
                              Theme.of(context).dividerTheme.color ??
                                  AppColors.borderDark,
                          onChanged: onGoCoinsChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (useGoCoins) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text('GoCoins Discount',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.primaryGold))),
                    Text(
                      '-€2.00',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount to Pay Now',
                    style: AppTextStyles.titleSmall
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '€${(10.0 - (useGoCoins ? 2.0 : 0.0)).toStringAsFixed(2)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primaryGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note != null && note!.isNotEmpty
                            ? '$note\n\nNote: Upfront Booking fee must be paid now. The Estimated Total will be paid directly to the service provider after the job is completed.'
                            : 'Note: Upfront Booking fee must be paid now. The Estimated Total will be paid directly to the service provider after the job is completed.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
