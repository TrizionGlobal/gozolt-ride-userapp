import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_image_picker.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';

class ApplianceRepairDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const ApplianceRepairDetailsScreen({super.key, required this.bookingData});

  @override
  State<ApplianceRepairDetailsScreen> createState() => _ApplianceRepairDetailsScreenState();
}

class _ApplianceRepairDetailsScreenState extends State<ApplianceRepairDetailsScreen> {
  String _materialPreference = 'Bring tools';
  // Counters for appliances
  final Map<String, int> _applianceCounts = {
    'Air Conditioner': 0,
    'Refrigerator': 0,
    'Washing Machine': 0,
    'Dishwasher': 0,
    'Oven / Microwave': 0,
    'Water Heater': 0,
    'Television': 0,
  };

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // If the user selected a specific appliance from the previous screen's modal, set its count to 1
    if (widget.bookingData.selectedServiceTitle != null &&
        _applianceCounts.containsKey(widget.bookingData.selectedServiceTitle)) {
      _applianceCounts[widget.bookingData.selectedServiceTitle!] = 1;
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _incrementAppliance(String key) {
    setState(() {
      _applianceCounts[key] = (_applianceCounts[key] ?? 0) + 1;
    });
  }

  void _decrementAppliance(String key) {
    setState(() {
      if ((_applianceCounts[key] ?? 0) > 0) {
        _applianceCounts[key] = (_applianceCounts[key] ?? 0) - 1;
      }
    });
  }

  IconData _getApplianceIcon(String key) {
    switch (key) {
      case 'Air Conditioner':
        return Icons.ac_unit;
      case 'Refrigerator':
        return Icons.kitchen;
      case 'Washing Machine':
        return Icons.local_laundry_service;
      case 'Dishwasher':
        return Icons.local_car_wash;
      case 'Oven / Microwave':
        return Icons.microwave;
      case 'Water Heater':
        return Icons.propane;
      case 'Television':
        return Icons.tv;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 1,
            title: 'Service Requirements',
            subtitle: 'Appliance Repair',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appliance selection with counters
                  Text(
                    'Which appliance needs service?',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: _applianceCounts.keys.map((key) {
                        final count = _applianceCounts[key] ?? 0;
                        final isLast = key == _applianceCounts.keys.last;
                        
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(_getApplianceIcon(key), size: 22, color: Colors.grey.shade600),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      key,
                                      style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _decrementAppliance(key),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.remove, size: 16),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          '$count',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _incrementAppliance(key),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.add, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.withOpacity(0.2),
                                indent: 16,
                                endIndent: 16,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),


                  Text(
                    'Required Tools',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _materialPreference == 'Bring tools' ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                        width: _materialPreference == 'Bring tools' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handyman, size: 24, color: AppColors.primaryGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bring tools', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                _materialPreference == 'Bring tools' ? '+€5.00 extra charge' : 'Use my tools (No extra charge)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _materialPreference == 'Bring tools' ? AppColors.primaryGold : Colors.grey[600],
                                  fontWeight: _materialPreference == 'Bring tools' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: _materialPreference == 'Bring tools',
                            activeColor: isDark ? AppColors.backgroundDark : Colors.white,
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: (val) {
                              setState(() {
                                _materialPreference = val ? 'Bring tools' : 'Use my tools';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Additional Details',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  QuickServicesAdditionalDetails(
                    whatYouNeedController: _whatYouNeedController,
                    describeIssueController: _describeIssueController,
                    images: _selectedImages,
                    onAddImages: _pickImages,
                    onRemoveImage: (image) {
                      setState(() {
                        _selectedImages.remove(image);
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Continue Button
                  SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: () {
                        int totalCount = _applianceCounts.values.fold(0, (sum, count) => sum + count);
                        if (totalCount == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please select at least one appliance to continue.', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        
                        List<ServiceAddon> selectedAddons = [];
                        _applianceCounts.forEach((appliance, count) {
                          if (count > 0) {
                            selectedAddons.add(ServiceAddon(name: appliance, count: count, hoursPerUnit: 1.0)); // The price is not per addon here, it's a fixed visit fee
                          }
                        });

                        final updatedData = widget.bookingData.copyWith(
                          selectedAddons: selectedAddons,
                          whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                          describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                          uploadedImages: _selectedImages.map((e) => e.path).toList(),
                          subtotal: 0.0,
                          baseEstimatedHours: 0.0,
                          materialPreference: _materialPreference,
                        );

                        context.pushNamed(
                          RouteNames.quickServicesApplianceRepairReview,
                          extra: updatedData,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
}
