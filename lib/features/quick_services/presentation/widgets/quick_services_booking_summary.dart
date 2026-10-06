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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${bookingData.userName}', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text('Email: ${bookingData.userEmail}', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Phone: ${bookingData.userPhone}', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
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
                      : (bookingData.materialPreference!.toLowerCase().contains('product')
                          ? Icons.clean_hands
                          : Icons.inventory_2_outlined), 
                  size: 18, color: Colors.grey
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bookingData.materialPreference!.toLowerCase().contains('tool')
                        ? 'Tools: ${bookingData.materialPreference}'
                        : (bookingData.materialPreference!.toLowerCase().contains('product')
                            ? 'Products: ${bookingData.materialPreference}'
                            : 'Materials: ${bookingData.materialPreference}'),
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
          
          // Beauty & Wellness specific (if present)
          if (bookingData.beautySelectedTreatments != null && bookingData.beautySelectedTreatments!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Treatments: ${bookingData.beautySelectedTreatments!.join(', ')}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.peopleCount != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.group, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('People: ${bookingData.peopleCount}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.professionalPreference != null && bookingData.professionalPreference!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_search, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Professional Preference: ${bookingData.professionalPreference}', style: AppTextStyles.bodySmall),
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
          
          // Gardening specific (if present)
          if (bookingData.gardeningServices != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.yard_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Gardening Services: ${bookingData.gardeningServices}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.gardeningServiceArea != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.maps_home_work, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Service Area: ${bookingData.gardeningServiceArea}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],

          // Pest Control specific (if present)
          if (bookingData.pestType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bug_report, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Pest Type: ${bookingData.pestType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.propertyType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_work, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Property Type: ${bookingData.propertyType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.pestAffectedAreas != null && bookingData.pestAffectedAreas!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.maps_home_work, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Affected Areas: ${bookingData.pestAffectedAreas!.join(', ')}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.pestObservedLevel != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Observed Level: ${bookingData.pestObservedLevel}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.paintingAreas != null && bookingData.paintingAreas!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_paint, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Painting Areas: ${bookingData.paintingAreas!.join(', ')}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.roomCount != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.meeting_room, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Number of Rooms/Areas: ${bookingData.roomCount}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.eventType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Event Type: ${bookingData.eventType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.guestCount != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Estimated Guests: ${bookingData.guestCount}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.eventDuration != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Duration: ${bookingData.eventDuration}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.supplyCategory != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.category, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Category: ${bookingData.supplyCategory}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.itemRequired != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Item: ${bookingData.itemRequired}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.supplyQuantity != null && bookingData.supplyUnit != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shopping_cart, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Quantity: ${bookingData.supplyQuantity} ${bookingData.supplyUnit}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
          if (bookingData.requestType != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.assignment, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Type: ${bookingData.requestType}', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
