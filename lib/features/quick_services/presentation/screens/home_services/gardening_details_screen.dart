import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';

class GardeningDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const GardeningDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<GardeningDetailsScreen> createState() => _GardeningDetailsScreenState();
}

class _GardeningDetailsScreenState extends ConsumerState<GardeningDetailsScreen> {
  bool _isUploading = false;
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


  final List<String> _selectedServiceAreas = [];
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

  void _toggleServiceArea(String area) {
    setState(() {
      if (_selectedServiceAreas.contains(area)) {
        _selectedServiceAreas.remove(area);
      } else {
        _selectedServiceAreas.add(area);
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
                  // Select Services Section
                  Text(
                    'Select Services',
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
                          height: 100, // Fixed height to fit Icon and Text vertically
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
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _icons[key] ?? Icons.yard,
                                      size: 32,
                                      color: isSelected ? AppColors.primaryGold : const Color(0xFF324461),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      key,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 10,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.check_circle, color: AppColors.primaryGold, size: 16),
                                ),
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
                      final isSelected = _selectedServiceAreas.contains(area);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleServiceArea(area),
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
                            child: Stack(
                              children: [
                                Center(
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
                                if (isSelected)
                                  const Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Icon(Icons.check_circle, color: AppColors.primaryGold, size: 14),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Materials & Tools',
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
                                _materialPreference == 'Bring materials' ? '+€${QuickServicesPricingConfig.getMaterialCost(widget.bookingData.category).toStringAsFixed(2)} extra charge' : 'Use my materials (No extra charge)',
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
                  // CONTINUE Button
                  ElevatedButton(
                    onPressed: () {
                      if (_isUploading) return;
                      final selectedKeys = _selectedServices.toList();

                      double newSubtotal = selectedKeys.length * 25.00;

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Gardening',
                        selectedAddons: [], // Clear addons so it doesn't show in price summary
                        gardeningServices: selectedKeys.isNotEmpty ? selectedKeys.join(', ') : null,
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                        gardeningServiceArea: _selectedServiceAreas.isNotEmpty ? _selectedServiceAreas.join(', ') : null,
                        gardeningApproximateArea: null,
                        greenWasteRemoval: null,
                        describeIssue: _descriptionController.text.trim().isNotEmpty
                            ? _descriptionController.text.trim()
                            : null,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty
                            ? _whatYouNeedController.text.trim()
                            : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                      );

                      if (_selectedImages.isNotEmpty) {
                        setState(() => _isUploading = true);
                        ref.read(quickServicesBookingProvider.notifier).uploadImages(
                          _selectedImages.map((e) => e.path).toList()
                        ).then((remoteUrls) {
                          if (mounted) setState(() => _isUploading = false);
                          var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
                          if (mounted) context.pushNamed(RouteNames.quickServicesGardeningReview, extra: finalDataObj);
                        }).catchError((e) {
                          if (mounted) setState(() => _isUploading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                        });
                      } else {
                        if (mounted) context.pushNamed(RouteNames.quickServicesGardeningReview, extra: updatedData);
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
