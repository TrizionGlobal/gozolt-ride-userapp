import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/quick_service_booking_data.dart';

class QuickServicesServiceSummary extends StatelessWidget {
  final QuickServiceBookingData bookingData;
  final IconData? icon;
  final String? serviceTitle;
  final List<Widget>? customServiceRows;

  const QuickServicesServiceSummary({
    super.key,
    required this.bookingData,
    this.icon,
    this.serviceTitle,
    this.customServiceRows,
  });

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiOptionRow(BuildContext context, String label, dynamic rawValue) {
    if (rawValue == null) return const SizedBox.shrink();

    List<String> items = [];
    if (rawValue is List<String>) {
      items = rawValue.where((e) => e.trim().isNotEmpty).toList();
    } else if (rawValue is List) {
      items = rawValue.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawValue is String) {
      if (rawValue.trim().isEmpty) return const SizedBox.shrink();
      items = rawValue.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      return _buildDetailRow(context, label, rawValue.toString());
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // If 1 or 2 items: keep existing row format
    if (items.length <= 2) {
      return _buildDetailRow(context, label, items.join(', '));
    }

    // If more than 2 items: display as list type
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = bookingData.applyDraft();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTitle = serviceTitle ?? data.selectedServiceTitle ?? data.category;

    final hasWhatYouNeed = (data.whatYouNeed != null && data.whatYouNeed!.trim().isNotEmpty) ||
        (data.requirementDescription != null && data.requirementDescription!.trim().isNotEmpty) ||
        (data.comments != null && data.comments!.trim().isNotEmpty);
    final hasIssue = data.describeIssue != null && data.describeIssue!.trim().isNotEmpty;
    final hasPhotos = data.uploadedImages != null && data.uploadedImages!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Service Summary',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Primary Service Title
          _buildDetailRow(context, 'Service', displayTitle),

          if (data.pestObservedLevel != null && data.pestObservedLevel!.isNotEmpty)
            _buildDetailRow(context, 'Observed Level', data.pestObservedLevel!),

          // Specific service fields
          if (data.professionalPreference != null && data.professionalPreference!.isNotEmpty)
            _buildDetailRow(context, 'Professional Preference', data.professionalPreference!),

          if (data.peopleCount != null)
            _buildDetailRow(context, 'People', '${data.peopleCount}'),

          if (data.beautySelectedTreatments != null && data.beautySelectedTreatments!.isNotEmpty)
            _buildMultiOptionRow(context, 'Treatments', data.beautySelectedTreatments!),

          if (data.helperCount != null)
            _buildDetailRow(context, 'Helper', '${data.helperCount} ${data.helperCount == 1 ? "Helper" : "Helpers"}'),

          if (data.genderPreference != null && data.genderPreference!.isNotEmpty)
            _buildDetailRow(context, 'Gender Preference', data.genderPreference!),

          if (data.expectedDuration != null && data.expectedDuration!.isNotEmpty)
            _buildDetailRow(context, 'Duration', data.expectedDuration!),

          if (data.carType != null && data.carType!.isNotEmpty)
            _buildDetailRow(context, 'Vehicle Type', data.carType!),

          if (data.bikeType != null && data.bikeType!.isNotEmpty)
            _buildDetailRow(context, 'Vehicle Type', data.bikeType!),

          if (data.truckType != null && data.truckType!.isNotEmpty)
            _buildDetailRow(context, 'Vehicle Type', data.truckType!),

          if (data.pestType != null && data.pestType!.isNotEmpty)
            _buildMultiOptionRow(context, 'Pest Type', data.pestType!),

          if (data.propertyType != null && data.propertyType!.isNotEmpty)
            _buildMultiOptionRow(context, 'Property Type', data.propertyType!),

          if (data.pestAffectedAreas != null && data.pestAffectedAreas!.isNotEmpty)
            _buildMultiOptionRow(context, 'Affected Areas', data.pestAffectedAreas!),

          if (data.childrenOrPets != null && data.childrenOrPets!.isNotEmpty)
            _buildDetailRow(context, 'Children / Pets', data.childrenOrPets!),

          if (data.gardeningServices != null && data.gardeningServices!.isNotEmpty)
            _buildMultiOptionRow(context, 'Gardening Services', data.gardeningServices!),

          if (data.gardeningServiceArea != null && data.gardeningServiceArea!.isNotEmpty)
            _buildMultiOptionRow(context, 'Service Area', data.gardeningServiceArea!),

          if (data.gardeningApproximateArea != null && data.gardeningApproximateArea!.isNotEmpty)
            _buildDetailRow(context, 'Approximate Area', data.gardeningApproximateArea!),

          if (data.greenWasteRemoval != null && data.greenWasteRemoval!.isNotEmpty)
            _buildDetailRow(context, 'Green Waste Removal', data.greenWasteRemoval!),

          if (data.liftType != null && data.liftType!.isNotEmpty)
            _buildDetailRow(context, 'Lift Type', data.liftType!),

          if (data.floorsServed != null && data.floorsServed!.isNotEmpty)
            _buildDetailRow(context, 'Floors Served', data.floorsServed!),

          if (data.paintingType != null && data.paintingType!.isNotEmpty)
            _buildDetailRow(context, 'Painting Type', data.paintingType!),

          if (data.roomCount != null)
            _buildDetailRow(context, 'Rooms / Areas', '${data.roomCount}'),

          if (data.paintingAreas != null && data.paintingAreas!.isNotEmpty)
            _buildMultiOptionRow(context, 'Painting Areas', data.paintingAreas!),

          if (data.eventType != null && data.eventType!.isNotEmpty)
            _buildDetailRow(context, 'Event Type', data.eventType!),

          if (data.guestCount != null)
            _buildDetailRow(context, 'Estimated Guests', '${data.guestCount}'),

          if (data.eventDuration != null && data.eventDuration!.isNotEmpty)
            _buildDetailRow(context, 'Duration', data.eventDuration!),

          if (data.supplyCategory != null && data.supplyCategory!.isNotEmpty)
            _buildDetailRow(context, 'Category', data.supplyCategory!),

          if (data.itemRequired != null && data.itemRequired!.isNotEmpty)
            _buildDetailRow(context, 'Item', data.itemRequired!),

          if (data.supplyQuantity != null && data.supplyUnit != null)
            _buildDetailRow(context, 'Quantity', '${data.supplyQuantity} ${data.supplyUnit}'),

          if (data.requestType != null && data.requestType!.isNotEmpty)
            _buildDetailRow(context, 'Request Type', data.requestType!),

          if (data.taskCategory != null && data.taskCategory!.isNotEmpty)
            _buildDetailRow(context, 'Task Category', data.taskCategory!),

          if (data.projectScope != null && data.projectScope!.isNotEmpty)
            _buildDetailRow(context, 'Project Scope', data.projectScope!),

          if (data.commercialLaundryTypes != null && data.commercialLaundryTypes!.isNotEmpty)
            _buildMultiOptionRow(context, 'Laundry Types', data.commercialLaundryTypes!),

          if (customServiceRows != null && customServiceRows!.isNotEmpty)
            ...customServiceRows!,

          // Addons
          if (data.selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Add-ons',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...data.selectedAddons.map((addon) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        addon.name,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    Text(
                      '${addon.count}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Additional Details
          if (hasWhatYouNeed || hasIssue || hasPhotos) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Additional Details',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (hasWhatYouNeed) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'What you need: ${data.whatYouNeed ?? data.requirementDescription ?? data.comments}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (hasIssue) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Issue description: ${data.describeIssue}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (hasPhotos) ...[
              Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    'Attached Photos (${data.uploadedImages!.length})',
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
                    final path = data.uploadedImages![index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: path.startsWith('http')
                            ? Image.network(
                                path,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

