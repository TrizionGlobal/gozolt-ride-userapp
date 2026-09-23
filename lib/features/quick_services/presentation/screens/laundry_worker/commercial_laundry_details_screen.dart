import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quick_services_booking_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';
import 'dart:io';


class CommercialLaundryDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const CommercialLaundryDetailsScreen({super.key, required this.bookingData});

  @override
  ConsumerState<CommercialLaundryDetailsScreen> createState() => _CommercialLaundryDetailsScreenState();
}

class _CommercialLaundryDetailsScreenState extends ConsumerState<CommercialLaundryDetailsScreen> {
  bool _isUploading = false;
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _customServiceController = TextEditingController();
  
  String _selectedMethod = 'On-Site Service';
  String _selectedService = '';
  double _servicePricePerKg = 0.0;
  String _materialPreference = 'Bring materials';
  
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _laundryServices = [

    {'title': 'Uniforms', 'icon': Icons.checkroom, 'priceText': '', 'unitPrice': 0.0},
    {'title': 'Towels', 'icon': Icons.layers, 'priceText': '', 'unitPrice': 0.0},
    {'title': 'Table Linen', 'icon': Icons.table_restaurant, 'priceText': '', 'unitPrice': 0.0},
    {'title': 'Cleaning Clothes', 'icon': Icons.cleaning_services, 'priceText': '', 'unitPrice': 0.0},

  ];


  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _collectionPointController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _otherBusinessTypeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime? _requestedDate;
  TimeOfDay? _requestedTime;
  String? _businessType;
  String? _serviceFrequency = 'One-Time Service';


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
    _customServiceController.dispose();

    _businessNameController.dispose();
    _collectionPointController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _otherBusinessTypeController.dispose();
    _dateController.dispose();
    _timeController.dispose();

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
      // Round to nearest 5 minutes
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


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          QuickServicesHeader(
            currentStep: 1,
            title: 'Service Requirements',
            subtitle: (widget.bookingData.selectedServiceTitle ?? 'Home').toLowerCase().endsWith('laundry') ? widget.bookingData.selectedServiceTitle! : '${widget.bookingData.selectedServiceTitle ?? 'Home'} Laundry',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Method
                  Text(
                    'Service Method',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildMethodCard(
                            title: 'On-Site Service',
                            subtitle: 'Service performed at your facility.',
                            icon: Icons.home_work_outlined,
                            isSelected: _selectedMethod == 'On-Site Service',
                            onTap: () => setState(() => _selectedMethod = 'On-Site Service'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMethodCard(
                            title: 'Pickup & Return',
                            subtitle: 'Return date & time confirmed after collection.',
                            icon: Icons.local_shipping_outlined,
                            isSelected: _selectedMethod == 'Pickup & Return',
                            onTap: () => setState(() => _selectedMethod = 'Pickup & Return'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Select Services
                  Text(
                    'Select Services',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _laundryServices.map((svc) {
                      final title = svc['title'] as String;
                      final unitPrice = svc['unitPrice'] as double;
                      final iconData = svc['icon'] as IconData?;
                      final isSelected = _selectedService == title;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedService = title;
                            _servicePricePerKg = unitPrice;
                          });
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 48) / 2,
                          height: 90,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (iconData != null)
                                Icon(
                                  iconData,
                                  color: isSelected ? AppColors.primaryGold : Colors.grey[700],
                                  size: 26,
                                ),
                              if (iconData != null) const SizedBox(height: 8),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  

                  const SizedBox(height: 24),


                  // Business Details
                  Text('Business Details', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Business Name', _businessNameController)),
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
                  if (_selectedMethod == 'Pickup & Return') ...[

                  // Requested Return
                  Text('Requested Return', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
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
                  ],


                  Text(
                    'Cleaning materials',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _materialPreference == 'Bring materials' ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                        width: _materialPreference == 'Bring materials' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handyman, size: 24, color: AppColors.primaryGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bring materials', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                _materialPreference == 'Bring materials' ? '+€${QuickServicesPricingConfig.getMaterialCost('commercial_laundry').toStringAsFixed(2)} extra charge' : 'Use my materials (No extra charge)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _materialPreference == 'Bring materials' ? AppColors.primaryGold : Colors.grey[600],
                                  fontWeight: _materialPreference == 'Bring materials' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: _materialPreference == 'Bring materials',
                            activeColor: isDark ? AppColors.backgroundDark : Colors.white,
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: Colors.grey[300],
                            onChanged: (val) {
                              setState(() {
                                _materialPreference = val ? 'Bring materials' : 'Use my materials';
                              });
                            },
                          ),
                        ),
                      ],
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

                  const SizedBox(height: 32),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {

                      if (_isUploading) return;
                      if (_selectedService.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service.'), backgroundColor: Colors.red));
                        return;
                      }
                      if ((_selectedService == 'Other Laundry Service' || _selectedService == 'Other Linen') && _customServiceController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please specify the service type.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_businessNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Business Name.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_collectionPointController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Collection Point.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_contactPersonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Contact Person.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_contactNumberController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Contact Number.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_selectedMethod == 'Pickup & Return' && (_requestedDate == null || _requestedTime == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Requested Return Date and Time.'), backgroundColor: Colors.red));
                        return;
                      }

                      final finalServiceType = (_selectedService == 'Other Laundry Service' || _selectedService == 'Other Linen') && _customServiceController.text.trim().isNotEmpty
                          ? _customServiceController.text.trim()
                          : _selectedService;


                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Commercial Laundry',
                        laundryServiceMethod: _selectedMethod,
                        commercialLaundryTypes: finalServiceType.isNotEmpty ? [finalServiceType] : [],
                        serviceFrequency: _serviceFrequency,
                        businessType: _businessType == 'Other' && _otherBusinessTypeController.text.isNotEmpty ? _otherBusinessTypeController.text : _businessType,
                        requestedReturnDate: _selectedMethod == 'Pickup & Return' ? _requestedDate : null,
                        requestedReturnTime: _selectedMethod == 'Pickup & Return' ? _requestedTime : null,
                        facilityName: _businessNameController.text.trim(),
                        collectionPoint: _collectionPointController.text.trim(),
                        facilityContactPerson: _contactPersonController.text.trim(),
                        facilityContactNumber: _contactNumberController.text.trim(),
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                        pickupAndReturnFee: _selectedMethod == 'Pickup & Return' ? QuickServicesPricingConfig.getPickupFee('commercial_laundry') : 0.0,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                      );
                      
                      if (_selectedImages.isNotEmpty) {
                        setState(() => _isUploading = true);
                        ref.read(quickServicesBookingProvider.notifier).uploadImages(
                          _selectedImages.map((e) => e.path).toList()
                        ).then((remoteUrls) {
                          if (mounted) setState(() => _isUploading = false);
                          var finalDataObj = updatedData.copyWith(uploadedImages: remoteUrls);
                          if (mounted) context.pushNamed(RouteNames.quickServicesLaundryReview, extra: finalDataObj);
                        }).catchError((e) {
                          if (mounted) setState(() => _isUploading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images')));
                        });
                      } else {
                        if (mounted) context.pushNamed(RouteNames.quickServicesLaundryReview, extra: updatedData);
                      }

                    },
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.amber.shade900.withOpacity(0.25) : const Color(0xFFFFF8E1))
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.primaryGold : Colors.grey[600], size: 22),
                const Spacer(),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_off,
                  color: isSelected ? AppColors.primaryGold : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? (isDark ? AppColors.primaryGold : Colors.black87) : Colors.grey[800],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: isSelected ? (isDark ? Colors.amber[200] : Colors.grey[800]) : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
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
              IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: onDecrement),
              Text('$value $suffix'.trim(), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, size: 20), onPressed: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, {String? hintText, int maxLines = 1, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, IconData? prefixIcon}) {
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
          textCapitalization: keyboardType == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
          inputFormatters: inputFormatters,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
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

}
