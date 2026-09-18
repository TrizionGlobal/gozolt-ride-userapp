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

class GardeningDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const GardeningDetailsScreen({super.key, required this.bookingData});

  @override
  State<GardeningDetailsScreen> createState() => _GardeningDetailsScreenState();
}

class _GardeningDetailsScreenState extends State<GardeningDetailsScreen> {
  String _materialPreference = 'Bring materials';
  final Set<String> _selectedServices = {};

  final Map<String, IconData> _icons = {
    'Lawn Mowing': Icons.grass,
    'Hedge Trimming': Icons.content_cut,
    'Tree / Plant Pruning': Icons.park,
    'Weeding': Icons.cleaning_services,
    'Planting': Icons.local_florist,
    'Leaf & Garden Cleanup': Icons.eco,
    'General Garden Maintenance': Icons.yard,
    'Terrace / Balcony Gardening': Icons.deck,
    'Other Gardening Work': Icons.miscellaneous_services,
  };

  final Map<String, double> _hours = {
    'Lawn Mowing': 1.0,
    'Hedge Trimming': 1.0,
    'Tree / Plant Pruning': 1.5,
    'Weeding': 1.0,
    'Planting': 1.0,
    'Leaf & Garden Cleanup': 1.5,
    'General Garden Maintenance': 2.0,
    'Terrace / Balcony Gardening': 1.0,
    'Other Gardening Work': 1.0,
  };


  String? _selectedServiceArea;
  final List<String> _serviceAreas = ['Garden', 'Yard', 'Terrace / Balcony'];

  String? _selectedApproxArea;
  final List<String> _approxAreas = [
    'Small – Below 50 m²',
    'Medium – 50–150 m²',
    'Large – Above 150 m²',
    'Not Sure',
  ];

  String? _greenWasteRemoval;
  final List<String> _wasteOptions = ['Yes', 'No'];

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();

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

  void _toggleService(String key) {
    setState(() {
      if (_selectedServices.contains(key)) {
        _selectedServices.remove(key);
      } else {
        _selectedServices.add(key);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _whatYouNeedController.dispose();
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
            subtitle: 'Gardening',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Gardening Services Section
                  Text(
                    'Select Gardening Services',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _icons.keys.map((key) {
                      final isSelected = _selectedServices.contains(key);

                      return GestureDetector(
                        onTap: () => _toggleService(key),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 50) / 2,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGold.withValues(alpha: 0.15)
                                : (isDark ? Colors.grey[850] : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                _icons[key] ?? Icons.yard,
                                size: 18,
                                color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  key,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 16, color: Colors.black),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Service Area Section
                  Text(
                    'Service Area',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: _serviceAreas.map((area) {
                      final isSelected = _selectedServiceArea == area;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedServiceArea = area),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGold.withValues(alpha: 0.15)
                                  : (isDark ? Colors.grey[850] : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      area,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle, size: 14, color: Colors.black),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Approximate Area Section
                  Text(
                    'Approximate Area',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _approxAreas.length,
                    itemBuilder: (context, index) {
                      final approx = _approxAreas[index];
                      final isSelected = _selectedApproxArea == approx;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedApproxArea = approx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGold.withValues(alpha: 0.15)
                                : (isDark ? Colors.grey[850] : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  approx,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 14, color: Colors.black),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Green waste removal required? Section
                  Text(
                    'Green waste removal required?',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: _wasteOptions.map((opt) {
                      final isSelected = _greenWasteRemoval == opt;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _greenWasteRemoval = opt),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGold.withValues(alpha: 0.15)
                                  : (isDark ? Colors.grey[850] : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  opt,
                                  style: AppTextStyles.bodyMedium.copyWith(
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
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Standard additional details component (Tell us what you need, Describe issue, Upload Photos)
                  QuickServicesAdditionalDetails(
                    showTellUsWhatYouNeed: true,
                    whatYouNeedController: _whatYouNeedController,
                    describeIssueController: _descriptionController,
                    images: _selectedImages,
                    onAddImages: _pickImages,
                    onRemoveImage: (file) {
                      setState(() {
                        _selectedImages.remove(file);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Info Notice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Final price may change after the professional inspects the garden.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.blue[200] : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CONTINUE Button
                  ElevatedButton(
                    onPressed: () {
                      final selectedKeys = _selectedServices.toList();

                      List<ServiceAddon> selectedAddons = selectedKeys.map((key) {
                        return ServiceAddon(name: key, count: 1, hoursPerUnit: _hours[key]!);
                      }).toList();

                      double newSubtotal = selectedKeys.length * 25.00;

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Gardening',
                        selectedAddons: selectedAddons,
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                        gardeningServiceArea: _selectedServiceArea,
                        gardeningApproximateArea: _selectedApproxArea,
                        greenWasteRemoval: _greenWasteRemoval,
                        describeIssue: _descriptionController.text.trim().isNotEmpty
                            ? _descriptionController.text.trim()
                            : null,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty
                            ? _whatYouNeedController.text.trim()
                            : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                      );

                      context.pushNamed(
                        RouteNames.quickServicesGardeningReview,
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
