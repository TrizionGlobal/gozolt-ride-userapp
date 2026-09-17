import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class ComputerRepairDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const ComputerRepairDetailsScreen({super.key, required this.bookingData});

  @override
  State<ComputerRepairDetailsScreen> createState() => _ComputerRepairDetailsScreenState();
}

class _ComputerRepairDetailsScreenState extends State<ComputerRepairDetailsScreen> {
  String _materialPreference = 'Bring materials';
  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedOS;
  String? _selectedIssue;

  final TextEditingController _customBrandController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _deviceTypes = [
    'Laptop',
    'Desktop',
    'All-in-One',
    'Gaming PC',
    'Mac',
    'Other Device',
  ];

  final List<String> _brands = [
    'Dell',
    'HP',
    'Lenovo',
    'Apple',
    'Asus',
    'Acer',
    'MSI',
    'Other',
  ];

  static const Map<String, List<String>> _brandModelsMap = {
    'Dell': [
      'Inspiron 15',
      'XPS 13',
      'XPS 15',
      'Latitude 5420',
      'Alienware m15',
      'Vostro 3510',
      'Other Model',
    ],
    'HP': [
      'Pavilion 15',
      'Spectre x360',
      'Envy 13',
      'Omen 16',
      'ProBook 450',
      'Other Model',
    ],
    'Lenovo': [
      'ThinkPad X1 Carbon',
      'IdeaPad Slim 3',
      'Legion 5',
      'Yoga Slim 7',
      'ThinkBook 15',
      'Other Model',
    ],
    'Apple': [
      'MacBook Pro 14',
      'MacBook Pro 16',
      'MacBook Air M2',
      'iMac 24',
      'Mac mini',
      'Mac Studio',
      'Other Model',
    ],
    'Asus': [
      'ROG Strix G16',
      'TUF Gaming F15',
      'ZenBook 14',
      'VivoBook 15',
      'ROG Zephyrus G14',
      'Other Model',
    ],
    'Acer': [
      'Aspire 5',
      'Nitro 5',
      'Predator Helios 300',
      'Swift 3',
      'Other Model',
    ],
    'MSI': [
      'Katana GF66',
      'Stealth 15M',
      'Raider GE76',
      'Modern 14',
      'Other Model',
    ],
    'Other': [
      'Other Model',
    ],
  };

  List<String> get _currentModels =>
      _selectedBrand != null ? (_brandModelsMap[_selectedBrand] ?? const ['Other Model']) : const [];

  final List<String> _operatingSystems = [
    'Windows',
    'macOS',
    'Linux',
    'Not Sure',
    'Other',
  ];

  final List<String> _leftIssues = [
    "Won't Power On",
    'Keyboard / Touchpad',
    'Software / OS Issue',
    'Slow / Freezing',
    'Screen / Display Issue',
  ];

  final List<String> _rightIssues = [
    'Battery / Charging',
    'Overheating',
    'Virus / Malware',
    'Data Recovery',
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
            title: 'Service Requirements',
            subtitle: 'Computer & Laptop Repair',
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
                        case 'Desktop':
                        case 'Gaming PC':
                          iconData = Icons.desktop_windows;
                          break;
                        case 'All-in-One':
                          iconData = Icons.computer;
                          break;
                        case 'Mac':
                          iconData = Icons.laptop_mac;
                          break;
                        case 'Other Device':
                          iconData = Icons.devices_other;
                          break;
                        case 'Laptop':
                        default:
                          iconData = Icons.laptop;
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
                        hintText: 'Enter Brand Name (e.g. Razer, Alienware, Toshiba)',
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

                  // Dynamic Model Dropdown based on selected Brand
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
                        hintText: 'Enter Model Name (e.g. XPS 13, Legion 5)',
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

                  // Operating System Chips
                  Text(
                    'Operating System',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _operatingSystems.map((os) {
                        final isSelected = _selectedOS == os;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedOS = os),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.blue.shade900 : const Color(0xFFE3F2FD))
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              os,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blue.shade800 : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // What is the issue? (2 Column Radio List)
                  Text(
                    'What is the issue?',
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
                                'Never enter passwords in booking comments.',
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
                        selectedServiceTitle: 'Computer & Laptop Repair',
                        computerDeviceType: _selectedDeviceType,
                        computerBrand: finalBrand,
                        computerModel: finalModel,
                        computerOS: _selectedOS,
                        computerIssue: _selectedIssue,
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
                        RouteNames.quickServicesComputerRepairReview,
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
