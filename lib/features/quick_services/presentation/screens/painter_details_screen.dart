import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';
import '../widgets/quick_services_additional_details.dart';

class PainterDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const PainterDetailsScreen({super.key, required this.bookingData});

  @override
  State<PainterDetailsScreen> createState() => _PainterDetailsScreenState();
}

class _PainterDetailsScreenState extends State<PainterDetailsScreen> {
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  String? _paintingType;
  int _roomCount = 1;
  bool _paintProvided = false;

  final List<String> _paintingTypes = ['Interior', 'Exterior', 'Both'];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
    if (widget.bookingData.paintingType != null) {
      _paintingType = widget.bookingData.paintingType;
    }
    if (widget.bookingData.roomCount != null) {
      _roomCount = widget.bookingData.roomCount!;
    }
    if (widget.bookingData.paintProvided != null) {
      _paintProvided = widget.bookingData.paintProvided!;
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

  Widget _buildCounter() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Number of Rooms', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryGold),
                onPressed: () {
                  if (_roomCount > 1) {
                    setState(() => _roomCount--);
                  }
                },
              ),
              Text('$_roomCount', style: AppTextStyles.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGold),
                onPressed: () {
                  setState(() => _roomCount++);
                },
              ),
            ],
          ),
        ],
      ),
    );
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
                    Text('Painting Details', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paintingType,
                      hint: Text('Type of Painting', style: AppTextStyles.bodyMedium),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _paintingTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.bodyMedium));
                      }).toList(),
                      onChanged: (value) => setState(() => _paintingType = value),
                    ),
                    const SizedBox(height: 16),
                    _buildCounter(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('I will provide the paint', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch.adaptive(
                              value: _paintProvided,
                              onChanged: (bool value) {
                                setState(() {
                                  _paintProvided = value;
                                });
                              },
                              activeTrackColor: AppColors.primaryGold,
                              inactiveTrackColor: Theme.of(context).dividerTheme.color,
                            ),
                          ),
                        ],
                      ),
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
                          selectedServiceTitle: 'Painter',
                          paintingType: _paintingType,
                          roomCount: _roomCount,
                          paintProvided: _paintProvided,
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
