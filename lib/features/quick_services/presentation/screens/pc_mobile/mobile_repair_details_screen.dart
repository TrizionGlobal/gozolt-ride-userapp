import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class MobileRepairDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const MobileRepairDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<MobileRepairDetailsScreen> createState() => _MobileRepairDetailsScreenState();
}

class _MobileRepairDetailsScreenState extends ConsumerState<MobileRepairDetailsScreen> {
  bool _isUploading = false;
  String _materialPreference = 'Bring tools';
  String? _selectedIssue;
  
  final List<MobileDevice> _savedDevices = [];

  void _addDevice() {
    final finalDeviceType = _selectedDeviceType == 'Other Device' ? _customDeviceTypeController.text.trim() : _selectedDeviceType;
    final finalBrand = _selectedBrand == 'Other' ? _customBrandController.text.trim() : _selectedBrand;
    final finalModel = _selectedModel == 'Other Model' ? _customModelController.text.trim() : _selectedModel;

    if (finalDeviceType == null || finalDeviceType.isEmpty ||
        finalBrand == null || finalBrand.isEmpty ||
        finalModel == null || finalModel.isEmpty ||
        _selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter device type, brand, model, and an issue.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _savedDevices.add(MobileDevice(
        deviceType: finalDeviceType,
        deviceBrand: finalBrand,
        deviceModel: finalModel,
        issue: _selectedIssue!,
      ));

      // Reset form
      _selectedDeviceType = null;
      _selectedBrand = null;
      _selectedModel = null;
      _selectedIssue = null;
      
      _customDeviceTypeController.clear();
      _customBrandController.clear();
      _customModelController.clear();

      FocusScope.of(context).unfocus();
    });
  }

  void _removeDevice(int index) {
    setState(() {
      _savedDevices.removeAt(index);
    });
  }

  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  
  final TextEditingController _customDeviceTypeController = TextEditingController();
  final TextEditingController _customBrandController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  
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

  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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
    _customDeviceTypeController.dispose();
    _customBrandController.dispose();
    _customModelController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    super.dispose();
  }

  Widget _buildCustomTextField(TextEditingController controller, String hint) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.bodyMedium,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: hint,
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
    );
  }

  Widget _buildDeviceDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            '$label:',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 1,
            title: 'Service Requirements',
            subtitle: 'Mobile Repair',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DEVICE FORM ---
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
                          'Add a Device',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Device Type Section (2 Column Wrap - No Scroll)
                        Text(
                          'Device Type',
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
                            childAspectRatio: 2.0,
                          ),
                          itemCount: _deviceTypes.length,
                          itemBuilder: (context, index) {
                            final type = _deviceTypes[index];
                            final isSelected = _selectedDeviceType == type;
                            IconData iconData;
                            switch (type) {
                              case 'Smartphone':
                                iconData = Icons.smartphone;
                                break;
                              case 'Tablet':
                                iconData = Icons.tablet_mac;
                                break;
                              case 'Smartwatch':
                                iconData = Icons.watch;
                                break;
                              default:
                                iconData = Icons.devices;
                            }
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDeviceType = type),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.15) : Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            iconData,
                                            color: isSelected ? AppColors.primaryGold : const Color(0xFF324461),
                                            size: 28,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            type,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: isDark ? Colors.white : Colors.black87,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Icon(Icons.check_circle, color: AppColors.primaryGold, size: 16),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_selectedDeviceType == 'Other Device')
                          _buildCustomTextField(_customDeviceTypeController, 'Enter custom device type'),
                        const SizedBox(height: 24),
                        
                        // Brand Dropdown & Manual Input
                        Text(
                          'Brand',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
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
                            setState(() {
                              _selectedBrand = val;
                              _selectedModel = null;
                            });
                          },
                        ),
                        if (_selectedBrand == 'Other')
                          _buildCustomTextField(_customBrandController, 'Enter Brand Name (e.g. Asus, Nothing)'),
                        
                        const SizedBox(height: 16),
                        
                        // Model Dropdown & Manual Input
                        Text(
                          'Model',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
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
                            fillColor: _selectedBrand == null ? Colors.grey.withOpacity(0.1) : Theme.of(context).cardTheme.color,
                          ),
                          items: _currentModels.map((model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: _selectedBrand == null
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedModel = val;
                                  });
                                },
                        ),
                        if (_selectedModel == 'Other Model')
                          _buildCustomTextField(_customModelController, 'Enter Model Name (e.g. Zenfone 10)'),
                        const SizedBox(height: 24),
                        // Select Issue
                        Text(
                          'Select Issue',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _addDevice,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primaryGold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Add Device', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LIST OF ADDED DEVICES ---
                  if (_savedDevices.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Mobile Devices (${_savedDevices.length})',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _savedDevices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final device = _savedDevices[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDeviceDetailRow('Type', device.deviceType),
                                    const SizedBox(height: 4),
                                    _buildDeviceDetailRow('Device', '${device.deviceBrand} ${device.deviceModel}'),
                                    if (device.operatingSystem != null && device.operatingSystem!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      _buildDeviceDetailRow('OS', device.operatingSystem!),
                                    ],
                                    const SizedBox(height: 4),
                                    _buildDeviceDetailRow('Issue', device.issue),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeDevice(index),
                                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Required Tools Section
                  Text(
                    'Required Tools',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
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
                          color: _materialPreference == 'Bring tools' ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                          width: _materialPreference == 'Bring tools' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.1),
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
                                  _materialPreference == 'Bring tools'
                                      ? '+\u20ac${QuickServicesPricingConfig.getMaterialCost(widget.bookingData.category).toStringAsFixed(2)} extra charge'
                                      : 'Use my tools (No extra charge)',
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
                                  _materialPreference = val ? 'Bring tools' : 'Use my tools';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
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


                  const SizedBox(height: 32),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      if (_isUploading) return;
                      if (_savedDevices.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add at least one device before continuing.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Mobile Repair',
                        mobileDevices: _savedDevices,
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

                      if (_selectedImages.isNotEmpty) {
                        setState(() => _isUploading = true);
                        ref.read(quickServicesBookingProvider.notifier).uploadImages(
                          _selectedImages.map((e) => e.path).toList()
                        ).then((remoteUrls) {
                          if (mounted) setState(() => _isUploading = false);
                          var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
                          if (mounted) context.pushNamed(RouteNames.quickServicesMobileRepairReview, extra: finalDataObj);
                        }).catchError((e) {
                          if (mounted) setState(() => _isUploading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                        });
                      } else {
                        if (mounted) context.pushNamed(RouteNames.quickServicesMobileRepairReview, extra: updatedData);
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
                  const SizedBox(height: 40),
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
