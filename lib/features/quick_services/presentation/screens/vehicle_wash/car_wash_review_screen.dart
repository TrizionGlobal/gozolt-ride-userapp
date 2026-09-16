import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
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

class CarWashReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const CarWashReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<CarWashReviewScreen> createState() => _CarWashReviewScreenState();
}

class _CarWashReviewScreenState extends ConsumerState<CarWashReviewScreen> {
  late QuickServiceBookingData _bookingData;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool _useGoCoins = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM yyyy').format(_bookingData.scheduleDate);
    final timeStr = _bookingData.scheduleTime.format(context);

    final make = _bookingData.vehicleMake ?? 'Toyota';
    final model = _bookingData.vehicleModel ?? 'Corolla';
    final colour = _bookingData.vehicleColour ?? 'Black';
    final regNo = _bookingData.vehicleRegistration ?? 'ABC 123';
    final packageName = _bookingData.carWashPackage ?? 'Full Wash';
    final packagePrice = _bookingData.carWashPackagePrice ?? 30.0;
    final vehicleCount = _bookingData.vehicleCount ?? 1;
    final condition = _bookingData.vehicleCondition ?? 'Normal';
    final water = _bookingData.waterAccess ?? 'Available';
    final electricity = _bookingData.electricityAccess ?? 'Available';

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
                          'Car Wash',
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
                                _bookingData.location.address,
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
                            Text('Customer: ${_bookingData.userName}', style: AppTextStyles.bodyMedium),
                          ],
                        ),

                        if (_bookingData.describeIssue != null && _bookingData.describeIssue!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Parking instruction: ${_bookingData.describeIssue!}',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Photos Thumbnail
                        if (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Text('Attached Photo (${_bookingData.uploadedImages!.length})', style: AppTextStyles.bodySmall),
                              const Spacer(),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: _bookingData.uploadedImages!.length,
                                  itemBuilder: (context, index) {
                                    final path = _bookingData.uploadedImages![index];
                                    return QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),);
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

                  // Payment Section
                  
                  QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),
                  const SizedBox(height: 40),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                  final finalTotal = _bookingData.hasRateRange
                      ? _bookingData.estimatedTotalMax - (_useGoCoins ? 2.0 : 0.0)
                      : _bookingData.estimatedTotalMin - (_useGoCoins ? 2.0 : 0.0);
                      
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => BookingPaymentSheet(
                      currentType: _bookingData.paymentMethodType,
                      currentCardId: _bookingData.paymentMethodId,
                      isQuickService: true,
                      amount: finalTotal,
                      onConfirm: (type, {cardId}) {
                        final updatedData = _bookingData.copyWith(
                          paymentMethodType: type,
                          paymentMethodId: cardId,
                        );
                        context.pushNamed(
                          RouteNames.quickServicesCarWashConfirmation,
                          extra: updatedData,
                        );
                      },
                    ),
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
