import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';

class LiftElevatorMechanicReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const LiftElevatorMechanicReviewScreen({super.key, required this.bookingData});

  @override
  State<LiftElevatorMechanicReviewScreen> createState() => _LiftElevatorMechanicReviewScreenState();
}

class _LiftElevatorMechanicReviewScreenState extends State<LiftElevatorMechanicReviewScreen> {
  bool useCoins = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(
                RouteNames.quickServicesLiftElevatorConfirmation,
                extra: widget.bookingData,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('CONFIRM BOOKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ),
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
          ),
          
          // Certified technician required banner
          Container(
            width: double.infinity,
            color: AppColors.primaryGold.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: AppColors.primaryGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Certified technician required',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Summary',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Service', widget.bookingData.selectedServiceTitle ?? 'N/A'),
                        _buildSummaryRow('Property Type', widget.bookingData.propertyType ?? 'N/A'),
                        _buildSummaryRow('Lift Type', widget.bookingData.liftType ?? 'N/A'),
                        _buildSummaryRow('Manufacturer / Model', '${widget.bookingData.vehicleMake ?? 'Unknown'} ${widget.bookingData.vehicleModel ?? ''}'.trim()),
                        _buildSummaryRow('Floors Served', widget.bookingData.floorsServed ?? 'Not specified'),
                        _buildSummaryRow('Issue', widget.bookingData.vehicleIssue ?? 'N/A'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(Icons.calendar_today, 'Schedule'),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Text(
                      _formatDate(widget.bookingData.scheduleDate, widget.bookingData.scheduleTime),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.location_on, 'Service Address'),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Text(
                      widget.bookingData.location.address,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.person, 'Customer'),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bookingData.userName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.bookingData.userPhone} • ${widget.bookingData.userEmail}',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  
                  if (widget.bookingData.whatYouNeed != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.info_outline, 'What You Need'),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: Text(
                        widget.bookingData.whatYouNeed!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  if (widget.bookingData.describeIssue != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.description, 'Issue Description'),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: Text(
                        widget.bookingData.describeIssue!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  if (widget.bookingData.uploadedImages != null && widget.bookingData.uploadedImages!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.photo_library, 'Uploaded Photos'),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.bookingData.uploadedImages!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(widget.bookingData.uploadedImages![index])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  Text(
                    'Pricing Estimate',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceRow('Visit / Inspection Fee', '€50.00'),
                        _buildPriceRow('Estimated Labour', '€80 - €250'),
                        _buildPriceRow('Replacement Parts', 'Not Included'),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text('Final quote after inspection', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/go_coin.png', width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.monetization_on, size: 20, color: AppColors.primaryGold)),
                                const SizedBox(width: 8),
                                const Text('GO Coins Available', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset('assets/images/go_coin.png', width: 14, height: 14, errorBuilder: (c, e, s) => const Icon(Icons.monetization_on, size: 14, color: AppColors.primaryGold)),
                                const SizedBox(width: 4),
                                const Text('250', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Use GO Coins', style: TextStyle(fontSize: 14)),
                            Switch(
                              value: useCoins,
                              activeColor: AppColors.primaryGold,
                              onChanged: (v) => setState(() => useCoins = v),
                            ),
                          ],
                        ),
                        if (useCoins) _buildPriceRow('Discount', '-€2.00', isDiscount: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF324461),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF324461)),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF324461),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(price, style: TextStyle(fontSize: 14, color: isDiscount ? Colors.red : null)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, TimeOfDay time) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} (${weekdays[date.weekday - 1]})';
  }
}
