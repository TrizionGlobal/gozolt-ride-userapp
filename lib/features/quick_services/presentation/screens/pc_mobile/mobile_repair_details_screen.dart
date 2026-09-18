import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class MobileRepairDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const MobileRepairDetailsScreen({super.key, required this.bookingData});

  @override
  State<MobileRepairDetailsScreen> createState() => _MobileRepairDetailsScreenState();
}

class _MobileRepairDetailsScreenState extends State<MobileRepairDetailsScreen> {
  String _materialPreference = 'Bring materials';
  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedOS;
  String? _selectedIssue;
  int _deviceCount = 1;

  final TextEditingController _customBrandController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _deviceTypes = ['Smartphone', 'Tablet', 'Smartwatch', 'Other Device'];
  
  final List<String> _brands = [
    'Samsung',
    'Apple',
    'Xiaomi',
    'Huawei',
    'Google',
    'OnePlus',
    'Sony',
    'Other'
  ];

  static const Map<String, List<String>> _brandModelsMap = {
    'Samsung': [
      'Galaxy S23 Ultra',
      'Galaxy S23',
      'Galaxy S22',
      'Galaxy S21',
      'Galaxy Z Fold 5',
      'Galaxy Z Flip 5',
      'Galaxy A54',
      'Other Model',
    ],
    'Apple': [
      'iPhone 15 Pro Max',
      'iPhone 15 Pro',
      'iPhone 15',
      'iPhone 14 Pro',
      'iPhone 14',
      'iPhone 13',
      'iPhone 12',
      'iPhone SE',
      'Other Model',
    ],
    'Xiaomi': [
      'Xiaomi 13 Pro',
      'Xiaomi 13',
      'Redmi Note 12 Pro',
      'Redmi Note 12',
      'Poco F5',
      'Poco X5 Pro',
      'Other Model',
    ],
    'Huawei': [
      'P60 Pro',
      'Mate 50 Pro',
      'P40 Pro',
      'Nova 11',
      'Other Model',
    ],
    'Google': [
      'Pixel 8 Pro',
      'Pixel 8',
      'Pixel 7a',
      'Pixel 7 Pro',
      'Pixel 7',
      'Pixel 6a',
      'Other Model',
    ],
    'OnePlus': [
      'OnePlus 11',
      'OnePlus 11R',
      'OnePlus 10 Pro',
      'OnePlus Nord 3',
      'OnePlus Nord CE 3',
      'Other Model',
    ],
    'Sony': [
      'Xperia 1 V',
      'Xperia 5 V',
      'Xperia 10 V',
      'Xperia 1 IV',
      'Other Model',
    ],
    'Other': [
      'Other Model',
    ],
  };

  List<String> get _currentModels =>
      _selectedBrand != null ? (_brandModelsMap[_selectedBrand] ?? const ['Other Model']) : const [];

  final List<String> _operatingSystems = ['Android', 'iOS', 'Other'];

  final List<String> _leftIssues = [
    'Screen / Display Damage',
    'Battery Issue',
    'Charging Port',
    "Won't Power On",
    'Camera Issue',
  ];

  final List<String> _rightIssues = [
    'Speaker / Microphone',
    'Water / Liquid Damage',
    'Software Issue',
    'Network / SIM Issue',
    'Other Issue',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
  }

  @override
  void dispose() {
    _customBrandController.dispose();
    _customModelController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentModels = _currentModels;
    if (_selectedBrand != null && _selectedModel != null && !currentModels.contains(_selectedModel)) {
      _selectedModel = currentModels.isNotEmpty ? currentModels.first : null;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 1,
            title: 'Device & Issue Details',
            subtitle: 'Mobile Repair at Home',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Type Section (2 Column Wrap - No Scroll)
                  Text(
                    'Device Type',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _deviceTypes.map((type) {
                      final isSelected = _selectedDeviceType == type;
                      IconData iconData;
                      switch (type) {
                        case 'Tablet':
                          iconData = Icons.tablet_android;
                          break;
                        case 'Smartwatch':
                          iconData = Icons.watch;
                          break;
                        case 'Other Device':
                          iconData = Icons.devices_other;
                          break;
                        case 'Smartphone':
                        default:
                          iconData = Icons.smartphone;
                          break;
                      }
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDeviceType = type),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 40 - 8) / 2,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                iconData,
                                size: 18,
                                color: isSelected ? AppColors.primaryGold : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? (isDark ? AppColors.primaryGold : Colors.black)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Brand Dropdown & Manual Input
                  Text(
                    'Brand',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedBrand,
                    hint: Text('Select Brand', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                    ),
                    items: _brands.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedBrand = val;
                          final models = _brandModelsMap[_selectedBrand] ?? ['Other Model'];
                          _selectedModel = models.first;
                        });
                      }
                    },
                  ),
                  if (_selectedBrand == 'Other') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customBrandController,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Enter Brand Name (e.g. Motorola, Asus, LG)',
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
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Model Dropdown & Manual Input
                  Text(
                    'Model',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    hint: Text('Select Model', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                    ),
                    items: currentModels.map((model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(model, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedModel = val);
                      }
                    },
                  ),
                  if (_selectedModel == 'Other' || _selectedModel == 'Other Model') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customModelController,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Enter Model Name (e.g. Moto G84, ROG Phone)',
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
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Operating System Dropdown
                  Text(
                    'Operating System',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOS,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                    ),
                    items: _operatingSystems.map((os) {
                      return DropdownMenuItem<String>(
                        value: os,
                        child: Text(os, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedOS = val!),
                  ),

                  const SizedBox(height: 24),

                  // Select Issue (2 Column Radio List)
                  Text(
                    'Select Issue',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: _leftIssues.map((issue) => _buildRadioTile(issue)).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: _rightIssues.map((issue) => _buildRadioTile(issue)).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Compact Number of Devices Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Number of Devices',
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _deviceCount > 1
                                ? () => setState(() => _deviceCount--)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: _deviceCount > 1 ? null : Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$_deviceCount',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _deviceCount++),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Reusable Tell Us What You Need, Describe Issue & Image Picker Section
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

                  const SizedBox(height: 24),

                  // Data Privacy Banner (Blue Box)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Back up important data where possible.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Never enter your PIN or password in booking comments.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Workshop Disclaimer Banner (Grey Box)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'If repair cannot be completed at home, workshop collection requires your approval.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      final finalBrand = (_selectedBrand == 'Other' && _customBrandController.text.trim().isNotEmpty)
                          ? _customBrandController.text.trim()
                          : _selectedBrand;

                      final finalModel = ((_selectedModel == 'Other' || _selectedModel == 'Other Model') && _customModelController.text.trim().isNotEmpty)
                          ? _customModelController.text.trim()
                          : _selectedModel;

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Mobile Repair at Home',
                        deviceType: _selectedDeviceType,
                        deviceBrand: finalBrand,
                        deviceModel: finalModel,
                        operatingSystem: _selectedOS,
                        mobileIssue: _selectedIssue,
                        deviceCount: _deviceCount,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty
                            ? _whatYouNeedController.text.trim()
                            : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty
                            ? _describeIssueController.text.trim()
                            : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                      );

                      context.pushNamed(
                        RouteNames.quickServicesMobileRepairReview,
                        extra: updatedData,
                      );
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

  Widget _buildRadioTile(String issue) {
    final isSelected = _selectedIssue == issue;
    return GestureDetector(
      onTap: () => setState(() => _selectedIssue = issue),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? AppColors.primaryGold : Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                issue,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
