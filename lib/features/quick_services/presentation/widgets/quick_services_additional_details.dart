import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../ride/data/models/location_data.dart';
export '../../data/models/quick_services_booking_draft.dart';
import '../../data/models/quick_services_booking_draft.dart';
import 'quick_services_image_picker.dart';

class QuickServicesAdditionalDetails extends StatefulWidget {
  final TextEditingController whatYouNeedController;
  final TextEditingController describeIssueController;
  final List<XFile> images;
  final VoidCallback onAddImages;
  final Function(XFile) onRemoveImage;
  final bool showTellUsWhatYouNeed;

  const QuickServicesAdditionalDetails({
    super.key,
    required this.whatYouNeedController,
    required this.describeIssueController,
    required this.images,
    required this.onAddImages,
    required this.onRemoveImage,
    this.showTellUsWhatYouNeed = true,
  });

  @override
  State<QuickServicesAdditionalDetails> createState() => _QuickServicesAdditionalDetailsState();
}

class _QuickServicesAdditionalDetailsState extends State<QuickServicesAdditionalDetails> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDateText();
    _updateTimeText();
  }

  void _updateDateText() {
    final date = QuickServicesBookingDraft.selectedDate;
    if (date == null) return;
    _dateController.text = DateFormat('dd MMM yyyy').format(date);
  }

  void _updateTimeText() {
    final time = QuickServicesBookingDraft.selectedTime;
    if (time == null) return;
    _timeController.text = time.format(context);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: QuickServicesBookingDraft.selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryGold,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimary,
                )
              : const ColorScheme.light(
                  primary: AppColors.primaryGold,
                  onSurface: AppColors.textPrimaryLight,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        QuickServicesBookingDraft.selectedDate = date;
        _updateDateText();
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: QuickServicesBookingDraft.selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryGold,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimary,
                )
              : const ColorScheme.light(
                  primary: AppColors.primaryGold,
                  onSurface: AppColors.textPrimaryLight,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          timePickerTheme: const TimePickerThemeData(
            hourMinuteTextStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            dayPeriodTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: Transform.scale(
          scale: 0.85,
          child: child!,
        ),
      ),
    );
    if (time != null) {
      int roundedMinute = ((time.minute / 5).round() * 5);
      int finalHour = time.hour;
      if (roundedMinute >= 60) {
        roundedMinute = 0;
        finalHour = (finalHour + 1) % 24;
      }
      final roundedTime = TimeOfDay(hour: finalHour, minute: roundedMinute);
      setState(() {
        QuickServicesBookingDraft.selectedTime = roundedTime;
        _timeController.text = roundedTime.format(context);
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await context.pushNamed<LocationData>(RouteNames.mapPinSelection);
    if (result != null && mounted) {
      setState(() {
        QuickServicesBookingDraft.selectedLocation = result;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedLocation = QuickServicesBookingDraft.selectedLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Describe issue
        Text(
          'Describe issue',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : const Color(0xFF324461),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.describeIssueController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the problem in detail...',
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
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
          ),
        ),
        const SizedBox(height: 16),

        // Image Picker
        QuickServicesImagePicker(
          images: widget.images,
          onAddPressed: widget.onAddImages,
          onRemovePressed: widget.onRemoveImage,
        ),

        const SizedBox(height: 24),

        // ── Schedule ───────────────────────────────────────
        Text(
          'Schedule',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : const Color(0xFF324461),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select Date',
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select Time',
                      prefixIcon: const Icon(Icons.access_time, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Address ────────────────────────────────────────
        Text(
          'Address',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : const Color(0xFF324461),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickLocation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardTheme.color,
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryGold),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    selectedLocation?.address ?? 'Tap to select location',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Map Placeholder / Map View
        GestureDetector(
          onTap: _pickLocation,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: selectedLocation != null
                ? AbsorbPointer(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(selectedLocation.latitude, selectedLocation.longitude),
                        zoom: 15,
                      ),
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: LatLng(selectedLocation.latitude, selectedLocation.longitude),
                        )
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Map Placeholder\n(Tap to Pick Location)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
