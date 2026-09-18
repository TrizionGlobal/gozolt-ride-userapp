import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import 'dart:io';

class HotelLaundryDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const HotelLaundryDetailsScreen({super.key, required this.bookingData});

  @override
  State<HotelLaundryDetailsScreen> createState() => _HotelLaundryDetailsScreenState();
}

class _HotelLaundryDetailsScreenState extends State<HotelLaundryDetailsScreen> {
  String _materialPreference = 'Bring materials';
  final TextEditingController _facilityNameController = TextEditingController();
  final TextEditingController _collectionPointController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _otherLaundryTypeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final List<String> _selectedLaundryTypes = [];
  final List<String> _availableLaundryTypes = ['Bed Linen', 'Towels', 'Staff Uniforms', 'Table Linen', 'Guest Laundry', 'Curtains', 'Other Laundry'];

  int _estimatedWeightKg = 1;
  int _numberOfBags = 1;

  String? _linenType;
  String? _serviceFrequency = 'One-Time Service';

  DateTime? _requestedDate;
  TimeOfDay? _requestedTime;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill if needed
  }

  @override
  void dispose() {
    _facilityNameController.dispose();
    _collectionPointController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
    _otherLaundryTypeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    if (_requestedDate == null) return;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _dateController.text = '${_requestedDate!.day} ${months[_requestedDate!.month - 1]} ${_requestedDate!.year}';
  }

  void _updateTimeText() {
    if (_requestedTime == null) return;
    _timeController.text = _requestedTime!.format(context);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _requestedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) {
      setState(() {
        _requestedDate = picked;
        _updateDateText();
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _requestedTime ?? TimeOfDay.now(),
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
    if (picked != null) {
      int roundedMinute = ((picked.minute / 5).round() * 5);
      int finalHour = picked.hour;
      if (roundedMinute >= 60) {
        roundedMinute = 0;
        finalHour = (finalHour + 1) % 24;
      }
      setState(() {
        _requestedTime = TimeOfDay(hour: finalHour, minute: roundedMinute);
        _updateTimeText();
      });
    }
  }

  Future<void> _pickFiles() async {
    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(files);
      });
    }
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFF1E3A8A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup & Return',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                ),
                Text(
                  'Hotel laundry is collected and returned by an approved provider.',
                  style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hintText, int maxLines = 1, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
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
    );
  }

  Widget _buildCounterField(String label, int value, VoidCallback onDecrement, VoidCallback onIncrement, {String suffix = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardTheme.color,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: onDecrement,
                color: Colors.black,
              ),
              Text(
                '$value $suffix'.trim(),
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: onIncrement,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ],
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
            title: 'Hotel Laundry Requirements',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNoticeBanner(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Hotel Details
                        _buildSectionHeader('1. Hotel Details'),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Hotel Name', _facilityNameController)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Collection Point', _collectionPointController)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Contact Person', _contactPersonController)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Contact Number', _contactNumberController, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                          ],
                        ),
                        const Divider(height: 32),

                        // 2. Select Laundry Type
                        Row(
                          children: [
                            _buildSectionHeader('2. Select Laundry Type'),
                            const SizedBox(width: 8),
                            Text('(Select all that apply)', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _availableLaundryTypes.map((type) {
                            final isSelected = _selectedLaundryTypes.contains(type);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedLaundryTypes.remove(type);
                                  } else {
                                    _selectedLaundryTypes.add(type);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      type,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle, size: 16, color: Colors.black),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_selectedLaundryTypes.contains('Other Laundry')) ...[
                          const SizedBox(height: 12),
                          _buildTextField('', _otherLaundryTypeController, hintText: 'Please specify other laundry type'),
                        ],
                        const Divider(height: 32),

                        // 3. Estimated Quantity
                        _buildSectionHeader('3. Estimated Quantity'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCounterField('Estimated Weight', _estimatedWeightKg, () {
                                if (_estimatedWeightKg > 1) setState(() => _estimatedWeightKg--);
                              }, () {
                                setState(() => _estimatedWeightKg++);
                              }, suffix: 'kg'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCounterField('Number of Bags', _numberOfBags, () {
                                if (_numberOfBags > 1) setState(() => _numberOfBags--);
                              }, () {
                                setState(() => _numberOfBags++);
                              }),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // 4. Service Frequency
                        _buildSectionHeader('4. Service Frequency'),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ['One-Time Service', 'Recurring Service'].map((type) {
                            final isSelected = _serviceFrequency == type;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _serviceFrequency = type;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      size: 18,
                                      color: isSelected ? Colors.black : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      type,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recurring schedule can be confirmed by the provider.',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                        ),
                        const Divider(height: 32),

                        // 5. Special Handling
                        _buildSectionHeader('5. Special Handling'),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: ['Standard', 'Special Care Required', 'Not Sure'].map((type) {
                            final isSelected = _linenType == type;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _linenType = type;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGold.withOpacity(0.15) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      size: 18,
                                      color: isSelected ? Colors.black : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      type,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The provider will confirm special-care requirements.',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                        ),
                        const Divider(height: 32),

                        // 6. Requested Return
                        _buildSectionHeader('6. Requested Return'),
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
                                      hintText: 'Date',
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickTime,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _timeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'Time',
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
                        const SizedBox(height: 8),
                        Text(
                          'Subject to provider confirmation.',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                        ),
                        const Divider(height: 32),

                        // 7. Additional Details
                        _buildSectionHeader('7. Additional Details'),
                        QuickServicesAdditionalDetails(
                          whatYouNeedController: _whatYouNeedController,
                          describeIssueController: _describeIssueController,
                          images: _selectedFiles,
                          onAddImages: _pickFiles,
                          onRemoveImage: (image) {
                            setState(() {
                              _selectedFiles.remove(image);
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Warning Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Provide only sealed and labelled laundry bags. Clinical waste and sharps are not accepted.',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Continue Button
                        ElevatedButton(
                          onPressed: () {
                            if (_facilityNameController.text.trim().isEmpty || _collectionPointController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required hotel details.')));
                              return;
                            }
                            if (_linenType == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select special handling requirements.')));
                              return;
                            }
                            if (_requestedDate == null || _requestedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select requested return date and time.')));
                              return;
                            }

                            List<String> finalLaundryTypes = List.from(_selectedLaundryTypes);
                            if (finalLaundryTypes.contains('Other Laundry') && _otherLaundryTypeController.text.trim().isNotEmpty) {
                              finalLaundryTypes.remove('Other Laundry');
                              finalLaundryTypes.add(_otherLaundryTypeController.text.trim());
                            }

                            final updatedData = widget.bookingData.copyWith(
                              selectedServiceTitle: 'Hotel Laundry',
                              facilityName: _facilityNameController.text.trim(),
                              collectionPoint: _collectionPointController.text.trim(),
                              facilityContactPerson: _contactPersonController.text.trim(),
                              facilityContactNumber: _contactNumberController.text.trim(),
                              commercialLaundryTypes: finalLaundryTypes,
                              laundryQuantityKg: _estimatedWeightKg,
                              numberOfBags: _numberOfBags,
                              serviceFrequency: _serviceFrequency,
                              linenHandlingType: _linenType,
                              requestedReturnDate: _requestedDate,
                              requestedReturnTime: _requestedTime,
                              whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                              describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                              uploadedImages: _selectedFiles.map((e) => e.path).toList(),
                              baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                            );

                            context.pushNamed(RouteNames.quickServicesLaundryReview, extra: updatedData);
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
