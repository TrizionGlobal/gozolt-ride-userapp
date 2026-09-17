import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import 'dart:io';

class CommercialLaundryDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const CommercialLaundryDetailsScreen({super.key, required this.bookingData});

  @override
  State<CommercialLaundryDetailsScreen> createState() => _CommercialLaundryDetailsScreenState();
}

class _CommercialLaundryDetailsScreenState extends State<CommercialLaundryDetailsScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bagsController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _otherBusinessTypeController = TextEditingController();
  final TextEditingController _otherLaundryTypeController = TextEditingController();

  String? _businessType;
  final List<Map<String, dynamic>> _businessTypes = [
    {'name': 'Restaurant', 'icon': Icons.restaurant},
    {'name': 'Hotel', 'icon': Icons.hotel},
    {'name': 'Salon / Spa', 'icon': Icons.spa},
    {'name': 'Gym', 'icon': Icons.fitness_center},
    {'name': 'Office', 'icon': Icons.work},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  final List<String> _selectedLaundryTypes = [];
  final List<Map<String, dynamic>> _availableLaundryTypes = [
    {'name': 'Uniforms', 'icon': Icons.checkroom},
    {'name': 'Towels', 'icon': Icons.layers},
    {'name': 'Table Linen', 'icon': Icons.table_restaurant},
    {'name': 'Cleaning Cloths', 'icon': Icons.cleaning_services},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  String? _serviceFrequency = 'One-Time Service';

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];

  @override
  void dispose() {
    _businessNameController.dispose();
    _weightController.dispose();
    _bagsController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    _otherBusinessTypeController.dispose();
    _otherLaundryTypeController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
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
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(pickedFiles);
      });
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
            subtitle: 'Commercial Laundry',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Name
                  _buildSectionHeader('Business Name'),
                  _buildTextField('', _businessNameController, hintText: 'Enter business name'),
                  const Divider(height: 32),

                  // Business Type
                  _buildSectionHeader('Business Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _businessTypes.map((type) {
                      final isSelected = _businessType == type['name'];
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _businessType = type['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : (isDark ? Colors.grey[850] : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type['icon'], size: 18, color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87)),
                              const SizedBox(width: 8),
                              Text(
                                type['name'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle, size: 16, color: Colors.black),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_businessType == 'Other') ...[
                    const SizedBox(height: 12),
                    _buildTextField('', _otherBusinessTypeController, hintText: 'Please specify business type'),
                  ],
                  const Divider(height: 32),

                  // Laundry Type
                  _buildSectionHeader('Laundry Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _availableLaundryTypes.map((type) {
                      final isSelected = _selectedLaundryTypes.contains(type['name']);
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedLaundryTypes.remove(type['name']);
                            } else {
                              _selectedLaundryTypes.add(type['name']);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : (isDark ? Colors.grey[850] : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type['icon'], size: 18, color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87)),
                              const SizedBox(width: 6),
                              Text(
                                type['name'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle, size: 16, color: Colors.black),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedLaundryTypes.contains('Other')) ...[
                    const SizedBox(height: 12),
                    _buildTextField('', _otherLaundryTypeController, hintText: 'Please specify laundry type'),
                  ],
                  const Divider(height: 32),

                  // Estimated Quantity
                  _buildSectionHeader('Estimated Quantity'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('', _weightController, hintText: 'Weight (kg)', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: _buildTextField('', _bagsController, hintText: 'Number of Bags', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Service Frequency
                  _buildSectionHeader('Service Frequency'),
                  Row(
                    children: ['One-Time Service', 'Recurring Service'].map((type) {
                      final isSelected = _serviceFrequency == type;
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _serviceFrequency = type;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : (isDark ? Colors.grey[850] : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGold : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? Colors.black : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    type,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),

                  // Additional Details (Tell us what you need, Describe issue, Upload Photos)
                  QuickServicesAdditionalDetails(
                    whatYouNeedController: _whatYouNeedController,
                    describeIssueController: _describeIssueController,
                    images: _selectedFiles,
                    onAddImages: _pickImages,
                    onRemoveImage: (image) {
                      setState(() {
                        _selectedFiles.remove(image);
                      });
                    },
                  ),

                  const SizedBox(height: 40),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      if (_businessNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the business name.')));
                        return;
                      }
                      if (_businessType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a business type.')));
                        return;
                      }

                      final weight = int.tryParse(_weightController.text.trim());
                      final bags = int.tryParse(_bagsController.text.trim());

                      String finalBusinessType = _businessType!;
                      if (_businessType == 'Other' && _otherBusinessTypeController.text.trim().isNotEmpty) {
                        finalBusinessType = _otherBusinessTypeController.text.trim();
                      }

                      List<String> finalLaundryTypes = List.from(_selectedLaundryTypes);
                      if (finalLaundryTypes.contains('Other') && _otherLaundryTypeController.text.trim().isNotEmpty) {
                        finalLaundryTypes.remove('Other');
                        finalLaundryTypes.add(_otherLaundryTypeController.text.trim());
                      }

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Commercial Laundry',
                        facilityName: _businessNameController.text.trim(),
                        businessType: finalBusinessType,
                        commercialLaundryTypes: finalLaundryTypes,
                        laundryQuantityKg: weight,
                        numberOfBags: bags,
                        serviceFrequency: _serviceFrequency,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        uploadedImages: _selectedFiles.map((e) => e.path).toList(),
                        baseEstimatedHours: (weight != null && weight > 0) ? (weight * 0.5 > 1.0 ? weight * 0.5 : 1.0) : 2.0,
                      );

                      context.pushNamed(RouteNames.quickServicesLaundryReview, extra: updatedData);
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
