import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';
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
  String _materialPreference = 'Bring tools';
  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedIssue;

  final List<ComputerDevice> _savedComputers = [];

  final TextEditingController _customDeviceTypeController = TextEditingController();
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


  void _addComputer() {
    final finalDeviceType = _selectedDeviceType == 'Other Device'
        ? _customDeviceTypeController.text.trim()
        : _selectedDeviceType;
        
    if (finalDeviceType == null || finalDeviceType.isEmpty) {
      _showError('Please select or enter a device type');
      return;
    }

    final finalBrand = _selectedBrand == 'Other'
        ? _customBrandController.text.trim()
        : _selectedBrand;

    if (finalBrand == null || finalBrand.isEmpty) {
      _showError('Please select or enter a brand');
      return;
    }

    final finalModel = (_selectedModel == 'Other' || _selectedModel == 'Other Model')
        ? _customModelController.text.trim()
        : _selectedModel;

    if (finalModel == null || finalModel.isEmpty) {
      _showError('Please select or enter a model');
      return;
    }

    if (_selectedIssue == null) {
      _showError('Please select an issue');
      return;
    }

    setState(() {
      _savedComputers.add(
        ComputerDevice(
          deviceType: _selectedDeviceType!,
          brand: finalBrand,
          model: finalModel,
          issue: _selectedIssue!,
        ),
      );
      
      // Reset form
      _selectedDeviceType = null;
      _selectedBrand = null;
      _selectedModel = null;
      _selectedIssue = null;
      _customDeviceTypeController.clear();
      _customBrandController.clear();
      _customModelController.clear();
    });
    
    FocusScope.of(context).unfocus();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                  // --- COMPUTER FORM ---
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
                          'Add a Computer/Laptop',
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
                        case 'Desktop':
                          iconData = Icons.desktop_windows;
                          break;
                        case 'Gaming PC':
                          iconData = Icons.sports_esports;
                          break;
                        case 'All-in-One':
                          iconData = Icons.tablet_mac;
                          break;
                        case 'Mac':
                          iconData = Icons.apple;
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
                  if (_selectedDeviceType == 'Other Device') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customDeviceTypeController,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Enter Custom Device Type',
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _addComputer,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primaryGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add Computer', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            // --- LIST OF ADDED COMPUTERS ---
            if (_savedComputers.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Computers & Laptops (${_savedComputers.length})',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedComputers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final computer = _savedComputers[index];
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
                              Text(
                                '${computer.brand} ${computer.model}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${computer.deviceType}',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                              ),
                              if (computer.operatingSystem != null && computer.operatingSystem!.isNotEmpty)
                                Text(
                                  'OS: ${computer.operatingSystem}',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                ),
                              Text(
                                'Issue: ${computer.issue}',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _savedComputers.removeAt(index);
                            });
                          },
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
                      if (_savedComputers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add at least one computer before continuing.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Computer & Laptop Repair',
                        computerDevices: _savedComputers,
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
