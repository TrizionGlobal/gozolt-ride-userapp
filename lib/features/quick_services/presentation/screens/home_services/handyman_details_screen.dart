import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class HandymanDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const HandymanDetailsScreen({super.key, required this.bookingData});

  @override
  State<HandymanDetailsScreen> createState() => _HandymanDetailsScreenState();
}

class _HandymanDetailsScreenState extends State<HandymanDetailsScreen> {
  final Map<String, int> _counts = {
    'TV / Wall Mounting': 0,
    'Shelf Installation': 0,
    'Picture / Mirror Hanging': 0,
    'Curtain / Blind Installation': 0,
    'Furniture Assembly': 0,
    'Door Handle / Minor Repair': 0,
    'Silicone / Sealant Work': 0,
    'Drilling / Minor Fixing': 0,
    'Other Handyman Work': 0,
  };

  final Map<String, IconData> _icons = {
    'TV / Wall Mounting': Icons.tv,
    'Shelf Installation': Icons.shelves,
    'Picture / Mirror Hanging': Icons.crop_original,
    'Curtain / Blind Installation': Icons.curtains,
    'Furniture Assembly': Icons.chair_outlined,
    'Door Handle / Minor Repair': Icons.door_front_door_outlined,
    'Silicone / Sealant Work': Icons.format_paint_outlined,
    'Drilling / Minor Fixing': Icons.handyman_outlined,
    'Other Handyman Work': Icons.build_outlined,
  };

  final Map<String, double> _hours = {
    'TV / Wall Mounting': 1.5,
    'Shelf Installation': 0.5,
    'Picture / Mirror Hanging': 0.5,
    'Curtain / Blind Installation': 1.0,
    'Furniture Assembly': 1.5,
    'Door Handle / Minor Repair': 0.5,
    'Silicone / Sealant Work': 1.0,
    'Drilling / Minor Fixing': 0.5,
    'Other Handyman Work': 1.0,
  };


  final List<String> _wallTypes = ['Brick', 'Concrete', 'Drywall', 'Not Sure'];
  String? _selectedWallType;

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
    if (widget.bookingData.wallType != null) {
      _selectedWallType = widget.bookingData.wallType;
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
      selectedServiceTitle: widget.bookingData.selectedServiceTitle ?? 'Handyman Services',
      selectedAddons: selectedAddons,
      wallType: _selectedWallType,
      whatYouNeed: _whatYouNeedController.text.trim(),
      describeIssue: _describeIssueController.text.trim(),
      uploadedImages: _selectedImages.map((img) => img.path).toList(),
      subtotal: 0.0,
                        baseEstimatedHours: 0.0,
    );

    context.pushNamed(RouteNames.quickServicesHandymanReview, extra: updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Service Requirements',
            subtitle: 'Handyman',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What work do you need?',
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

                  // Wall Type Selection Section
                  Text(
                    'Wall Type — Optional',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF324461),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _wallTypes.map((type) {
                      final isSelected = _selectedWallType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedWallType = selected ? type : null;
                          });
                        },
                        selectedColor: AppColors.primaryGold,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryGold : Colors.grey.shade400,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
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

                  // Specialist Warning Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC5CAE9)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF3F51B5), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Electrical, plumbing, gas or structural work must be booked with the appropriate specialist.',
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontSize: 12,
                            ),
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
