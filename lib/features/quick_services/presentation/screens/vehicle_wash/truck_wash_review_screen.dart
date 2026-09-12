import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_header.dart';

class TruckWashReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const TruckWashReviewScreen({super.key, required this.bookingData});

  @override
  State<TruckWashReviewScreen> createState() => _TruckWashReviewScreenState();
}

class _TruckWashReviewScreenState extends State<TruckWashReviewScreen> {
  bool _useGoCoins = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM yyyy').format(widget.bookingData.scheduleDate);
    final timeStr = widget.bookingData.scheduleTime.format(context);

    final make = widget.bookingData.vehicleMake ?? 'Toyota';
    final model = widget.bookingData.vehicleModel ?? 'Corolla';
    final colour = widget.bookingData.vehicleColour ?? 'Black';
    final regNo = widget.bookingData.vehicleRegistration ?? 'ABC 123';
    final packageName = widget.bookingData.carWashPackage ?? 'Full Wash';
    final packagePrice = widget.bookingData.carWashPackagePrice ?? 30.0;
    final vehicleCount = widget.bookingData.vehicleCount ?? 1;
    final condition = widget.bookingData.vehicleCondition ?? 'Normal';
    final water = widget.bookingData.waterAccess ?? 'Available';
    final electricity = widget.bookingData.electricityAccess ?? 'Available';

    final rawSubtotal = packagePrice * vehicleCount;
    final discount = _useGoCoins ? 2.0 : 0.0;
    final estimatedTotal = (rawSubtotal - discount).clamp(0.0, 9999.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Title Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF8E1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_car_wash,
                            color: Color(0xFFF57F17),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Truck Wash',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Service Details Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Vehicle:', '$make $model • $colour'),
                        const SizedBox(height: 8),
                        _buildDetailRow('Registration:', regNo),
                        const SizedBox(height: 8),
                        _buildDetailRow('Package:', packageName),
                        const SizedBox(height: 8),
                        _buildDetailRow('Vehicles:', '$vehicleCount'),
                        const SizedBox(height: 8),
                        _buildDetailRow('Condition:', condition),
                        const SizedBox(height: 8),
                        _buildDetailRow('Water:', water),
                        const SizedBox(height: 8),
                        _buildDetailRow('Electricity:', electricity),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location, Schedule & Customer Card
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
                        // Date & Time
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text('$dateStr • $timeStr', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
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
                                widget.bookingData.location.address,
                                style: AppTextStyles.bodyMedium,
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
                            Text('Customer: ${widget.bookingData.userName}', style: AppTextStyles.bodyMedium),
                          ],
                        ),

                        if (widget.bookingData.describeIssue != null && widget.bookingData.describeIssue!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Parking instruction: ${widget.bookingData.describeIssue!}',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Photos Thumbnail
                        if (widget.bookingData.uploadedImages != null && widget.bookingData.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Text('Attached Photo (${widget.bookingData.uploadedImages!.length})', style: AppTextStyles.bodySmall),
                              const Spacer(),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: widget.bookingData.uploadedImages!.length,
                                  itemBuilder: (context, index) {
                                    final path = widget.bookingData.uploadedImages![index];
                                    return QuickServicesPriceSummary(bookingData: widget.bookingData);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Summary
                  Text(
                    'Price Summary',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(packageName, style: AppTextStyles.bodyMedium),
                            Text('€${rawSubtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Additional Work: If required', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                            Text('-', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text('€${rawSubtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // GO Coins Discount Box
                        GestureDetector(
                          onTap: () => setState(() => _useGoCoins = !_useGoCoins),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _useGoCoins ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _useGoCoins,
                                  activeColor: AppColors.primaryGold,
                                  onChanged: (val) => setState(() => _useGoCoins = val ?? false),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GO Coins: 250 available', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Use 200 GO Coins', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700])),
                                  ],
                                ),
                                const Spacer(),
                                Text('-€2.00', style: AppTextStyles.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Estimated Total', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text('€${estimatedTotal.toStringAsFixed(2)}', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                      final updatedData = widget.bookingData.copyWith(
                        subtotal: estimatedTotal,
                      );

                      context.pushNamed(
                        RouteNames.quickServicesTruckWashConfirmation,
                        extra: updatedData,
                      );
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
                    child: Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700])),
        Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
