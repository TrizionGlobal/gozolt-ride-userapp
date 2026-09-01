import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_filled_text_field.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../../ride/data/models/location_data.dart';
import '../widgets/bike_rental_location_search.dart';
import '../providers/bike_rental_search_provider.dart';
import '../../../../core/utils/geo_utils.dart';

import '../widgets/bike_rental_header.dart';

class BikeRentalSearchScreen extends ConsumerStatefulWidget {
  const BikeRentalSearchScreen({super.key});

  @override
  ConsumerState<BikeRentalSearchScreen> createState() => _BikeRentalSearchScreenState();
}

class _BikeRentalSearchScreenState extends ConsumerState<BikeRentalSearchScreen> {
  bool _returnToSameLocation = true;
  bool _driverAgeValid = true;
  String _deliveryType = 'SELF_PICKUP';

  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  LocationData? _pickupLocation;
  LocationData? _dropoffLocation;

  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _dropoffDate;
  TimeOfDay? _dropoffTime;

  final _deliveryAddressController = TextEditingController();
  final _deliveryPhoneController = TextEditingController();
  final _deliveryEmailController = TextEditingController();
  final _deliveryWhatsappController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickupLocation = null;
    _pickupController.text = '';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _deliveryAddressController.dispose();
    _deliveryPhoneController.dispose();
    _deliveryEmailController.dispose();
    _deliveryWhatsappController.dispose();
    super.dispose();
  }

  void _selectLocation(String field) {
    if (field == 'dropoff' && _returnToSameLocation) {
      // Don't allow selecting drop-off if returning to same location
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BikeRentalLocationSearchSheet(
        showCurrentLocation: field == 'pickup',
        onSelect: (location) {
          Navigator.of(ctx).pop();
          setState(() {
            if (field == 'pickup') {
              _pickupLocation = location;
              _pickupController.text = location.address;
              if (_returnToSameLocation) {
                _dropoffLocation = location;
                _dropoffController.text = location.address;
              }
            } else if (field == 'dropoff') {
              _dropoffLocation = location;
              _dropoffController.text = location.address;
            }
          });
        },
      ),
    );
  }

  Future<void> _selectDate(bool isPickup) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimaryLight,
                ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = pickedDate;
        } else {
          _dropoffDate = pickedDate;
        }
      });
    }
  }

  Future<void> _selectTime(bool isPickup) async {
    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: now,
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
          textTheme: Theme.of(context).textTheme.copyWith(
            displayLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          timePickerTheme: TimePickerThemeData(
            hourMinuteTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            dayPeriodTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = pickedTime;
        } else {
          _dropoffTime = pickedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BikeRentalHeader(title: 'Bike Rental'),
            // ── Location Input Box ──────────────────────────────
            if (_deliveryType != 'SELF_PICKUP' || !_returnToSameLocation)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryGold, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_deliveryType != 'SELF_PICKUP')
                      BikeRentalLocationField(
                        controller: _pickupController,
                        hint: 'Current Location / Search Location',
                        dotColor: AppColors.success,
                        labelOverride: 'PICKUP',
                        onTap: () => _selectLocation('pickup'),
                      ),
                    
                    if (_deliveryType != 'SELF_PICKUP' && !_returnToSameLocation)
                      // Connecting line between locations
                      Padding(
                        padding: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      
                    if (!_returnToSameLocation)
                      BikeRentalLocationField(
                        controller: _dropoffController,
                        hint: 'Where are you going?',
                        dotColor: AppColors.error,
                        labelOverride: 'DROP-OFF',
                        onTap: () => _selectLocation('dropoff'),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(isDark, 'Pickup Date'),
                            const SizedBox(height: 8),
                            AppFilledTextField(
                              hint: 'Select Date',
                              value: _pickupDate != null ? DateFormat('MMM dd, yyyy').format(_pickupDate!) : null,
                              icon: Icons.calendar_today,
                              onTap: () => _selectDate(true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(isDark, 'Pickup Time'),
                            const SizedBox(height: 8),
                            AppFilledTextField(
                              hint: 'Select Time',
                              value: _pickupTime != null ? _pickupTime!.format(context) : null,
                              icon: Icons.access_time,
                              onTap: () => _selectTime(true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(isDark, 'Drop-off Date'),
                            const SizedBox(height: 8),
                            AppFilledTextField(
                              hint: 'Select Date',
                              value: _dropoffDate != null ? DateFormat('MMM dd, yyyy').format(_dropoffDate!) : null,
                              icon: Icons.calendar_today,
                              onTap: () => _selectDate(false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(isDark, 'Drop-off Time'),
                            const SizedBox(height: 8),
                            AppFilledTextField(
                              hint: 'Select Time',
                              value: _dropoffTime != null ? _dropoffTime!.format(context) : null,
                              icon: Icons.access_time,
                              onTap: () => _selectTime(false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _returnToSameLocation,
                          activeColor: AppColors.primaryGold,
                          onChanged: (val) {
                            setState(() {
                              _returnToSameLocation = val ?? true;
                              if (_returnToSameLocation && _pickupLocation != null) {
                                _dropoffLocation = _pickupLocation;
                                _dropoffController.text = _pickupLocation!.address;
                              } else {
                                _dropoffLocation = null;
                                _dropoffController.text = '';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Return Bike to Same Location'),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _driverAgeValid,
                          activeColor: AppColors.primaryGold,
                          onChanged: (val) {
                            setState(() {
                              _driverAgeValid = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Driver aged between 20-70 years'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader(isDark, 'Bike Delivery Option'),
                  const SizedBox(height: 8),
                  _buildDeliveryOptions(isDark),

                  // Removed inline delivery details form since Doorstep Delivery is now informational

                  const SizedBox(height: 40),
                  GozoltButton(
                    label: 'Search Available Bikes',
                    width: double.infinity,
                    onPressed: () {
                      if (_deliveryType != 'SELF_PICKUP' && _pickupLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pickup location'), backgroundColor: Colors.red));
                        return;
                      }
                      if (!_returnToSameLocation && _dropoffLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a drop-off location'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_pickupDate == null || _pickupTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select pickup date and time'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_dropoffDate == null || _dropoffTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select drop-off date and time'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_deliveryType == 'DOORSTEP_DELIVERY') {
                        if (_deliveryAddressController.text.trim().isEmpty) {
                          // Allow continue without checking delivery fields since it's informational
                        }
                      }
                      
                      ref.read(bikeRentalSearchProvider.notifier).setSearchOptions(
                        type: _deliveryType,
                        address: _deliveryAddressController.text.trim(),
                        phone: _deliveryPhoneController.text.trim(),
                        email: _deliveryEmailController.text.trim(),
                        whatsapp: _deliveryWhatsappController.text.trim(),
                        pickupLocation: _deliveryType == 'SELF_PICKUP' ? '' : (_pickupLocation?.address ?? ''),
                        dropoffLocation: _returnToSameLocation 
                            ? (_deliveryType == 'SELF_PICKUP' ? '' : (_pickupLocation?.address ?? '')) 
                            : (_dropoffLocation?.address ?? ''),
                        pickupLat: _deliveryType == 'SELF_PICKUP' ? null : _pickupLocation?.latitude,
                        pickupLng: _deliveryType == 'SELF_PICKUP' ? null : _pickupLocation?.longitude,
                        dropoffLat: _returnToSameLocation 
                            ? (_deliveryType == 'SELF_PICKUP' ? null : _pickupLocation?.latitude) 
                            : _dropoffLocation?.latitude,
                        dropoffLng: _returnToSameLocation 
                            ? (_deliveryType == 'SELF_PICKUP' ? null : _pickupLocation?.longitude) 
                            : _dropoffLocation?.longitude,
                        pickupDate: _pickupDate,
                        pickupTime: _pickupTime?.format(context),
                        dropoffDate: _dropoffDate,
                        dropoffTime: _dropoffTime?.format(context),
                      );
                      
                      context.pushNamed(RouteNames.bikeRentalList);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(bool isDark, String hint, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13, 
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
        suffixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: isDark ? AppColors.primaryGold : Colors.black54,
      ),
    );
  }

  Widget _buildDeliveryOptions(bool isDark) {
    return Column(
      children: [
        RadioListTile(
          value: 'SELF_PICKUP',
          groupValue: _deliveryType,
          activeColor: AppColors.primaryGold,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: const Text('Self Pickup'),
          onChanged: (val) => setState(() => _deliveryType = val.toString()),
        ),
        RadioListTile(
          value: 'SUPPLIER_DELIVERY',
          groupValue: _deliveryType,
          activeColor: AppColors.primaryGold,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: const Text('Supplier Delivery'),
          onChanged: (val) => setState(() => _deliveryType = val.toString()),
        ),
        RadioListTile(
          value: 'DOORSTEP_DELIVERY',
          groupValue: _deliveryType,
          activeColor: AppColors.primaryGold,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: const Text('Doorstep Delivery'),
          onChanged: (val) {
            setState(() => _deliveryType = val.toString());
            _showDeliveryDetailsModal(context);
          },
        ),
      ],
    );
  }

  Future<void> _showDeliveryDetailsModal(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doorstep Delivery', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'For doorstep delivery arrangements, please contact our support team directly at the details below:',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildContactDetailRow(isDark, Icons.location_on, 'Office Address', 'Triq il-Kbira, Sliema, Malta', () async {
                final uri = Uri.parse('https://maps.google.com/?q=Triq+il-Kbira,Sliema,Malta');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }),
              const SizedBox(height: 16),
              _buildContactDetailRow(isDark, Icons.phone, 'Phone Number', '+356 999 00002', () async {
                final uri = Uri.parse('tel:+35699900002');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }),
              const SizedBox(height: 16),
              _buildContactDetailRow(isDark, Icons.email, 'Email ID', 'info@gozolt.com', () async {
                final uri = Uri.parse('mailto:info@gozolt.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }),
              const SizedBox(height: 16),
              _buildContactDetailRow(isDark, Icons.chat, 'WhatsApp Number', '+356 999 00002', () async {
                final uri = Uri.parse('https://wa.me/35699900002');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }),
              const SizedBox(height: 32),
              GozoltButton(
                label: 'OK',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    // This runs after the modal is closed, regardless of whether they tapped OK, swiped down, or tapped outside.
    if (mounted) {
      setState(() {
        _deliveryType = 'SELF_PICKUP';
      });
    }
  }

  Widget _buildContactDetailRow(bool isDark, IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryGold, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
