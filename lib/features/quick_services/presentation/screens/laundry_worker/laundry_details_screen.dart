import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';
import '../../../../../core/config/quick_services_pricing_config.dart';

class LaundryDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const LaundryDetailsScreen({super.key, required this.bookingData});

  @override
  State<LaundryDetailsScreen> createState() => _LaundryDetailsScreenState();
}

class _LaundryDetailsScreenState extends State<LaundryDetailsScreen> {
  String _materialPreference = 'Bring materials';
  String? _selectedMethod = 'At-Home Service';
  String? _selectedService;
  double _servicePricePerKg = 0.0;


  int _shirtCount = 0;
  int _dressCount = 0;
  int _trouserCount = 0;
  int _beddingCount = 0;



  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _customServiceController = TextEditingController();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? _requestedDate;
  TimeOfDay? _requestedTime;

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _laundryServices = [
    {'title': 'Wash & Fold', 'icon': Icons.local_laundry_service, 'priceText': '', 'unitPrice': 3.0},
    {'title': 'Wash & Iron', 'icon': Icons.dry_cleaning, 'priceText': '', 'unitPrice': 5.0},
    {'title': 'Ironing Only', 'icon': Icons.iron, 'priceText': '', 'unitPrice': 3.0},
    {'title': 'Dry Cleaning', 'icon': Icons.checkroom, 'priceText': '', 'unitPrice': 0.0},
    {'title': 'Bedding / Linen', 'icon': Icons.bed, 'priceText': '', 'unitPrice': 8.0},
    {'title': 'Curtains', 'icon': Icons.curtains, 'priceText': '', 'unitPrice': 0.0},
    {'title': 'Delicate Garments', 'icon': Icons.wash, 'priceText': '', 'unitPrice': 0.0},
    {'title': 'Other Laundry Service', 'icon': Icons.more_horiz, 'priceText': '', 'unitPrice': 0.0},
  ];

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
                            title: 'At-Home Service',
                            subtitle: 'Service performed at your address.',
                            icon: Icons.home_work_outlined,
                            isSelected: _selectedMethod == 'At-Home Service',
                            onTap: () => setState(() => _selectedMethod = 'At-Home Service'),
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

                  if (_selectedService == 'Other Laundry Service') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customServiceController,
                      style: AppTextStyles.bodyMedium,
                      decoration: _inputDecoration(hintText: 'Enter Custom Laundry Service'),
                    ),
                  ],



                  const SizedBox(height: 24),
                  // Special-Care Items
                  Text(
                    'Special-Care Items',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildItemCounter(
                            label: 'Shirts',
                            icon: Icons.dry_cleaning,
                            count: _shirtCount,
                            onDecrement: () {
                              if (_shirtCount > 0) setState(() => _shirtCount--);
                            },
                            onIncrement: () => setState(() => _shirtCount++),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildItemCounter(
                            label: 'Suits / Party wear',
                            icon: Icons.checkroom,
                            count: _dressCount,
                            onDecrement: () {
                              if (_dressCount > 0) setState(() => _dressCount--);
                            },
                            onIncrement: () => setState(() => _dressCount++),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildItemCounter(
                            label: 'Trousers',
                            icon: Icons.straighten,
                            count: _trouserCount,
                            onDecrement: () {
                              if (_trouserCount > 0) setState(() => _trouserCount--);
                            },
                            onIncrement: () => setState(() => _trouserCount++),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildItemCounter(
                            label: 'Bedding / Linen',
                            icon: Icons.single_bed,
                            count: _beddingCount,
                            onDecrement: () {
                              if (_beddingCount > 0) setState(() => _beddingCount--);
                            },
                            onIncrement: () => setState(() => _beddingCount++),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                                _materialPreference == 'Bring materials' ? '+€${QuickServicesPricingConfig.getMaterialCost('laundry').toStringAsFixed(2)} extra charge' : 'Use my materials (No extra charge)',
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

                  const SizedBox(height: 20),



                  const SizedBox(height: 32),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {

                      if (_selectedMethod == null || _selectedMethod!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service method.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_selectedService == null || _selectedService!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_selectedService == 'Other Laundry Service' && _customServiceController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please specify the service type.'), backgroundColor: Colors.red));
                        return;
                      }

                      final finalServiceType = _selectedService == 'Other Laundry Service' && _customServiceController.text.trim().isNotEmpty
                          ? _customServiceController.text.trim()
                          : _selectedService;

                      final calculatedSubtotal = _servicePricePerKg * 1;
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Laundry & Ironing',
                        laundryServiceMethod: _selectedMethod,
                        requestedReturnDate: _selectedMethod == 'Pickup & Return' ? _requestedDate : null,
                        requestedReturnTime: _selectedMethod == 'Pickup & Return' ? _requestedTime : null,
                        laundryServiceType: finalServiceType,
                        laundryPackagePrice: _servicePricePerKg,
                        laundryQuantityKg: 1,
                        specialCareShirtCount: _shirtCount,
                        specialCareDressCount: _dressCount,
                        specialCareTrouserCount: _trouserCount,
                        specialCareBeddingCount: _beddingCount,
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                        pickupAndReturnFee: _selectedMethod == 'Pickup & Return' ? QuickServicesPricingConfig.getPickupFee('laundry') : 0.0,
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty
                            ? _whatYouNeedController.text.trim()
                            : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty
                            ? _describeIssueController.text.trim()
                            : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                      );

                      context.pushNamed(
                        RouteNames.quickServicesLaundryReview,
                        extra: updatedData,
                      );
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
                    child: Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
                Icon(
                  icon,
                  color: isSelected ? AppColors.primaryGold : const Color(0xFF324461),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12.5,
                      color: isSelected ? (isDark ? AppColors.primaryGold : const Color(0xFFB45309)) : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCounter({
    required String label,
    required IconData icon,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF324461)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 10.5, height: 1.1),
              maxLines: 2,
              softWrap: true,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onDecrement,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.remove, size: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$count',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                InkWell(
                  onTap: onIncrement,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.add, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
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
    );
  }
}
