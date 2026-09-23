import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class EventOrganisersDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const EventOrganisersDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<EventOrganisersDetailsScreen> createState() => _EventOrganisersDetailsScreenState();
}

class _EventOrganisersDetailsScreenState extends ConsumerState<EventOrganisersDetailsScreen> {
  bool _isUploading = false;
  String _materialPreference = 'Bring materials';
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  String? _eventType;
  String? _eventDuration;

  final List<String> _eventTypes = ['Wedding', 'Birthday', 'Corporate', 'Other'];
  final List<String> _eventDurations = ['Half Day', 'Full Day', 'Multiple Days'];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
    if (widget.bookingData.eventType != null) {
      _eventType = widget.bookingData.eventType;
    }
    if (widget.bookingData.guestCount != null) {
      _guestCountController.text = widget.bookingData.guestCount!.toString();
    }
    if (widget.bookingData.eventDuration != null) {
      _eventDuration = widget.bookingData.eventDuration;
    }
  }

  @override
  void dispose() {
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    _guestCountController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 1,
              title: 'Service Requirements',
            subtitle: 'Event Organisers',
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Event Details', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _eventType,
                      hint: Text('Event Type', style: AppTextStyles.bodyMedium),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.bodyMedium));
                      }).toList(),
                      onChanged: (value) => setState(() => _eventType = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _guestCountController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Estimated Number of Guests',
                        labelStyle: AppTextStyles.bodyMedium,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _eventDuration,
                      hint: Text('Event Duration', style: AppTextStyles.bodyMedium),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _eventDurations.map((duration) {
                        return DropdownMenuItem(value: duration, child: Text(duration, style: AppTextStyles.bodyMedium));
                      }).toList(),
                      onChanged: (value) => setState(() => _eventDuration = value),
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
                        if (_isUploading) return;
                        final updatedData = widget.bookingData.copyWith(
                          selectedServiceTitle: 'Event Organisers',
                          eventType: _eventType,
                          guestCount: int.tryParse(_guestCountController.text.trim()),
                          eventDuration: _eventDuration,
                          whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                          describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
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
                            if (mounted) context.pushNamed(RouteNames.quickServicesOtherServicesReview, extra: finalDataObj);
                          }).catchError((e) {
                            if (mounted) setState(() => _isUploading = false);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                          });
                        } else {
                          if (mounted) context.pushNamed(RouteNames.quickServicesOtherServicesReview, extra: updatedData);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
