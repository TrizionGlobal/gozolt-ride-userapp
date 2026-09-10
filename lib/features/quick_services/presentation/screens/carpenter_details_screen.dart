import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';
import '../widgets/quick_services_image_picker.dart';
import '../widgets/quick_services_additional_details.dart';

class CarpenterDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const CarpenterDetailsScreen({super.key, required this.bookingData});

  @override
  State<CarpenterDetailsScreen> createState() => _CarpenterDetailsScreenState();
}

class _CarpenterDetailsScreenState extends State<CarpenterDetailsScreen> {
  final Map<String, int> _counts = {
    'Door Repair': 0,
    'Furniture Repair': 0,
    'Cupboard Repair': 0,
    'Lock / Hinge Repair': 0,
    'Shelf Installation': 0,
    'Furniture Assembly': 0,
    'Other Carpentry Issue': 0,
  };

  final Map<String, IconData> _icons = {
    'Door Repair': Icons.door_front_door,
    'Furniture Repair': Icons.chair,
    'Cupboard Repair': Icons.kitchen,
    'Lock / Hinge Repair': Icons.lock,
    'Shelf Installation': Icons.table_bar,
    'Furniture Assembly': Icons.handyman,
    'Other Carpentry Issue': Icons.miscellaneous_services,
  };

  void _increment(String key) {
    setState(() {
      _counts[key] = (_counts[key] ?? 0) + 1;
    });
  }

  void _decrement(String key) {
    setState(() {
      if ((_counts[key] ?? 0) > 0) {
        _counts[key] = (_counts[key] ?? 0) - 1;
      }
    });
  }

  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  @override
  void dispose() {
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "What's the issue?",
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: _counts.keys.map((key) {
                        final count = _counts[key] ?? 0;
                        final isLast = key == _counts.keys.last;
                        
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(_icons[key], size: 24, color: Colors.grey.shade600),
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
                                        onTap: () => _decrement(key),
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
                                        onTap: () => _increment(key),
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      final selectedKeys = _counts.keys.where((k) => (_counts[k] ?? 0) > 0).toList();
                      
                      if (selectedKeys.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select at least one issue.')),
                        );
                        return;
                      }

                      List<ServiceAddon> selectedAddons = selectedKeys.map((key) {
                        return ServiceAddon(name: key, count: _counts[key]!, pricePerUnit: 15.00);
                      }).toList();

                      double newSubtotal = 0;
                      for (var key in selectedKeys) {
                        newSubtotal += 15.00 * _counts[key]!;
                      }

                      final updatedData = widget.bookingData.copyWith(
                        selectedAddons: selectedAddons,
                        subtotal: newSubtotal,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                      );

                      context.pushNamed(
                        RouteNames.quickServicesCarpenterReview,
                        extra: updatedData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
