import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class PestControlDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const PestControlDetailsScreen({super.key, required this.bookingData});

  @override
  State<PestControlDetailsScreen> createState() => _PestControlDetailsScreenState();
}

class _PestControlDetailsScreenState extends State<PestControlDetailsScreen> {
  String _materialPreference = 'Bring materials';
  String? _selectedPestType;
  String? _selectedPropertyType;
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
    {'name': 'Cockroaches', 'icon': Icons.bug_report},
    {'name': 'Ants', 'icon': Icons.bug_report_outlined},
    {'name': 'Rodents', 'icon': Icons.pest_control_rodent},
    {'name': 'Bed Bugs', 'icon': Icons.bed},
    {'name': 'Mosquitoes', 'icon': Icons.water_drop_outlined},
    {'name': 'Flies', 'icon': Icons.air},
    {'name': 'Wasps / Other Insects', 'icon': Icons.flutter_dash},
    {'name': 'Termites / Wood Pests', 'icon': Icons.home_repair_service},
  ];

  final List<Map<String, dynamic>> _propertyTypes = [
    {'name': 'Apartment', 'icon': Icons.apartment},
    {'name': 'House', 'icon': Icons.house},
    {'name': 'Office', 'icon': Icons.chair_alt},
    {'name': 'Shop / Commercial', 'icon': Icons.store},
    {'name': 'Farm House', 'icon': Icons.agriculture},
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
    if (_selectedPestType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Pest Type.')));
      return;
    }
    if (_selectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Property Type.')));
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


    final pestType = _selectedPestType == 'Other Pest' 
        ? (_otherPestController.text.isNotEmpty ? _otherPestController.text : 'Other Pest')
        : _selectedPestType;

    final updatedData = widget.bookingData.copyWith(
      selectedServiceTitle: 'Pest Control',
      pestType: pestType,
      propertyType: _selectedPropertyType,
      pestAffectedAreas: _selectedAffectedAreas,
      pestAffectedRooms: _affectedRoomsCount,
      pestObservedLevel: _selectedObservedLevel,
      describeIssue: _problemDescriptionController.text.trim(),
      uploadedImages: _selectedImages.map((f) => f.path).toList(),
      subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
    );

    context.pushNamed(RouteNames.quickServicesPestControlReview, extra: updatedData);
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

  Widget _buildGridSelection(List<Map<String, dynamic>> items, String? selectedValue, ValueChanged<String> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedValue == item['name'];
        return GestureDetector(
          onTap: () => onChanged(item['name']),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Pest Control Requirements',
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
                  _buildGridSelection(_pestTypes, _selectedPestType, (val) => setState(() => _selectedPestType = val)),

                  // 2. Property Type
                  _buildSectionHeader('2', 'Property Type'),
                  _buildGridSelection(_propertyTypes, _selectedPropertyType, (val) => setState(() => _selectedPropertyType = val)),

                  // 3. Affected Areas
                  _buildSectionHeader('3', 'Affected Areas', subtitle: '(Select all that apply)'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _affectedAreasOptions.map((area) {
                      final isSelected = _selectedAffectedAreas.contains(area);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAffectedAreas.remove(area);
                            } else {
                              _selectedAffectedAreas.add(area);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                area,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, color: Colors.black, size: 16),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Number of Affected Rooms', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (_affectedRoomsCount > 1) {
                                  setState(() => _affectedRoomsCount--);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.remove, size: 20),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('$_affectedRoomsCount', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _affectedRoomsCount++);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.add, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 4. Observed Pest Level
                  _buildSectionHeader('4', 'Observed Pest Level', subtitle: '\nThis helps the professional estimate the required treatment.'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _observedLevels.map((level) {
                      final isSelected = _selectedObservedLevel == level;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedObservedLevel = level),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            level,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),


                  
                  const SizedBox(height: 16),

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
                    child: Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
