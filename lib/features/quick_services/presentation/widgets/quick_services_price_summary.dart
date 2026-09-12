import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/quick_service_booking_data.dart';

class QuickServicesPriceSummary extends StatelessWidget {
  final QuickServiceBookingData bookingData;
  final String? note;

  const QuickServicesPriceSummary({
    super.key,
    required this.bookingData,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            const Divider(height: 24),
          ],

          if (bookingData.baseEstimatedHours > 0) ...[
            Builder(
              builder: (context) {
                String label = 'Base / Inspection Time';
                if (bookingData.laundryQuantityKg != null && bookingData.laundryQuantityKg! > 0) {
                  final rate = bookingData.baseEstimatedHours / bookingData.laundryQuantityKg!;
                  label = 'Est. Time (${bookingData.laundryQuantityKg} kg @ ${rate.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")} hr/kg)';
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
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
          
          if (bookingData.selectedAddons.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Estimated Hours', style: AppTextStyles.bodyMedium),
                Text(
                  '${bookingData.totalEstimatedHours.toStringAsFixed(1)} hrs',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hourly Rate', style: AppTextStyles.bodyMedium),
              Text(
                bookingData.hasRateRange 
                    ? '€${bookingData.minHourlyRate.toStringAsFixed(2)} - €${bookingData.maxHourlyRate!.toStringAsFixed(2)}/hr'
                    : '€${bookingData.minHourlyRate.toStringAsFixed(2)}/hr',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),

          if (bookingData.fixedAddonCosts > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Fixed Add-ons', style: AppTextStyles.bodyMedium)),
                Text(
                  '€${bookingData.fixedAddonCosts.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (bookingData.materialCost > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Material Surcharge', style: AppTextStyles.bodyMedium)),
                Text(
                  '€${bookingData.materialCost.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (bookingData.subtotal > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Other Subtotal', style: AppTextStyles.bodyMedium)),
                Text(
                  '€${bookingData.subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (bookingData.fixedAddonCosts > 0 || bookingData.materialCost > 0 || bookingData.subtotal > 0)
            const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Total',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
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

          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              note!,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
