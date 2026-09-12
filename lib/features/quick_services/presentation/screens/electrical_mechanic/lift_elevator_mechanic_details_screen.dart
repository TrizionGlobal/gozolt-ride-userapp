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

class LiftElevatorMechanicDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const LiftElevatorMechanicDetailsScreen({super.key, required this.bookingData});

  @override
  State<LiftElevatorMechanicDetailsScreen> createState() => _LiftElevatorMechanicDetailsScreenState();
}

class _LiftElevatorMechanicDetailsScreenState extends State<LiftElevatorMechanicDetailsScreen> {
  String? _selectedPropertyType;
  String? _selectedLiftType;
  
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  
  final List<String> _issues = [
    'Lift Not Moving', 'Door Problem', 'Unusual Noise',
    'Uneven Leveling', 'Button / Display Fault', 'Routine Maintenance', 'Other Issue'
  ];
  String? _selectedIssue;

  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _floorsController.dispose();
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.titleSmall.copyWith(
        fontWeight: FontWeight.bold, 
        color: const Color(0xFF324461)
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }

  Widget _buildChips(List<String> options, String? selectedValue, ValueChanged<String?> onSelected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;

        return GestureDetector(
          onTap: () {
            onSelected(isSelected ? null : option);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : const Color(0xFF324461),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIssueChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _issues.map((issue) {
        final isSelected = _selectedIssue == issue;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIssue = isSelected ? null : issue;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              issue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : const Color(0xFF324461),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: () {
              if (_selectedPropertyType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a Property Type.')),
                );
                return;
              }
              if (_selectedLiftType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a Lift Type.')),
                );
                return;
              }
              if (_selectedIssue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an issue.')),
                );
                return;
              }
              
              if (_selectedImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please upload at least one photo or video of the issue.')),
                );
                return;
              }

              final updatedData = widget.bookingData.copyWith(
                selectedServiceTitle: 'Lift / Elevator Mechanic',
                subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                propertyType: _selectedPropertyType,
                liftType: _selectedLiftType,
                vehicleMake: _manufacturerController.text.trim().isNotEmpty ? _manufacturerController.text.trim() : null, // Reusing vehicleMake for Manufacturer
                vehicleModel: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null, // Reusing vehicleModel for Model
                floorsServed: _floorsController.text.trim().isNotEmpty ? _floorsController.text.trim() : null,
                vehicleIssue: _selectedIssue, // Reusing vehicleIssue for Issue
                whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                uploadedImages: _selectedImages.map((e) => e.path).toList(),
              );

              context.pushNamed(
                RouteNames.quickServicesLiftElevatorReview,
                extra: updatedData,
              );
            },
            child: Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
          ),
        ),
      ),
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
                  _buildLabel('Property Type'),
                  const SizedBox(height: 12),
                  _buildChips(
                    ['Residential Building', 'Commercial Building', 'Hotel', 'Other'], 
                    _selectedPropertyType, 
                    (val) => setState(() => _selectedPropertyType = val)
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Lift Type'),
                  const SizedBox(height: 12),
                  _buildChips(
                    ['Passenger Lift', 'Goods Lift', 'Platform Lift', 'Stairlift', 'Not Sure'], 
                    _selectedLiftType, 
                    (val) => setState(() => _selectedLiftType = val)
                  ),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Manufacturer / Brand — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_manufacturerController, ''),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Model / Serial Number — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_modelController, ''),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Floors Served — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_floorsController, '', isNumber: true),
                  const SizedBox(height: 24),

                  _buildLabel('What is the issue?'),
                  const SizedBox(height: 12),
                  _buildIssueChips(),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
