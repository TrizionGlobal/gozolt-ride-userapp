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

class TruckMechanicDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const TruckMechanicDetailsScreen({super.key, required this.bookingData});

  @override
  State<TruckMechanicDetailsScreen> createState() => _TruckMechanicDetailsScreenState();
}

class _TruckMechanicDetailsScreenState extends State<TruckMechanicDetailsScreen> {
  String _materialPreference = 'Bring materials';
  String? _selectedTruckType;
  final List<String> _truckTypes = ['Light Duty', 'Heavy Duty', 'Trailer', 'Box Truck'];

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedIssue;
  final List<String> _issues = [
    'Battery Issue',
    'Flat Tyre',
    'Brake Issue',
    'Engine Issue',
    'Overheating',
    'Electrical Issue',
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
    _mileageController.dispose();
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
            subtitle: 'Truck Mechanic',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Type',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _truckTypes.map((type) {
                      final isSelected = _selectedTruckType == type;
                      IconData icon;
                      switch (type) {
                        case 'Light Duty': icon = Icons.local_shipping_outlined; break;
                        case 'Heavy Duty': icon = Icons.fire_truck_outlined; break;
                        case 'Trailer': icon = Icons.rv_hookup_outlined; break;
                        case 'Box Truck': icon = Icons.delivery_dining_outlined; break;
                        default: icon = Icons.local_shipping;
                      }
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTruckType = type),
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
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Make'),
                            const SizedBox(height: 8),
                            _buildTextField(_makeController, '', false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Model'),
                            const SizedBox(height: 8),
                            _buildTextField(_modelController, '', false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Year — Optional'),
                            const SizedBox(height: 8),
                            _buildTextField(_yearController, '', false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Registration Number'),
                            const SizedBox(height: 8),
                            _buildTextField(_registrationController, '', false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Mileage — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_mileageController, '', false),
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
                          width: (MediaQuery.of(context).size.width - 40 - 16) / 3, // 3 columns
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            issue,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black : const Color(0xFF324461),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
                  const SizedBox(height: 16),
                  
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Upload the full vehicle, affected area and dashboard warning lights.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Vehicle unsafe or stopped in traffic? Move to a safe place if possible and call 112 for immediate danger.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
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
                  if (_selectedTruckType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Truck Type.')));
                    return;
                  }
                  final updatedBookingData = widget.bookingData.copyWith(
                    truckType: _selectedTruckType,
                    vehicleMake: _makeController.text.isNotEmpty ? _makeController.text : null,
                    vehicleModel: _modelController.text.isNotEmpty ? _modelController.text : null,
                    vehicleYear: _yearController.text.isNotEmpty ? _yearController.text : null,
                    vehicleRegistration: _registrationController.text.isNotEmpty ? _registrationController.text : null,
                    mileage: _mileageController.text.isNotEmpty ? _mileageController.text : null,
                    vehicleIssue: _selectedIssue,
                    whatYouNeed: _whatYouNeedController.text.isNotEmpty ? _whatYouNeedController.text : null,
                    describeIssue: _describeIssueController.text.isNotEmpty ? _describeIssueController.text : null,
                    uploadedImages: _selectedImages.map((f) => f.path).toList(),
                    selectedServiceTitle: 'Truck Mechanic',
                    subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                  );
                  context.pushNamed(
                    RouteNames.quickServicesTruckMechanicReview,
                    extra: updatedBookingData,
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
      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isNumber) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
