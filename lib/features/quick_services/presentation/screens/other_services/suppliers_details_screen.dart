import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class SuppliersDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const SuppliersDetailsScreen({super.key, required this.bookingData});

  @override
  State<SuppliersDetailsScreen> createState() => _SuppliersDetailsScreenState();
}

class _SuppliersDetailsScreenState extends State<SuppliersDetailsScreen> {
  String? _supplyCategory;
  final TextEditingController _itemRequiredController = TextEditingController();
  int _quantity = 1;
  String _unit = 'Pieces';
  String _requestType = 'Purchase';
  
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  final List<String> _categories = [
    'Event Supplies',
    'Building Materials',
    'Cleaning Supplies',
    'Electrical Supplies',
    'Other'
  ];

  final List<String> _units = ['Pieces', 'Kg', 'Liters', 'Boxes'];

  @override
  void dispose() {
    _itemRequiredController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      debugPrint("Error picking images: \$e");
    }
  }



  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF324461),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F6F8),
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Service Requirements',
            subtitle: 'Suppliers',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Supply Category
                  _buildLabel('Supply Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _supplyCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _supplyCategory = selected ? category : null);
                        },
                        selectedColor: AppColors.primaryGold,
                        backgroundColor: Colors.transparent,
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryGold : Colors.grey.shade400,
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Item Required
                  _buildLabel('Item Required'),
                  TextField(
                    controller: _itemRequiredController,
                    decoration: InputDecoration(
                      hintText: 'Enter item or product name',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color ?? Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity and Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Quantity'),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Text('$_quantity', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () => setState(() => _quantity++),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Unit'),
                            DropdownButtonFormField<String>(
                              value: _unit,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Theme.of(context).cardTheme.color ?? Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primaryGold),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(value: unit, child: Text(unit, style: AppTextStyles.bodyMedium));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _unit = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Request Type
                  _buildLabel('Request Type'),
                  Row(
                    children: ['Purchase', 'Rental'].map((type) {
                      return Row(
                        children: [
                          Radio<String>(
                            value: type,
                            groupValue: _requestType,
                            onChanged: (val) {
                              if (val != null) setState(() => _requestType = val);
                            },
                            activeColor: AppColors.primaryGold,
                          ),
                          Text(type, style: AppTextStyles.bodyMedium),
                          const SizedBox(width: 16),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Additional Details (Tell Us, Description, Upload)
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
                  
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Light yellow
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Color(0xFFFBC02D), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The supplier will confirm availability and final price.',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      if (_supplyCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supply category')));
                        return;
                      }
                      if (_itemRequiredController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the required item')));
                        return;
                      }
                      
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Suppliers',
                        supplyCategory: _supplyCategory,
                        itemRequired: _itemRequiredController.text.trim(),
                        supplyQuantity: _quantity,
                        supplyUnit: _unit,
                        requestType: _requestType,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        subtotal: 0.0,
                        baseEstimatedHours: 1.0,
                      );

                      context.pushNamed(
                        RouteNames.quickServicesOtherServicesReview,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
