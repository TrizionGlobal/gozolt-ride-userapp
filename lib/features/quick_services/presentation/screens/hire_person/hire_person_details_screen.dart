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

class HirePersonDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const HirePersonDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<HirePersonDetailsScreen> createState() => _HirePersonDetailsScreenState();
}

class _HirePersonDetailsScreenState extends ConsumerState<HirePersonDetailsScreen> {
  bool _isUploading = false;
  final List<String> _durations = ['1 Hour', '2 Hours', '3 Hours', '4+ Hours'];
  String? _selectedDuration;
  String? _selectedGender;
  int _helperCount = 1;

  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.expectedDuration != null) {
      _selectedDuration = widget.bookingData.expectedDuration;
    }
    if (widget.bookingData.helperCount != null) {
      _helperCount = widget.bookingData.helperCount!;
    }
    if (widget.bookingData.genderPreference != null) {
      _selectedGender = widget.bookingData.genderPreference;
    }
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    } else if (widget.bookingData.comments != null) {
      _describeIssueController.text = widget.bookingData.comments!;
    }
  }

  @override
  void dispose() {
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
      debugPrint("Error picking images: $e");
    }
  }

  double _getCalculatedSubtotal(String? durationStr) {
    if (durationStr == null) return 14.0;
    if (durationStr.startsWith('1')) return 14.0;
    if (durationStr.startsWith('2')) return 28.0;
    if (durationStr.startsWith('3')) return 42.0;
    return 56.0;
  }

  void _onContinue() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender preference.')),
      );
      return;
    }
    if (_selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expected duration.')),
      );
      return;
    }

    final baseSubtotal = _getCalculatedSubtotal(_selectedDuration);
    final totalSubtotal = baseSubtotal * _helperCount;

    final commentsText = _describeIssueController.text.trim().isNotEmpty
        ? _describeIssueController.text.trim()
        : _whatYouNeedController.text.trim();

    if (commentsText.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 50 characters in the Additional Details section.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int durationHours = 2;
    if (_selectedDuration != null) {
      final match = RegExp(r'\d+').firstMatch(_selectedDuration!);
      if (match != null) {
        durationHours = int.parse(match.group(0)!);
      }
    }
    final double estimatedHours = (durationHours * _helperCount).toDouble();

    final updatedData = widget.bookingData.copyWith(
      selectedServiceTitle: 'Hire a Person',
      expectedDuration: _selectedDuration,
      helperCount: _helperCount,
      genderPreference: _selectedGender,
      whatYouNeed: _whatYouNeedController.text.trim(),
      describeIssue: _describeIssueController.text.trim(),
      comments: commentsText,
      uploadedImages: _selectedImages.map((img) => img.path).toList(),
      subtotal: 0.0,
      baseEstimatedHours: estimatedHours,
    );

    if (_isUploading) return;
    if (_selectedImages.isNotEmpty) {
      setState(() => _isUploading = true);
      ref.read(quickServicesBookingProvider.notifier).uploadImages(
        _selectedImages.map((e) => e.path).toList()
      ).then((remoteUrls) {
        if (mounted) setState(() => _isUploading = false);
        var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
        if (mounted) context.pushNamed(RouteNames.quickServicesHirePersonReview, extra: finalDataObj);
      }).catchError((e) {
        if (mounted) setState(() => _isUploading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
      });
    } else {
      if (mounted) context.pushNamed(RouteNames.quickServicesHirePersonReview, extra: updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 1,
            title: 'Service Requirements',
            subtitle: 'Hire Person',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Helper Stepper Banner Card
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF8E1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFF57F17),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$_helperCount ${_helperCount == 1 ? "Helper" : "Helpers"} Included',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF324461),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (_helperCount > 1) {
                                        setState(() => _helperCount--);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.remove, size: 16),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '$_helperCount',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() => _helperCount++);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.add, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_helperCount == 1 ? "One helper" : "$_helperCount helpers"} will be assigned for your booking.',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gender Preference Section
                  Text(
                    'Gender Preference',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF324461),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectableChip(
                          label: 'Men',
                          icon: Icons.man,
                          isSelected: _selectedGender == 'Men',
                          onTap: () => setState(() => _selectedGender = 'Men'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSelectableChip(
                          label: 'Women',
                          icon: Icons.woman,
                          isSelected: _selectedGender == 'Women',
                          onTap: () => setState(() => _selectedGender = 'Women'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSelectableChip(
                          label: 'Other',
                          icon: Icons.group,
                          isSelected: _selectedGender == 'Other',
                          onTap: () => setState(() => _selectedGender = 'Other'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Expected Duration Section
                  Text(
                    'Expected Duration',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF324461),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _durations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final duration = _durations[index];
                      final isSelected = _selectedDuration == duration;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDuration = duration;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppColors.primaryGold : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                duration,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Standard Additional Details Section
                  Text(
                    'Additional Details',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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

                  // Notice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC5CAE9)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF3F51B5), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Only lawful, safe and non-specialist tasks are permitted.',
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onContinue,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    double? width,
    double height = 48.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
