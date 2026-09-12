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
  // Counters for appliances
  final Map<String, int> _applianceCounts = {
    'Air Conditioner': 0,
    'Refrigerator': 0,
    'Washing Machine': 0,
    'Dishwasher': 0,
    'Oven / Microwave': 0,
    'Water Heater': 0,
    'Television': 0,
    'Other Appliance': 0,
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
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Service Requirements',
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
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  Icon(_getApplianceIcon(key), size: 24, color: Colors.grey.shade600),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      key,
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
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



                  // Brand - Optional
                  Text(
                    'Brand — Optional',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      hintText: 'Daikin',
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Model Number - Optional
                  Text(
                    'Model Number — Optional',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      hintText: 'FTKF35',
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                      ),
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

                  // Warning Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Burning smell, smoke or sparking? Switch off the appliance if safe and call 112 for immediate danger.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      int totalCount = _applianceCounts.values.fold(0, (sum, count) => sum + count);
                      if (totalCount == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select at least one appliance.')),
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
                        baseEstimatedHours: 0.0, // Fixed 20 euro visit fee as per mockup
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
