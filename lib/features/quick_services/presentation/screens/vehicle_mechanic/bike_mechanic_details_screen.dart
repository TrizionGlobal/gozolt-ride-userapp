import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../../data/models/quick_service_booking_data.dart' as model;
import 'package:image_picker/image_picker.dart';

class BikeMechanicDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const BikeMechanicDetailsScreen({super.key, required this.bookingData});

  @override
  State<BikeMechanicDetailsScreen> createState() => _BikeMechanicDetailsScreenState();
}

class _BikeMechanicDetailsScreenState extends State<BikeMechanicDetailsScreen> {
  String _materialPreference = 'Bring materials';
  String? _selectedBikeType;
  final List<String> _bikeTypes = ['Bicycle', 'E-Bike', 'Scooter', 'Motorcycle'];

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedIssue;
  final List<String> _issues = [
    'Puncture / Tyre',
    'Brake Issue',
    'Chain / Gear Issue',
    'Battery / Electrical',
    'Engine Issue',
    'General Service',
    'Other Issue'
  ];

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    super.dispose();
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
            subtitle: 'Bike Mechanic',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bike Type',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bikeTypes.map((type) {
                      final isSelected = _selectedBikeType == type;
                      IconData icon;
                      switch (type) {
                        case 'Bicycle': icon = Icons.pedal_bike; break;
                        case 'E-Bike': icon = Icons.electric_bike; break;
                        case 'Scooter': icon = Icons.moped; break;
                        default: icon = Icons.motorcycle;
                      }
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBikeType = type),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 40 - 8) / 2,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 18, color: isSelected ? Colors.black : const Color(0xFF324461)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black : const Color(0xFF324461),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.check_circle, size: 16, color: isSelected ? Colors.black : Colors.transparent),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Make'),
                  const SizedBox(height: 8),
                  _buildTextField(_makeController, '', false),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Model'),
                  const SizedBox(height: 8),
                  _buildTextField(_modelController, '', false),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Year — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_yearController, '', false),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Registration Number — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_registrationController, '', false),
                  const SizedBox(height: 24),

                  Text(
                    'What is the issue?',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
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
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(
                            issue,
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
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  Text(
                    'Materials / Parts',
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
                        color: _materialPreference == 'Bring materials' ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                        width: _materialPreference == 'Bring materials' ? 1.5 : 1,
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
                              Text('Bring materials', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                _materialPreference == 'Bring materials' ? '+€5.00 extra charge' : 'Use my materials (No extra charge)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _materialPreference == 'Bring materials' ? AppColors.primaryGold : Colors.grey[600],
                                  fontWeight: _materialPreference == 'Bring materials' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: _materialPreference == 'Bring materials',
                            activeColor: isDark ? AppColors.backgroundDark : Colors.white,
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: (val) {
                              setState(() {
                                _materialPreference = val ? 'Bring materials' : 'Use my materials';
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
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
          // Continue Button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  if (_makeController.text.trim().isEmpty || _modelController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter Make and Model.')),
                    );
                    return;
                  }
                  if (_selectedIssue == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an issue.')),
                    );
                    return;
                  }

                  final updatedData = widget.bookingData.copyWith(
                    selectedServiceTitle: 'Bike Mechanic',
                    subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                    bikeType: _selectedBikeType,
                    vehicleMake: _makeController.text.trim(),
                    vehicleModel: _modelController.text.trim(),
                    vehicleYear: _yearController.text.trim().isNotEmpty ? _yearController.text.trim() : null,
                    vehicleRegistration: _registrationController.text.trim().isNotEmpty ? _registrationController.text.trim() : null,
                    vehicleIssue: _selectedIssue,
                    whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                    describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                    uploadedImages: _selectedImages.map((e) => e.path).toList(),
                  );

                  context.pushNamed(
                    RouteNames.quickServicesBikeMechanicReview,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isMultiline) {
    return TextField(
      controller: controller,
      maxLines: isMultiline ? 4 : 1,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
