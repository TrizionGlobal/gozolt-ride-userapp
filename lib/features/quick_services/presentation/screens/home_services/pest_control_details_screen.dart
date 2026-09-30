import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';

class PestControlDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const PestControlDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<PestControlDetailsScreen> createState() => _PestControlDetailsScreenState();
}

class _PestControlDetailsScreenState extends ConsumerState<PestControlDetailsScreen> {
  bool _isUploading = false;
  String _materialPreference = 'Bring materials';
  List<String> _selectedPestTypes = [];
  List<String> _selectedPropertyTypes = [];
  final List<String> _selectedAffectedAreas = [];
  int _affectedRoomsCount = 2;
  String? _selectedObservedLevel;
  
  final TextEditingController _otherPestController = TextEditingController();
  final TextEditingController _problemDescriptionController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  final List<Map<String, dynamic>> _pestTypes = [
    {'name': 'Ants / Mosquitoes', 'icon': Icons.pest_control},
    {'name': 'Cockroaches / Flies', 'icon': Icons.bug_report},
    {'name': 'Wasps / Wood Pests', 'icon': Icons.emoji_nature},
    {'name': 'Rodents / Bed Bugs', 'icon': Icons.pest_control_rodent},
  ];

  final List<Map<String, dynamic>> _propertyTypes = [
    {'name': 'Home', 'icon': Icons.house},
    {'name': 'Office', 'icon': Icons.chair_alt},
    {'name': 'Commercial', 'icon': Icons.store},
  ];

  final List<String> _affectedAreasOptions = [
    'Kitchen', 'Bathroom', 'Bedroom', 'Living Area', 'Garden / Outdoor', 'Entire Property'
  ];

  final List<String> _observedLevels = [
    'Low', 'Medium', 'High', 'Not Sure'
  ];

  @override
  void dispose() {
    _otherPestController.dispose();
    _problemDescriptionController.dispose();
    _whatYouNeedController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_isUploading) return;
    if (_selectedPestTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one Pest Type.')));
      return;
    }
    if (_selectedPropertyTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one Property Type.')));
      return;
    }
    if (_selectedAffectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one Affected Area.')));
      return;
    }
    if (_selectedObservedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Observed Pest Level.')));
      return;
    }


    final pestType = _selectedPestTypes.join(', ');

    final updatedData = widget.bookingData.copyWith(
      selectedServiceTitle: 'Pest Control',
      pestType: pestType,
      propertyType: _selectedPropertyTypes.join(', '),
      pestAffectedAreas: _selectedAffectedAreas,
      pestAffectedRooms: _affectedRoomsCount,
      pestObservedLevel: _selectedObservedLevel,
      describeIssue: _problemDescriptionController.text.trim(),
      uploadedImages: _selectedImages.map((f) => f.path).toList(),
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
        var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
        if (mounted) context.pushNamed(RouteNames.quickServicesPestControlReview, extra: finalDataObj);
      }).catchError((e) {
        if (mounted) setState(() => _isUploading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
      });
    } else {
      if (mounted) context.pushNamed(RouteNames.quickServicesPestControlReview, extra: updatedData);
    }
  }

  Widget _buildSectionHeader(String number, String title, {String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (subtitle != null && !subtitle.contains('\n')) ...[
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle.contains('\n')) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle.replaceAll('\n', ''),
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSelection(List<Map<String, dynamic>> items, List<String> selectedValues, ValueChanged<String> onToggle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: items.length == 4 ? 2 : 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: items.length == 4 ? 2.0 : 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedValues.contains(item['name']);
        return GestureDetector(
          onTap: () => onToggle(item['name']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'],
                        color: isSelected ? AppColors.primaryGold : const Color(0xFF324461),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                      if (item['name'] == 'Other Pest' || item['name'] == 'Other')
                        Text(
                          item['name'] == 'Other Pest' ? 'Describe it below' : '',
                          style: TextStyle(fontSize: 8, color: Colors.grey),
                        )
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
      },
    );
  }
  Widget _buildTextGridSelection(List<String> items, List<String> selectedValues, ValueChanged<String> onToggle, {int crossAxisCount = 3, double childAspectRatio = 2.5}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedValues.contains(item);
        return GestureDetector(
          onTap: () => onToggle(item),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    item,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.check_circle, color: AppColors.primaryGold, size: 14),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
            subtitle: 'Pest Control',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Select Pest Type
                  _buildSectionHeader('1', 'Select Pest Type'),
                  _buildGridSelection(
                    _pestTypes,
                    _selectedPestTypes,
                    (val) {
                      setState(() {
                        if (_selectedPestTypes.contains(val)) {
                          _selectedPestTypes.remove(val);
                        } else {
                          _selectedPestTypes.add(val);
                        }
                      });
                    },
                  ),

                  // 2. Property Type
                  _buildSectionHeader('2', 'Property Type'),
                  _buildGridSelection(
                    _propertyTypes,
                    _selectedPropertyTypes,
                    (val) {
                      setState(() {
                        if (_selectedPropertyTypes.contains(val)) {
                          _selectedPropertyTypes.remove(val);
                        } else {
                          _selectedPropertyTypes.add(val);
                        }
                      });
                    },
                  ),

                  // 3. Affected Areas
                  _buildSectionHeader('3', 'Affected Areas', subtitle: '(Select all that apply)'),
                  _buildTextGridSelection(
                    _affectedAreasOptions,
                    _selectedAffectedAreas,
                    (val) {
                      setState(() {
                        if (_selectedAffectedAreas.contains(val)) {
                          _selectedAffectedAreas.remove(val);
                        } else {
                          _selectedAffectedAreas.add(val);
                        }
                      });
                    },
                  ),
                  
                  // 4. Observed Pest Level
                  _buildSectionHeader('4', 'Observed Pest Level', subtitle: '\nThis helps the professional estimate the required treatment.'),
                  _buildTextGridSelection(
                    _observedLevels,
                    _selectedObservedLevel != null ? [_selectedObservedLevel!] : [],
                    (val) {
                      setState(() {
                        _selectedObservedLevel = val;
                      });
                    },
                    crossAxisCount: 4,
                    childAspectRatio: 2.2,
                  ),


                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('5', 'Required Materials'),
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

                  // Standardized details section
                  QuickServicesAdditionalDetails(
                    whatYouNeedController: _whatYouNeedController,
                    describeIssueController: _problemDescriptionController,
                    images: _selectedImages,
                    onAddImages: _pickImages,
                    onRemoveImage: _removeImage,
                    showTellUsWhatYouNeed: false,
                  ),

                  const SizedBox(height: 24),
                  
                  // Info Notice Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF1967D2), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Follow the professional's preparation and safe re-entry instructions.",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF1967D2),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue Button
                  ElevatedButton(
                    onPressed: _onContinue,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
