import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/quick_service_booking_data.dart';
import 'package:intl/intl.dart';

class QuickServicesBookingSummary extends StatelessWidget {
  final QuickServiceBookingData bookingData;
  final IconData icon;

  const QuickServicesBookingSummary({
    super.key,
    required this.bookingData,
    required this.icon,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy • EEEE').format(date);
  }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Booking Summary',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                '${_formatDate(bookingData.scheduleDate)} • ${bookingData.scheduleTime.format(context)}',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bookingData.location.address,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Text('Customer: ${bookingData.userName}', style: AppTextStyles.bodySmall),
            ],
          ),

          // Materials or Tools (if present)
          if (bookingData.materialPreference != null && bookingData.materialPreference!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  bookingData.materialPreference!.toLowerCase().contains('tool') 
                      ? Icons.handyman_outlined 
                      : Icons.inventory_2_outlined, 
                  size: 18, color: Colors.grey
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bookingData.materialPreference!.toLowerCase().contains('tool')
                        ? 'Tools: ${bookingData.materialPreference}'
                        : 'Materials: ${bookingData.materialPreference}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          
          // Vehicle Type (if present)
          if (bookingData.carType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.directions_car, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Vehicle Type: ${bookingData.carType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.bikeType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.two_wheeler, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Vehicle Type: ${bookingData.bikeType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.truckType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_shipping, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Vehicle Type: ${bookingData.truckType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],

          // Vehicle Wash specific (if present)
          if (bookingData.carWashVehicles != null && bookingData.carWashVehicles!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.directions_car, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Vehicles: ${bookingData.carWashVehicles!.length}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],


          // Laundry specific (if present)
          if (bookingData.laundryQuantityKg != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.scale, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Quantity: ${bookingData.laundryQuantityKg} kg', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.laundryServiceType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_laundry_service, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Laundry Type: ${bookingData.laundryServiceType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
