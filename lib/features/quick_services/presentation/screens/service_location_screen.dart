import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../ride/data/models/location_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/quick_services_header.dart';
import '../../data/models/quick_service_booking_data.dart';

class ServiceLocationScreen extends StatefulWidget {
  const ServiceLocationScreen({super.key});

  @override
  State<ServiceLocationScreen> createState() => _ServiceLocationScreenState();
}

class _ServiceLocationScreenState extends State<ServiceLocationScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LocationData? _selectedLocation;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Do not set defaults, force user to select
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _updateDateText();
      _updateTimeText();
    }
  }

  void _updateDateText() {
    if (_selectedDate == null) return;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _dateController.text = '${_selectedDate!.day} ${months[_selectedDate!.month - 1]} ${_selectedDate!.year}';
  }

  void _updateTimeText() {
    if (_selectedTime == null) return;
    _timeController.text = _selectedTime!.format(context);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _updateDateText();
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
      // Round to nearest 5 minutes (matching cab booking logic)
      int roundedMinute = ((time.minute / 5).round() * 5);
      int finalHour = time.hour;
      if (roundedMinute >= 60) {
        roundedMinute = 0;
        finalHour = (finalHour + 1) % 24;
      }
      setState(() {
        _selectedTime = TimeOfDay(hour: finalHour, minute: roundedMinute);
        _updateTimeText();
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await context.pushNamed<LocationData>(RouteNames.mapPinSelection);
    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
          const QuickServicesHeader(
            title: 'Location & Schedule',
          ),
          
          // ── Content ──────────────────────────────────────
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Schedule', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
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
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                    Text('Address', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
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
                                _selectedLocation?.address ?? 'Tap to select location', 
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
                        child: _selectedLocation != null
                            ? AbsorbPointer(
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
                                    zoom: 15,
                                  ),
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: false,
                                  compassEnabled: false,
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('selected_location'),
                                      position: LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
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
                    const SizedBox(height: 24),
                    Text('User Details', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [InputValidators.nameInputFormatter],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Full Name is required';
                        if (!InputValidators.isValidName(value)) return 'Enter a valid name';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Phone number is required';
                        if (value.length < 8) return 'Enter a valid phone number';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Email is required';
                        if (!InputValidators.isValidEmail(value)) return 'Enter a valid email address';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedLocation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a service location.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          final bookingData = QuickServiceBookingData(
                            scheduleDate: _selectedDate!,
                            scheduleTime: _selectedTime!,
                            location: _selectedLocation!,
                            userName: _nameController.text.trim(),
                            userPhone: _phoneController.text.trim(),
                            userEmail: _emailController.text.trim(),
                          );
                          context.pushNamed(
                            RouteNames.quickServicesList,
                            extra: bookingData,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
