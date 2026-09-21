import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class PrinterScannerDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const PrinterScannerDetailsScreen({super.key, required this.bookingData});

  @override
  State<PrinterScannerDetailsScreen> createState() => _PrinterScannerDetailsScreenState();
}

class _PrinterScannerDetailsScreenState extends State<PrinterScannerDetailsScreen> {
  String _materialPreference = 'Bring tools';
  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  
  final List<PrinterDevice> _savedPrinters = [];
  final TextEditingController _customBrandController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  
  String? _selectedIssue;
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _problemDescriptionController = TextEditingController();
  
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _deviceTypes = [
    {'name': 'Printer / All-In-One Printer', 'icon': Icons.print},
    {'name': 'Scanner', 'icon': Icons.scanner},
    {'name': 'Photo Printer', 'icon': Icons.photo},
    {'name': 'Label Printer', 'icon': Icons.receipt_long},
  ];


  final List<String> _issues = [
    'Not Printing',
    'Paper Jam',
    'Poor Print Quality',
    'Not Scanning',
    'Connection Issue',
    'Error Message',
    'Ink / Toner Issue',
    'Driver / Setup Issue',
    "Won't Power On",
    'Other Issue',
  ];

  final List<String> _brands = [
    'HP',
    'Canon',
    'Epson',
    'Brother',
    'Lexmark',
    'Xerox',
    'Ricoh',
    'Kyocera',
    'Other',
  ];

  static const Map<String, List<String>> _brandModelsMap = {
    'HP': ['LaserJet Pro', 'DeskJet', 'Envy', 'OfficeJet Pro', 'Other Model'],
    'Canon': ['PIXMA', 'MAXIFY', 'i-SENSYS', 'imageRUNNER', 'Other Model'],
    'Epson': ['EcoTank', 'WorkForce', 'Expression Home', 'Other Model'],
    'Brother': ['HL Series', 'MFC Series', 'DCP Series', 'Other Model'],
    'Lexmark': ['GO Line', 'MB Series', 'CX Series', 'Other Model'],
    'Xerox': ['Phaser', 'VersaLink', 'AltaLink', 'Other Model'],
    'Ricoh': ['SP Series', 'IM Series', 'Other Model'],
    'Kyocera': ['ECOSYS', 'TASKalfa', 'Other Model'],
    'Other': ['Other Model'],
  };

  List<String> get _currentModels =>
      _selectedBrand != null ? (_brandModelsMap[_selectedBrand] ?? const ['Other Model']) : const [];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _problemDescriptionController.text = widget.bookingData.describeIssue!;
    }
  }

  @override
  void dispose() {
    _customBrandController.dispose();
    _customModelController.dispose();
    _serialNumberController.dispose();
    _whatYouNeedController.dispose();
    _problemDescriptionController.dispose();
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

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _addPrinter() {
    if (_selectedDeviceType == null) {
      _showError('Please select a device type');
      return;
    }
    
    final brand = _selectedBrand == 'Other' ? _customBrandController.text.trim() : _selectedBrand;
    if (brand == null || brand.isEmpty) {
      _showError('Please select or enter the brand');
      return;
    }

    final model = _selectedModel == 'Other Model' ? _customModelController.text.trim() : _selectedModel;
    if (model == null || model.isEmpty) {
      _showError('Please select or enter the model');
      return;
    }

    if (_selectedIssue == null) {
      _showError('Please select an issue');
      return;
    }

    setState(() {
      _savedPrinters.add(
        PrinterDevice(
          deviceType: _selectedDeviceType!,
          brand: brand,
          model: model,
          serialNumber: _serialNumberController.text.trim().isNotEmpty ? _serialNumberController.text.trim() : null,
          issues: [_selectedIssue!],
        ),
      );

      // Reset form
      _selectedDeviceType = null;
      _selectedBrand = null;
      _selectedModel = null;
      _customBrandController.clear();
      _customModelController.clear();
      _serialNumberController.clear();
      _selectedIssue = null;
    });

    FocusScope.of(context).unfocus();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            subtitle: 'Printer & Scanner Repair',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PRINTER FORM ---
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
                          'Add a Printer/Scanner',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // 1. Select Device Type
                        Text('1. Select Device Type', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
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
                      final device = _deviceTypes[index];
                      final isSelected = _selectedDeviceType == device['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDeviceType = device['name']),
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
                                      device['icon'],
                                      color: isSelected ? AppColors.primaryGold : const Color(0xFF324461),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      device['name'],
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
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.check_circle, color: AppColors.primaryGold, size: 16),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. Device Information
                  Text('2. Device Information', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  Text('Brand', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700])),
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
                    items: _brands.map((b) {
                      return DropdownMenuItem(value: b, child: Text(b, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBrand = val;
                        _selectedModel = null;
                      });
                    },
                  ),
                  if (_selectedBrand == 'Other')
                    _buildCustomTextField(_customBrandController, 'Enter Brand Name (e.g. Epson, Brother)'),

                  const SizedBox(height: 16),

                  Text('Model', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700])),
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
                      fillColor: _selectedBrand == null ? Colors.grey.withOpacity(0.1) : Theme.of(context).cardTheme.color,
                    ),
                    items: _currentModels.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: _selectedBrand == null ? null : (val) {
                      setState(() => _selectedModel = val);
                    },
                  ),
                  if (_selectedModel == 'Other Model')
                    _buildCustomTextField(_customModelController, 'Enter model'),

                  const SizedBox(height: 16),

                  Text('Serial Number (Optional)', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  _buildTextField(_serialNumberController, 'Enter serial number'),

                  const SizedBox(height: 24),

                  // 3. Select Issue
                  Text('3. Select Issue', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
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
                      onPressed: _addPrinter,
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

            // --- LIST OF ADDED PRINTERS ---
            if (_savedPrinters.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Printers & Scanners (${_savedPrinters.length})',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedPrinters.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final printer = _savedPrinters[index];
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
                                '${printer.brand} ${printer.model}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${printer.deviceType}',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                              ),
                              if (printer.serialNumber != null && printer.serialNumber!.isNotEmpty)
                                Text(
                                  'S/N: ${printer.serialNumber}',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                ),
                              Text(
                                'Issues: ${printer.issues.join(", ")}',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _savedPrinters.removeAt(index);
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
                    describeIssueController: _problemDescriptionController,
                    images: _selectedImages,
                    onAddImages: _pickImages,
                    onRemoveImage: (image) {
                      setState(() {
                        _selectedImages.remove(image);
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // Info Banners
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Never enter Wi-Fi, computer or administrator passwords in booking comments.',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.blue[800], fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CONTINUE
                  ElevatedButton(
                    onPressed: () {
                      if (_savedPrinters.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add at least one device before continuing.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Printer & Scanner Repair',
                        printerDevices: _savedPrinters,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _problemDescriptionController.text.trim().isNotEmpty ? _problemDescriptionController.text.trim() : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                      );

                      context.pushNamed(
                        RouteNames.quickServicesPrinterScannerReview,
                        extra: updatedData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall.copyWith(color: Colors.grey, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: AppColors.primaryGold),
          ),
        ),
      ),
    );
  }

  List<String> get _leftIssues => _issues.sublist(0, (_issues.length / 2).ceil());
  List<String> get _rightIssues => _issues.sublist((_issues.length / 2).ceil());

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
