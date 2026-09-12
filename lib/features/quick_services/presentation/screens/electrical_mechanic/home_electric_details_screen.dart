import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class HomeElectricDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const HomeElectricDetailsScreen({super.key, required this.bookingData});

  @override
  State<HomeElectricDetailsScreen> createState() => _HomeElectricDetailsScreenState();
}

class _HomeElectricDetailsScreenState extends State<HomeElectricDetailsScreen> {
  final Map<String, int> _counts = {
    'Switch / Socket Repair': 0,
    'Light Installation / Repair': 0,
    'Ceiling Fan Installation / Repair': 0,
    'Circuit Breaker / Tripping': 0,
    'Electrical Wiring Issue': 0,
    'Doorbell Installation / Repair': 0,
    'Appliance Electrical Connection': 0,
    'CCTV Installation / Repair': 0,
    'Other Electrical Issue': 0,
  };

  final Map<String, IconData> _icons = {
    'Switch / Socket Repair': Icons.power_outlined,
    'Light Installation / Repair': Icons.lightbulb_outline,
    'Ceiling Fan Installation / Repair': Icons.mode_fan_off_outlined,
    'Circuit Breaker / Tripping': Icons.electric_meter_outlined,
    'Electrical Wiring Issue': Icons.cable_outlined,
    'Doorbell Installation / Repair': Icons.notifications_outlined,
    'Appliance Electrical Connection': Icons.electrical_services_outlined,
    'CCTV Installation / Repair': Icons.videocam_outlined,
    'Other Electrical Issue': Icons.build_outlined,
  };

  final Map<String, double> _hours = {
    'Switch / Socket Repair': 0.5,
    'Light Installation / Repair': 0.5,
    'Ceiling Fan Installation / Repair': 1.0,
    'Circuit Breaker / Tripping': 1.5,
    'Electrical Wiring Issue': 2.0,
    'Doorbell Installation / Repair': 0.5,
    'Appliance Electrical Connection': 1.0,
    'CCTV Installation / Repair': 2.0,
    'Other Electrical Issue': 1.0,
  };


  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

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

  void _increment(String key) {
    setState(() {
      _counts[key] = (_counts[key] ?? 0) + 1;
    });
  }

  void _decrement(String key) {
    setState(() {
      if ((_counts[key] ?? 0) > 0) {
        _counts[key] = (_counts[key] ?? 0) - 1;
      }
    });
  }

  void _onContinue() {
    final selectedKeys = _counts.keys.where((k) => (_counts[k] ?? 0) > 0).toList();

    List<ServiceAddon> selectedAddons = selectedKeys.map((key) {
      return ServiceAddon(name: key, count: _counts[key]!, hoursPerUnit: _hours[key]!);
    }).toList();

    double calculatedSubtotal = selectedAddons.fold(0.0, (sum, item) => sum + item.totalPrice);
    if (calculatedSubtotal == 0) {
      calculatedSubtotal = 15.0; // Base visit fee
    }

    final updatedData = widget.bookingData.copyWith(
      selectedServiceTitle: widget.bookingData.selectedServiceTitle ?? 'Electrical Services',
      selectedAddons: selectedAddons,
      whatYouNeed: _whatYouNeedController.text.trim(),
      describeIssue: _describeIssueController.text.trim(),
      uploadedImages: _selectedImages.map((img) => img.path).toList(),
      subtotal: 0.0,
                        baseEstimatedHours: 0.0,
    );

    context.pushNamed(RouteNames.quickServicesElectricalReview, extra: updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Service Requirements',
          ),
          Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'What electrical work is needed?',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: _counts.keys.map((key) {
                          final isLast = key == _counts.keys.last;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(_icons[key], size: 22, color: Colors.grey.shade600),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        key,
                                        style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _decrement(key),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Icon(Icons.remove, size: 16),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            '${_counts[key]}',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _increment(key),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Icon(Icons.add, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.grey.withOpacity(0.2),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Additional Details',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD84315), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Fire, smoke or active sparking?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD84315),
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Switch off main power if safe and call 112.',
                                  style: TextStyle(
                                    color: Color(0xFF5D4037),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                    child: Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
