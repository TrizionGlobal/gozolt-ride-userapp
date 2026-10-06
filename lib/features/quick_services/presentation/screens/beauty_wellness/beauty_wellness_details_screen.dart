import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  List<Map<String, dynamic>> _treatments = [];

  int _peopleCount = 1;
  String _professionalPreference = 'Any Professional';
  String _materialPreference = 'Bring products';
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
    _loadTreatments();
  }

  void _loadTreatments() {
    final sub = widget.bookingData.selectedServiceTitle ?? 'Female';
    if (sub == 'Female' || sub == 'Others') {
      _treatments = [
        {'title': 'Body Care', 'category': 'Skin', 'price': 30.0, 'icon': Icons.spa, 'image': 'assets/images/beauty/beauty_skin_care.jpg'},
        {'title': 'Facials', 'category': 'Skin', 'price': 40.0, 'icon': Icons.face, 'image': 'assets/images/beauty/women_facial.jpg'},
        {'title': 'Clean up', 'category': 'Skin', 'price': 20.0, 'icon': Icons.cleaning_services, 'image': 'assets/images/beauty/women_facial.jpg'},
        {'title': 'Waxing', 'category': 'Skin', 'price': 25.0, 'icon': Icons.healing, 'image': 'assets/images/beauty/women_waxing.jpg'},
        {'title': 'Everyday Essentials', 'category': 'Skin', 'price': 15.0, 'icon': Icons.eco, 'image': 'assets/images/beauty/beauty_skin_care.jpg'},
        {'title': 'Haircut', 'category': 'Hair', 'price': 25.0, 'icon': Icons.content_cut, 'image': 'assets/images/beauty/beauty_haircut.jpg'},
        {'title': 'Colors', 'category': 'Hair', 'price': 45.0, 'icon': Icons.color_lens, 'image': 'assets/images/beauty/beauty_haircut.jpg'},
        {'title': 'Texture', 'category': 'Hair', 'price': 35.0, 'icon': Icons.waves, 'image': 'assets/images/beauty/beauty_haircut.jpg'},
        {'title': 'Hair Spa', 'category': 'Hair', 'price': 50.0, 'icon': Icons.spa, 'image': 'assets/images/beauty/beauty_haircut.jpg'},
        {'title': 'Hair Style', 'category': 'Hair', 'price': 30.0, 'icon': Icons.style, 'image': 'assets/images/beauty/beauty_haircut.jpg'},
        {'title': 'Party Makeup', 'category': 'Makeup', 'price': 40.0, 'icon': Icons.brush, 'image': 'assets/images/beauty/beauty_makeup.jpg'},
        {'title': 'Bridal Makeup', 'category': 'Makeup', 'price': 120.0, 'icon': Icons.face_retouching_natural, 'image': 'assets/images/beauty/women_bridal_makeup.jpg'},
        {'title': 'Makeup', 'category': 'Makeup', 'price': 35.0, 'icon': Icons.brush, 'image': 'assets/images/beauty/beauty_makeup.jpg'},
        {'title': 'Outdoor', 'category': 'Makeup', 'price': 50.0, 'icon': Icons.nature_people, 'image': 'assets/images/beauty/beauty_makeup.jpg'},
        {'title': 'Saaree drape', 'category': 'Makeup', 'price': 20.0, 'icon': Icons.checkroom, 'image': 'assets/images/beauty/women_saaree_drape.jpg'},
        {'title': 'Special Occasion', 'category': 'Makeup', 'price': 60.0, 'icon': Icons.celebration, 'image': 'assets/images/beauty/women_bridal_makeup.jpg'},
        {'title': 'Manicure', 'category': 'Hand & Feet', 'price': 20.0, 'icon': Icons.back_hand, 'image': 'assets/images/beauty/beauty_manicure_pedicure.jpg'},
        {'title': 'Pedicure', 'category': 'Hand & Feet', 'price': 25.0, 'icon': Icons.dry, 'image': 'assets/images/beauty/beauty_manicure_pedicure.jpg'},
        {'title': 'Nails', 'category': 'Hand & Feet', 'price': 15.0, 'icon': Icons.touch_app, 'image': 'assets/images/beauty/beauty_manicure_pedicure.jpg'},
      ];
    } else if (sub == 'Male') {
      _treatments = [
        {'title': 'Facials', 'category': 'Skin', 'price': 35.0, 'icon': Icons.face_retouching_natural, 'image': 'assets/images/beauty/men_facial.jpg'},
        {'title': 'Clean up', 'category': 'Skin', 'price': 20.0, 'icon': Icons.face_retouching_natural, 'image': 'assets/images/beauty/men_facial.jpg'},
        {'title': 'Haircut', 'category': 'Hair', 'price': 20.0, 'icon': Icons.content_cut, 'image': 'assets/images/beauty/men_haircut.jpg'},
        {'title': 'Colors', 'category': 'Hair', 'price': 40.0, 'icon': Icons.color_lens, 'image': 'assets/images/beauty/men_haircut.jpg'},
        {'title': 'Texture', 'category': 'Hair', 'price': 30.0, 'icon': Icons.waves, 'image': 'assets/images/beauty/men_haircut.jpg'},
        {'title': 'Hair Spa', 'category': 'Hair', 'price': 45.0, 'icon': Icons.spa, 'image': 'assets/images/beauty/men_haircut.jpg'},
        {'title': 'Party Makeup', 'category': 'Makeup', 'price': 30.0, 'icon': Icons.brush, 'image': 'assets/images/beauty/beauty_makeup.jpg'},
        {'title': 'Manicure', 'category': 'Hand & Feet', 'price': 15.0, 'icon': Icons.vaccines, 'image': 'assets/images/beauty/men_manicure.jpg'},
        {'title': 'Pedicure', 'category': 'Hand & Feet', 'price': 20.0, 'icon': Icons.spa, 'image': 'assets/images/beauty/men_manicure.jpg'},
      ];
    } else if (sub == 'Kids') {
      _treatments = [
        {'title': 'Hair Cut & Styling', 'category': 'Kids', 'price': 15.0, 'icon': Icons.content_cut, 'desc': 'No tears, just happy vibes!', 'image': 'assets/images/beauty/child_haircut.png'},
        {'title': 'Body Massage & Nourishment', 'category': 'Kids', 'price': 30.0, 'icon': Icons.volunteer_activism, 'desc': 'Calm minds, happy bodies', 'image': 'assets/images/beauty/child_body_massage.png'},
        {'title': 'Hydrotherapy for Infants', 'category': 'Kids', 'price': 50.0, 'icon': Icons.water_drop, 'desc': 'Gentle water therapy for your newborn', 'image': 'assets/images/beauty/child_hydrotheraphy.png'},
        {'title': 'Party Makeover', 'category': 'Kids', 'price': 25.0, 'icon': Icons.workspace_premium, 'desc': 'Look magical for your special day', 'image': 'assets/images/beauty/child_makover.png'},
        {'title': 'Spa Parties', 'category': 'Kids', 'price': 25.0, 'icon': Icons.spa, 'desc': 'The most magical birthday ever', 'image': 'assets/images/beauty/child_spa_parties.png'},
        {'title': 'Mani-Pedi for Kids', 'category': 'Kids', 'price': 20.0, 'icon': Icons.vaccines, 'desc': 'Tiny nails, big smiles', 'image': 'assets/images/beauty/child_mani_pedi.png'},
        {'title': 'Hair Spa & Treatments', 'category': 'Kids', 'price': 25.0, 'icon': Icons.face_retouching_natural, 'desc': 'Healthy, shiny hair naturally', 'image': 'assets/images/beauty/child_hair_spa.png'},
        {'title': 'Skin Care Rituals', 'category': 'Kids', 'price': 25.0, 'icon': Icons.eco, 'desc': 'Gentle care for sensitive skin', 'image': 'assets/images/beauty/child_skin_care.png'},
      ];
    }
    
    // Auto-populate prices map
    for (var item in _treatments) {
      _treatmentPrices[item['title'] as String] = item['price'] as double;
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

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subCategory = widget.bookingData.selectedServiceTitle ?? 'Female';
    
    // Group treatments by category
    final Map<String, List<Map<String, dynamic>>> groupedTreatments = {};
    for (var item in _treatments) {
      final cat = item['category'] as String;
      if (!groupedTreatments.containsKey(cat)) {
        groupedTreatments[cat] = [];
      }
      groupedTreatments[cat]!.add(item);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          QuickServicesHeader(
            currentStep: 1,
            title: 'Select Services',
            subtitle: 'Beauty & Wellness • $subCategory',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  if (subCategory == 'Kids')
                    _buildKidsGrid(isDark)
                  else
                    // Render grouped treatments
                    ...groupedTreatments.entries.map((entry) {
                      final categoryName = entry.key;
                    final categoryItems = entry.value;

                    Color bgColor;
                    Color circleColor;
                    String subtitle;
                    IconData catIcon;

                    if (subCategory == 'Male') {
                      switch (categoryName) {
                        case 'Skin':
                          bgColor = const Color(0xFFE8F4FD);
                          circleColor = const Color(0xFFCDE2F5);
                          subtitle = 'Healthy skin, confident you';
                          catIcon = Icons.face;
                          break;
                        case 'Hair':
                          bgColor = const Color(0xFFFFF6D9);
                          circleColor = const Color(0xFFFFE8A1);
                          subtitle = 'Style it your way';
                          catIcon = Icons.content_cut;
                          break;
                        case 'Makeup':
                          bgColor = const Color(0xFFFFE8EF);
                          circleColor = const Color(0xFFFFD1E3);
                          subtitle = 'Look sharp for every occasion';
                          catIcon = Icons.brush;
                          break;
                        case 'Hand & Feet':
                          bgColor = const Color(0xFFEFE8FE);
                          circleColor = const Color(0xFFDDD0F9);
                          subtitle = 'Well-groomed, always';
                          catIcon = Icons.back_hand;
                          break;
                        default:
                          bgColor = const Color(0xFFF0FDF4);
                          circleColor = const Color(0xFFC8F5D0);
                          subtitle = 'Exceptional care for you';
                          catIcon = Icons.spa;
                          break;
                      }
                    } else {
                      switch (categoryName) {
                        case 'Skin':
                          bgColor = const Color(0xFFFFF0F5);
                          circleColor = const Color(0xFFFFD1E3);
                          subtitle = 'Healthy, glowing skin every day';
                          catIcon = Icons.face_retouching_natural;
                          break;
                        case 'Hair':
                          bgColor = const Color(0xFFF0F8FF);
                          circleColor = const Color(0xFFCDE2F5);
                          subtitle = 'Style your way, every day';
                          catIcon = Icons.face_6;
                          break;
                        case 'Makeup':
                          bgColor = const Color(0xFFF8F0FA);
                          circleColor = const Color(0xFFDDD0F9);
                          subtitle = 'Look and feel your best';
                          catIcon = Icons.brush;
                          break;
                        case 'Hand & Feet':
                          bgColor = const Color(0xFFFFFDE7);
                          circleColor = const Color(0xFFFFE8A1);
                          subtitle = 'Polished to perfection';
                          catIcon = Icons.back_hand;
                          break;
                        default:
                          bgColor = const Color(0xFFF0FDF4);
                          circleColor = const Color(0xFFC8F5D0);
                          subtitle = 'Exceptional care for you';
                          catIcon = Icons.spa;
                          break;
                      }
                    }

                    if (isDark) {
                      bgColor = bgColor.withOpacity(0.1);
                      circleColor = Colors.white12;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: circleColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(catIcon, color: isDark ? Colors.white : Colors.black87, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                children: categoryItems.map((item) {
                                  final title = item['title'] as String;
                                  final price = item['price'] as double;
                                  final iconData = item['icon'] as IconData;
                                  final isSelected = _selectedTreatments.contains(title);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedTreatments.remove(title);
                                          } else {
                                            _selectedTreatments.add(title);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withOpacity(0.85) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isSelected ? Border.all(color: AppColors.primaryGold, width: 1.5) : null,
                                          boxShadow: [
                                            if (!isDark)
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.02),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(iconData, size: 20, color: isDark ? Colors.black87 : Colors.black87),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (isSelected)
                                                  const Padding(
                                                    padding: EdgeInsets.only(right: 8.0),
                                                    child: Icon(Icons.check_circle, color: AppColors.primaryGold, size: 18),
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.grey.shade200 : const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    'From €${price.toStringAsFixed(0)}',
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                      color: isDark ? Colors.black87 : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  }),


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

                  // Materials preference
                  Text(
                    'Products & Materials',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _materialPreference == 'Bring products' ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                        width: _materialPreference == 'Bring products' ? 1.5 : 1,
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
                          child: const Icon(Icons.clean_hands, size: 24, color: AppColors.primaryGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_materialPreference, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                _materialPreference == 'Bring products' ? '+€${QuickServicesPricingConfig.getMaterialCost(widget.bookingData.category).toStringAsFixed(2)} extra charge' : 'No extra charge',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _materialPreference == 'Bring products' ? AppColors.primaryGold : Colors.grey[600],
                                  fontWeight: _materialPreference == 'Bring products' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: _materialPreference == 'Bring products',
                            activeColor: isDark ? AppColors.backgroundDark : Colors.white,
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: (val) {
                              setState(() {
                                _materialPreference = val ? 'Bring products' : 'Use my products';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
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

                  const SizedBox(height: 24),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      if (_isUploading) return;
                      if (_selectedTreatments.isEmpty) {
                        _showErrorSnackBar('Please select at least one treatment service');
                        return;
                      }

                      final selectedList = _selectedTreatments.toList();
                      final updatedData = widget.bookingData.copyWith(
                        beautySelectedTreatments: selectedList,
                        beautyTreatmentsSubtotal: _calculatedSubtotal,
                        peopleCount: _peopleCount,
                        professionalPreference: _professionalPreference,
                        whatYouNeed: _notesController.text.trim(),
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        customBeautyService: _customServiceController.text.trim(),
                        materialPreference: _materialPreference,
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
                          if (mounted) _showErrorSnackBar('Failed to upload images');
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

  Widget _buildKidsGrid(bool isDark) {
    final List<Color> bgColors = [
      const Color(0xFFFFE8EF),
      const Color(0xFFE8F4FD),
      const Color(0xFFE8F9ED),
      const Color(0xFFF1EAFF),
      const Color(0xFFFFF6D9),
      const Color(0xFFFFECE8),
      const Color(0xFFE8F4FD),
      const Color(0xFFE8F9ED),
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88, // Increased to make the cards shorter
      ),
      itemCount: _treatments.length,
      itemBuilder: (context, index) {
        final item = _treatments[index];
        final title = item['title'] as String;
        final desc = item['desc'] as String;
        final price = item['price'] as double;
        final image = item['image'] as String;
        final bgColor = bgColors[index % bgColors.length];
        final isSelected = _selectedTreatments.contains(title);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTreatments.remove(title);
              } else {
                _selectedTreatments.add(title);
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: AppColors.primaryGold, width: 2) : Border.all(color: Colors.transparent, width: 2),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top half with image dictating its own height
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.asset(
                    image,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                // Bottom half with text filling the remaining space
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title == 'Spa Parties' ? '€${price.toStringAsFixed(0)} / child' : 'From €${price.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF5252), // Red price
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
