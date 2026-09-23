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

class SecurityPersonnelDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const SecurityPersonnelDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<SecurityPersonnelDetailsScreen> createState() => _SecurityPersonnelDetailsScreenState();
}

class _SecurityPersonnelDetailsScreenState extends ConsumerState<SecurityPersonnelDetailsScreen> {
  bool _isUploading = false;
  final List<String> _securityServices = [
    'Event Security',
    'Venue Access Control',
    'Crowd Management',
    'Bouncer / Door Security',
    'Property / Site Guard',
    'Personal Security',
    'Other Security Service',
  ];

  final List<String> _venueTypes = [
    'Private Event',
    'Wedding',
    'Corporate Event',
    'Bar / Club',
    'Residential Property',
    'Commercial Site',
    'Other',
  ];

  final List<String> _serviceAreas = ['Indoor', 'Outdoor', 'Both'];
  final List<String> _dressPreferences = ['Security Uniform', 'Formal Attire', 'Plain Clothes'];
  final List<String> _alcoholOptions = ['Yes', 'No'];

  String? _selectedSecurityService;
  String? _selectedVenueType;
  String? _selectedServiceArea;
  String? _selectedDressPreference;
  String? _selectedAlcoholServed;

  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 0);
  int _personnelCount = 1;

  final TextEditingController _attendanceController = TextEditingController(text: '120');
  final TextEditingController _dutyInstructionsController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.securityService != null) {
      _selectedSecurityService = widget.bookingData.securityService;
    }
    if (widget.bookingData.venueType != null) {
      _selectedVenueType = widget.bookingData.venueType;
    }
    if (widget.bookingData.serviceArea != null) {
      _selectedServiceArea = widget.bookingData.serviceArea;
    }
    if (widget.bookingData.dressPreference != null) {
      _selectedDressPreference = widget.bookingData.dressPreference;
    }
    if (widget.bookingData.alcoholServed != null) {
      _selectedAlcoholServed = widget.bookingData.alcoholServed;
    }
    if (widget.bookingData.personnelCount != null) {
      _personnelCount = widget.bookingData.personnelCount!;
    }
    if (widget.bookingData.expectedAttendance != null) {
      _attendanceController.text = widget.bookingData.expectedAttendance!;
    }
    if (widget.bookingData.describeIssue != null) {
      _dutyInstructionsController.text = widget.bookingData.describeIssue!;
    }
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
  }

  @override
  void dispose() {
    _attendanceController.dispose();
    _dutyInstructionsController.dispose();
    _whatYouNeedController.dispose();
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

  int _calculateDurationHours() {
    int startMinutes = _startTime.hour * 60 + _startTime.minute;
    int endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Next day
    }
    int diffMinutes = endMinutes - startMinutes;
    int hours = (diffMinutes / 60).round();
    return hours > 0 ? hours : 1;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).brightness == Brightness.dark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryGold,
                  onPrimary: Colors.black,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textPrimary,
                )
              : const ColorScheme.light(
                  primary: AppColors.primaryGold,
                  onPrimary: Colors.black,
                  onSurface: AppColors.textPrimaryLight,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          timePickerTheme: TimePickerThemeData(
            hourMinuteTextStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            dayPeriodTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            dayPeriodBorderSide: const BorderSide(color: AppColors.primaryGold),
            dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.primaryGold
                    : Colors.transparent),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.black
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)),
          ),
        ),
        child: Transform.scale(
          scale: 0.85,
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      int roundedMinute = ((picked.minute / 5).round() * 5);
      int finalHour = picked.hour;
      if (roundedMinute >= 60) {
        roundedMinute = 0;
        finalHour = (finalHour + 1) % 24;
      }
      final finalTime = TimeOfDay(hour: finalHour, minute: roundedMinute);

      setState(() {
        if (isStart) {
          _startTime = finalTime;
        } else {
          _endTime = finalTime;
        }
      });
    }
  }

  String _getDefaultDutyInstruction(String? service) {
    switch (service) {
      case 'Event Security':
        return 'Manage guest entry, venue access, and monitor the main event hall.';
      case 'Venue Access Control':
        return 'Screen guests, check tickets/invitations, and control entry/exit gates.';
      case 'Crowd Management':
        return 'Maintain orderly crowd flow, monitor exit paths, and prevent overcrowding.';
      case 'Bouncer / Door Security':
        return 'Perform ID checks at entry, manage the queue, and handle door security.';
      case 'Property / Site Guard':
        return 'Patrol property perimeter, log visitor entries, and monitor access points.';
      case 'Personal Security':
        return 'Provide close protection escort and personal security for VIPs/guests.';
      case 'Other Security Service':
        return 'Provide custom security services as specified in duty instructions.';
      default:
        return 'Manage guest entry and monitor the main event hall.';
    }
  }

  void _onSecurityServiceSelected(String service) {
    setState(() {
      _selectedSecurityService = service;
    });
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onContinue() {
    if (_selectedSecurityService == null) {
      _showValidationError('Please select a Security Service type to continue.');
      return;
    }
    if (_selectedVenueType == null) {
      _showValidationError('Please select the Venue Type for the assignment.');
      return;
    }
    if (_selectedServiceArea == null) {
      _showValidationError('Please select the Service Area (Indoor / Outdoor / Both).');
      return;
    }
    if (_selectedDressPreference == null) {
      _showValidationError('Please select the Dress Preference for your security personnel.');
      return;
    }
    if (_selectedAlcoholServed == null) {
      _showValidationError('Please indicate whether alcohol is served at the venue.');
      return;
    }

    final durationHours = _calculateDurationHours();
    // Estimated price: ~€18 per personnel per hour
    final subtotal = _personnelCount * durationHours * 18.0;

    final updatedData = widget.bookingData.copyWith(
      selectedServiceTitle: 'Security Personnel',
      securityService: _selectedSecurityService,
      venueType: _selectedVenueType,
      dutyStartTime: _formatTimeOfDay(_startTime),
      dutyEndTime: _formatTimeOfDay(_endTime),
      personnelCount: _personnelCount,
      expectedAttendance: _attendanceController.text.trim(),
      serviceArea: _selectedServiceArea,
      dressPreference: _selectedDressPreference,
      alcoholServed: _selectedAlcoholServed,
      describeIssue: _dutyInstructionsController.text.trim(),
      whatYouNeed: _selectedSecurityService,
      uploadedImages: _selectedImages.map((img) => img.path).toList(),
      subtotal: 0.0,
                        baseEstimatedHours: 0.0,
    );

    if (_isUploading) return;
    if (_selectedImages.isNotEmpty) {
      setState(() => _isUploading = true);
      ref.read(quickServicesBookingProvider.notifier).uploadImages(
        _selectedImages.map((e) => e.path).toList()
      ).then((remoteUrls) {
        if (mounted) setState(() => _isUploading = false);
        var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
        if (mounted) context.pushNamed(RouteNames.quickServicesSecurityPersonnelReview, extra: finalDataObj);
      }).catchError((e) {
        if (mounted) setState(() => _isUploading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
      });
    } else {
      if (mounted) context.pushNamed(RouteNames.quickServicesSecurityPersonnelReview, extra: updatedData);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    double? width,
    double height = 48.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.5,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationHours = _calculateDurationHours();
    final screenWidth = MediaQuery.of(context).size.width;
    final twoColWidth = (screenWidth - 40 - 8) / 2;
    final threeColWidth = (screenWidth - 40 - 16) / 3;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 1,
            title: 'Security Requirements',
            subtitle: 'Security / Bouncer Service',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Select Security Service
                  _buildSectionHeader('Select Security Service'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _securityServices.map((service) {
                      final isSelected = _selectedSecurityService == service;
                      return _buildSelectableChip(
                        label: service,
                        isSelected: isSelected,
                        width: twoColWidth,
                        onTap: () => _onSecurityServiceSelected(service),
                      );
                    }).toList(),
                  ),

                  // Venue Type
                  _buildSectionHeader('Venue Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _venueTypes.map((venue) {
                      final isSelected = _selectedVenueType == venue;
                      return _buildSelectableChip(
                        label: venue,
                        isSelected: isSelected,
                        width: twoColWidth,
                        onTap: () => setState(() => _selectedVenueType = venue),
                      );
                    }).toList(),
                  ),

                  // Duty Time Card (Start Time, End Time, Duration)
                  _buildSectionHeader('Duty Time'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Time',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _selectTime(true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimeOfDay(_startTime),
                                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const Icon(Icons.keyboard_arrow_down, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Time',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _selectTime(false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimeOfDay(_endTime),
                                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const Icon(Icons.keyboard_arrow_down, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Duration',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '$durationHours Hours',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Number of Personnel
                  _buildSectionHeader('Number of Personnel'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _personnelCount > 1
                              ? () => setState(() => _personnelCount--)
                              : null,
                        ),
                        Text(
                          '$_personnelCount',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _personnelCount++),
                        ),
                      ],
                    ),
                  ),

                  // Service Area
                  _buildSectionHeader('Service Area'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _serviceAreas.map((area) {
                      final isSelected = _selectedServiceArea == area;
                      return _buildSelectableChip(
                        label: area,
                        isSelected: isSelected,
                        width: threeColWidth,
                        onTap: () => setState(() => _selectedServiceArea = area),
                      );
                    }).toList(),
                  ),

                  // Dress Preference
                  _buildSectionHeader('Dress Preference'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dressPreferences.map((dress) {
                      final isSelected = _selectedDressPreference == dress;
                      return _buildSelectableChip(
                        label: dress,
                        isSelected: isSelected,
                        width: threeColWidth,
                        onTap: () => setState(() => _selectedDressPreference = dress),
                      );
                    }).toList(),
                  ),

                  // Alcohol served at venue?
                  _buildSectionHeader('Alcohol served at venue?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _alcoholOptions.map((opt) {
                      final isSelected = _selectedAlcoholServed == opt;
                      return _buildSelectableChip(
                        label: opt,
                        isSelected: isSelected,
                        width: twoColWidth,
                        onTap: () => setState(() => _selectedAlcoholServed = opt),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Additional Details
                  QuickServicesAdditionalDetails(
                    whatYouNeedController: _whatYouNeedController,
                    describeIssueController: _dutyInstructionsController,
                    images: _selectedImages,
                    onAddImages: _pickImages,
                    onRemoveImage: (image) {
                      setState(() {
                        _selectedImages.remove(image);
                      });
                    },
                  ),



                  const SizedBox(height: 24),
                  SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
}
