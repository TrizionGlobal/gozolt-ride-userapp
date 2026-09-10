import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';
import '../widgets/quick_services_additional_details.dart';

class PrinterScannerDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const PrinterScannerDetailsScreen({super.key, required this.bookingData});

  @override
  State<PrinterScannerDetailsScreen> createState() => _PrinterScannerDetailsScreenState();
}

class _PrinterScannerDetailsScreenState extends State<PrinterScannerDetailsScreen> {
  String? _selectedDeviceType;
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  
  final Set<String> _selectedIssues = {};
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _problemDescriptionController = TextEditingController();
  
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _deviceTypes = [
    {'name': 'Printer', 'icon': Icons.print},
    {'name': 'Scanner', 'icon': Icons.scanner},
    {'name': 'All-in-One Printer', 'icon': Icons.print},
    {'name': 'Photo Printer', 'icon': Icons.camera_alt},
    {'name': 'Label Printer', 'icon': Icons.label},
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
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _whatYouNeedController.dispose();
    _problemDescriptionController.dispose();
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Service Requirements',
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: isDark ? Colors.grey[900] : const Color(0xFFFFF8E1),
            child: Text(
              'Printer & Scanner Service',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.primaryGold : const Color(0xFFF57F17),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Select Device Type
                  Text('1. Select Device Type', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
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
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      device['name'],
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 11,
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Brand', style: AppTextStyles.bodySmall),
                            const SizedBox(height: 4),
                            _buildTextField(_brandController, ''),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Model', style: AppTextStyles.bodySmall),
                            const SizedBox(height: 4),
                            _buildTextField(_modelController, ''),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Device Number /\nSerial Number', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                            const SizedBox(height: 4),
                            _buildTextField(_serialNumberController, ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Select Issue
                  Row(
                    children: [
                      Text('3. Select Issue', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('(You can select more than one)', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _issues.map((issue) {
                      final isSelected = _selectedIssues.contains(issue);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIssues.remove(issue);
                            } else {
                              _selectedIssues.add(issue);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                issue,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isSelected ? Colors.black : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 14, color: Colors.black),
                              ]
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Final price and replacement parts will be confirmed after inspection.',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.brown[800], fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CONTINUE
                  ElevatedButton(
                    onPressed: () {
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Printer & Scanner Service',
                        printerDeviceType: _selectedDeviceType,
                        printerBrand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
                        printerModel: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
                        printerSerialNumber: _serialNumberController.text.trim().isNotEmpty ? _serialNumberController.text.trim() : null,
                        printerIssues: _selectedIssues.toList(),
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _problemDescriptionController.text.trim().isNotEmpty ? _problemDescriptionController.text.trim() : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        subtotal: 12.00, // Inspection fee basis
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
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
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
}
