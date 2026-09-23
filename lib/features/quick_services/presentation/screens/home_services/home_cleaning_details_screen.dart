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

class HomeCleaningDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const HomeCleaningDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<HomeCleaningDetailsScreen> createState() => _HomeCleaningDetailsScreenState();
}

class _HomeCleaningDetailsScreenState extends ConsumerState<HomeCleaningDetailsScreen> {
  bool _isUploading = false;
  final Map<String, int> _counts = {
    'Bathrooms': 0,
    'Bedrooms': 0,
    'Kitchen Cleaning': 0,
    'Hall': 0,
    'Fans': 0,
    'Exhaust Fans': 0,
    'Cupboards': 0,
    'Chimney': 0,
    'Corridor / Terrace': 0,
  };

  final Map<String, double> _hours = {
    'Bathrooms': 1.0,
    'Bedrooms': 1.0,
    'Kitchen Cleaning': 1.5,
    'Hall': 1.0,
    'Fans': 0.25,
    'Exhaust Fans': 0.25,
    'Cupboards': 0.5,
    'Chimney': 0.5,
    'Corridor / Terrace': 0.5,
  };

  final Map<String, IconData> _icons = {
    'Bathrooms': Icons.bathtub_outlined,
    'Bedrooms': Icons.bed_outlined,
    'Kitchen Cleaning': Icons.countertops_outlined,
    'Hall': Icons.weekend_outlined,
    'Fans': Icons.wind_power_outlined,
    'Exhaust Fans': Icons.cyclone_outlined,
    'Cupboards': Icons.kitchen_outlined,
    'Chimney': Icons.fireplace_outlined,
    'Corridor / Terrace': Icons.balcony_outlined,
  };

  String _materialPreference = 'Bring materials';

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

  double get _subtotal {
    double total = 0;
    _counts.forEach((key, count) {
      total += count * (_hours[key] ?? 0.0);
    });
    return total;
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
            subtitle: 'Home Cleaning',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select the areas you want cleaned',
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
                        final isLast = key == _counts.keys.last;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(_icons[key], size: 22, color: Colors.grey.shade600),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      key,
                                      style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
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
                                          '${_counts[key]}',
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
                    'Cleaning materials',
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
                          child: const Icon(Icons.cleaning_services, size: 24, color: AppColors.primaryGold),
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
                  SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isUploading) return;
                        if (_subtotal == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please select at least one area to clean to continue.', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        List<ServiceAddon> selectedAddons = [];
                        _counts.forEach((key, count) {
                          if (count > 0) {
                            selectedAddons.add(ServiceAddon(
                              name: key,
                              count: count,
                              hoursPerUnit: _hours[key]!,
                            ));
                          }
                        });


                        final updatedData = widget.bookingData.copyWith(
                          selectedAddons: selectedAddons,
                          materialPreference: _materialPreference,
                          subtotal: 0.0,
                          baseEstimatedHours: 0.0,
                          whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                          describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                          uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        );
  
                        if (_selectedImages.isNotEmpty) {
                          setState(() => _isUploading = true);
                          ref.read(quickServicesBookingProvider.notifier).uploadImages(
                            _selectedImages.map((e) => e.path).toList()
                          ).then((remoteUrls) {
                            if (mounted) setState(() => _isUploading = false);
                            var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
                            if (mounted) context.pushNamed(RouteNames.quickServicesHomeCleaningReview, extra: finalDataObj);
                          }).catchError((e) {
                            if (mounted) setState(() => _isUploading = false);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                          });
                        } else {
                          if (mounted) context.pushNamed(RouteNames.quickServicesHomeCleaningReview, extra: updatedData);
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
