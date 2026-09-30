import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';

class BeautyWellnessDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const BeautyWellnessDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<BeautyWellnessDetailsScreen> createState() => _BeautyWellnessDetailsScreenState();
}

class _BeautyWellnessDetailsScreenState extends ConsumerState<BeautyWellnessDetailsScreen> {
  bool _isUploading = false;
  final Set<String> _selectedTreatments = {};
  final Map<String, double> _treatmentPrices = {
    'Haircut & Styling': 25.0,
    'Hair Colouring': 45.0,
    'Facial Treatment': 30.0,
    'Manicure': 20.0,
    'Pedicure': 25.0,
    'Waxing': 15.0,
    'Threading': 10.0,
    'Makeup Service': 35.0,
    'Massage & Relaxation': 40.0,
    "Men's Grooming": 20.0,
  };

  final List<Map<String, dynamic>> _treatments = [
    {'title': 'Haircut & Styling', 'priceText': '', 'price': 25.0, 'icon': Icons.content_cut, 'image': 'assets/images/beauty/beauty_haircut.jpg'},
    {'title': 'Hair Colouring', 'priceText': '', 'price': 45.0, 'icon': Icons.color_lens, 'image': 'assets/images/beauty/beauty_hair_colouring.jpg'},
    {'title': 'Facial Treatment', 'priceText': '', 'price': 30.0, 'icon': Icons.face, 'image': 'assets/images/beauty/beauty_facial.jpg'},
    {'title': 'Manicure', 'priceText': '', 'price': 20.0, 'icon': Icons.back_hand, 'image': 'assets/images/beauty/beauty_manicure.jpg'},
    {'title': 'Pedicure', 'priceText': '', 'price': 25.0, 'icon': Icons.dry, 'image': 'assets/images/beauty/beauty_pedicure.jpg'},
    {'title': 'Waxing', 'priceText': '', 'price': 15.0, 'icon': Icons.spa, 'image': 'assets/images/beauty/beauty_waxing.jpg'},
    {'title': 'Threading', 'priceText': '', 'price': 10.0, 'icon': Icons.design_services, 'image': 'assets/images/beauty/beauty_threading.jpg'},
    {'title': 'Makeup Service', 'priceText': '', 'price': 35.0, 'icon': Icons.brush, 'image': 'assets/images/beauty/beauty_makeup.jpg'},
    {'title': 'Massage & Relaxation', 'priceText': '', 'price': 40.0, 'icon': Icons.self_improvement, 'image': 'assets/images/beauty/beauty_massage.jpg'},
    {'title': "Men's Grooming", 'priceText': '', 'price': 20.0, 'icon': Icons.face_retouching_natural, 'image': 'assets/images/beauty/beauty_mens_grooming.jpg'},
  ];

  int _peopleCount = 1;
  String _professionalPreference = 'Any Professional';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customServiceController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _notesController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customServiceController.dispose();
    _describeIssueController.dispose();
    super.dispose();
  }

  double get _calculatedSubtotal {
    double sum = 0.0;
    for (final item in _selectedTreatments) {
      sum += _treatmentPrices[item] ?? 0.0;
    }
    return sum * _peopleCount;
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
      debugPrint("Error picking images: $e");
    }
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
            title: 'Select Services',
            subtitle: 'Beauty & Wellness',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Services Section
                  Text(
                    'Available Treatments & Services',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.02,
                    ),
                    itemCount: _treatments.length,
                    itemBuilder: (context, index) {
                      final item = _treatments[index];
                      final title = item['title'] as String;
                      final priceText = item['priceText'] as String;
                      final iconData = item['icon'] as IconData;
                      final String? imagePath = item['image'] as String?;
                      final isSelected = _selectedTreatments.contains(title);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTreatments.remove(title);
                            } else {
                              _selectedTreatments.add(title);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.amber.shade900.withOpacity(0.25) : const Color(0xFFFFF8E1))
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.25),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    if (imagePath != null)
                                      Image.asset(
                                        imagePath,
                                        width: double.infinity,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Container(
                                          height: 90,
                                          color: AppColors.primaryGold.withOpacity(0.15),
                                          child: Center(
                                            child: Icon(iconData, color: AppColors.primaryGold, size: 28),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 90,
                                        width: double.infinity,
                                        color: AppColors.primaryGold.withOpacity(0.15),
                                        child: Center(
                                          child: Icon(iconData, color: AppColors.primaryGold, size: 28),
                                        ),
                                      ),
                                    if (isSelected)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primaryGold,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryGold.withOpacity(0.2)
                                              : (isDark ? Colors.grey[800] : Colors.grey[100]),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          priceText,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.5,
                                            color: isSelected
                                                ? (isDark ? AppColors.primaryGold : Colors.amber.shade900)
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),


                  const SizedBox(height: 20),

                  // Number of People Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Number of People',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_peopleCount > 1) {
                                  setState(() => _peopleCount--);
                                }
                              },
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_peopleCount',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _peopleCount++),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Professional Preference
                  Text(
                    'Professional Preference',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPreferenceCard('Any Professional', Icons.group_outlined, isDark),
                      const SizedBox(width: 8),
                      _buildPreferenceCard('Female', Icons.woman, isDark),
                      const SizedBox(width: 8),
                      _buildPreferenceCard('Male', Icons.man, isDark),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Additional Details (Tell Us, Describe, Images)
                  QuickServicesAdditionalDetails(
                    whatYouNeedController: _notesController,
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

                  // Info Notice Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Service duration and final price depend on the selected treatment.',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5, height: 1.2),
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
                      if (_selectedTreatments.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select at least one treatment service'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final selectedList = _selectedTreatments.toList();
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Beauty & Wellness',
                        beautySelectedTreatments: selectedList,
                        beautyTreatmentsSubtotal: _calculatedSubtotal,
                        peopleCount: _peopleCount,
                        professionalPreference: _professionalPreference,
                        whatYouNeed: _notesController.text.trim(),
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        customBeautyService: _customServiceController.text.trim(),
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                      );

                      if (_selectedImages.isNotEmpty) {
                        setState(() => _isUploading = true);
                        ref.read(quickServicesBookingProvider.notifier).uploadImages(
                          _selectedImages.map((e) => e.path).toList()
                        ).then((remoteUrls) {
                          if (mounted) setState(() => _isUploading = false);
                          var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
                          if (mounted) {
                            context.pushNamed(RouteNames.quickServicesBeautyWellnessReview, extra: finalDataObj);
                          }
                        }).catchError((e) {
                          if (mounted) setState(() => _isUploading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                        });
                      } else {
                        if (mounted) {
                          context.pushNamed(RouteNames.quickServicesBeautyWellnessReview, extra: updatedData);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(String text, IconData icon, bool isDark) {
    final isSelected = _professionalPreference == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _professionalPreference = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.amber.shade900.withOpacity(0.3) : const Color(0xFFFFF8E1))
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryGold : const Color(0xFF324461),
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      filled: true,
      fillColor: Theme.of(context).cardTheme.color,
    );
  }
}
