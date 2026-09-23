import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../../data/models/quick_service_booking_data.dart' as model;
import 'package:image_picker/image_picker.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';

class BikeMechanicDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const BikeMechanicDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<BikeMechanicDetailsScreen> createState() => _BikeMechanicDetailsScreenState();
}

class _BikeMechanicDetailsScreenState extends ConsumerState<BikeMechanicDetailsScreen> {
  bool _isUploading = false;
  String _materialPreference = 'Bring tools';
  
  final List<MechanicVehicle> _savedVehicles = [];

  void _addVehicle() {
    if (
        _typeController.text.trim().isEmpty ||
        _makeController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty ||
        _selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required car details and select an issue.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _savedVehicles.add(MechanicVehicle(
        type: _typeController.text.trim(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.trim().isNotEmpty ? _yearController.text.trim() : null,
        registration: _registrationController.text.trim().isNotEmpty ? _registrationController.text.trim() : null,
        mileage: _mileageController.text.trim().isNotEmpty ? _mileageController.text.trim() : null,
        issue: _selectedIssue!,
      ));

      // Reset form
      _selectedCarType = null;
      _typeController.clear();
      _makeController.clear();
      _modelController.clear();
      _yearController.clear();
      _registrationController.clear();
      _mileageController.clear();
      _selectedIssue = null;

      FocusScope.of(context).unfocus();
    });
  }

  void _removeVehicle(int index) {
    setState(() {
      _savedVehicles.removeAt(index);
    });
  }

  String? _selectedCarType;
  final List<String> _carTypes = ['Hatchback', 'Sedan', 'SUV', 'Van', 'Electric / Hybrid'];

  final TextEditingController _typeController = TextEditingController();
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
    _typeController.dispose();
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
            subtitle: 'Bike Mechanic',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // --- VEHICLE FORM ---
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
                        Text(
                          'Add a Bike',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                  _buildLabel('Bike Type'),
                  const SizedBox(height: 8),
                  _buildTextField(_typeController, 'e.g. Sports, Cruiser', false),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Bike Make'),
                            const SizedBox(height: 8),
                            _buildTextField(_makeController, 'e.g. Yamaha', false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Bike Model'),
                            const SizedBox(height: 8),
                            _buildTextField(_modelController, 'e.g. YZF-R1', false),
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
                            _buildTextField(_yearController, 'e.g. 2018', false),
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
                            _buildTextField(_registrationController, 'e.g. AB12 CDE', false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Mileage — Optional'),
                  const SizedBox(height: 8),
                  _buildTextField(_mileageController, 'e.g. 50,000 km', false),
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
                          width: (MediaQuery.of(context).size.width - 100) / 3, // 3 columns
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

                  
                        const SizedBox(height: 24),
                        // Add Vehicle Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _addVehicle,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.primaryGold : const Color(0xFFD97706),
                              side: BorderSide(color: isDark ? AppColors.primaryGold : const Color(0xFFD97706)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline, size: 20),
                                const SizedBox(width: 8),
                                Text('Add Bike', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LIST OF ADDED VEHICLES ---
                  if (_savedVehicles.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Added Bikes (${_savedVehicles.length})',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _savedVehicles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vehicle = _savedVehicles[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.motorcycle, color: AppColors.primaryGold, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${vehicle.make} ${vehicle.model}',
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Type: ${vehicle.type}',
                                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removeVehicle(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(height: 1),
                              ),
                              Text(
                                'Issue: ${vehicle.issue}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.red[700]),
                              ),
                              if (vehicle.registration != null || vehicle.year != null || vehicle.mileage != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (vehicle.year != null) 'Year: ${vehicle.year}',
                                    if (vehicle.registration != null) 'Reg: ${vehicle.registration}',
                                    if (vehicle.mileage != null) 'Mileage: ${vehicle.mileage}',
                                  ].join(' | '),
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
Text(
                    'Required Tools',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _materialPreference = _materialPreference == 'Bring tools' ? 'Use my tools' : 'Bring tools';
                      });
                    },
                    child: Container(
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
                                _materialPreference == 'Bring tools' ? '+€${QuickServicesPricingConfig.getMaterialCost(widget.bookingData.category).toStringAsFixed(2)} extra charge' : 'Use my tools (No extra charge)',
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
                                _materialPreference = val ? 'Bring materials' : 'Use my tools';
                              });
                            },
                          ),
                        ),
                      ],
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
                  
                  const SizedBox(height: 24),
                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      if (_isUploading) return;
                      if (_savedVehicles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add at least one bike to proceed.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final updatedBookingData = widget.bookingData.copyWith(
                        mechanicVehicles: _savedVehicles,
                        whatYouNeed: _whatYouNeedController.text.isNotEmpty ? _whatYouNeedController.text : null,
                        describeIssue: _describeIssueController.text.isNotEmpty ? _describeIssueController.text : null,
                        uploadedImages: _selectedImages.map((f) => f.path).toList(),
                        selectedServiceTitle: 'Bike Mechanic',
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                      );

                      if (_selectedImages.isNotEmpty) {
                        setState(() => _isUploading = true);
                        ref.read(quickServicesBookingProvider.notifier).uploadImages(
                          _selectedImages.map((e) => e.path).toList()
                        ).then((remoteUrls) {
                          if (mounted) setState(() => _isUploading = false);
                          var finalDataObj = updatedBookingData.copyWith(uploadedImages: remoteUrls);
                          if (mounted) context.pushNamed(RouteNames.quickServicesBikeMechanicReview, extra: finalDataObj);
                        }).catchError((e) {
                          if (mounted) setState(() => _isUploading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                        });
                      } else {
                        if (mounted) context.pushNamed(RouteNames.quickServicesBikeMechanicReview, extra: updatedBookingData);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
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
      textCapitalization: isNumber ? TextCapitalization.none : TextCapitalization.words,
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
