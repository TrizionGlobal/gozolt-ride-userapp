import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';
import '../widgets/quick_services_additional_details.dart';

class SuppliersDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const SuppliersDetailsScreen({super.key, required this.bookingData});

  @override
  State<SuppliersDetailsScreen> createState() => _SuppliersDetailsScreenState();
}

class _SuppliersDetailsScreenState extends State<SuppliersDetailsScreen> {
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  String? _supplyType;
  String? _supplyScale;

  final List<String> _supplyTypes = ['Food & Beverage', 'Decorations', 'Audio/Visual', 'Furniture', 'Other'];
  final List<String> _supplyScales = ['Small (1-50 items)', 'Medium (50-200 items)', 'Large (200+ items)'];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
    if (widget.bookingData.supplyType != null) {
      _supplyType = widget.bookingData.supplyType;
    }
    if (widget.bookingData.supplyScale != null) {
      _supplyScale = widget.bookingData.supplyScale;
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Supply Details', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _supplyType,
                      hint: Text('Type of Supply', style: AppTextStyles.bodyMedium),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _supplyTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.bodyMedium));
                      }).toList(),
                      onChanged: (value) => setState(() => _supplyType = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _supplyScale,
                      hint: Text('Scale / Quantity', style: AppTextStyles.bodyMedium),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _supplyScales.map((scale) {
                        return DropdownMenuItem(value: scale, child: Text(scale, style: AppTextStyles.bodyMedium));
                      }).toList(),
                      onChanged: (value) => setState(() => _supplyScale = value),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        final updatedData = widget.bookingData.copyWith(
                          selectedServiceTitle: 'Suppliers',
                          supplyType: _supplyType,
                          supplyScale: _supplyScale,
                          whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                          describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                          uploadedImages: _selectedImages.map((e) => e.path).toList(),
                          subtotal: 50.0, // Base estimated subtotal
                        );

                        context.pushNamed(
                          RouteNames.quickServicesOtherServicesReview,
                          extra: updatedData,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
