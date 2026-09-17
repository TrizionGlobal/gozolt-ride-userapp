import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';
import '../../../data/models/quick_service_booking_data.dart';

class LaundryDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const LaundryDetailsScreen({super.key, required this.bookingData});

  @override
  State<LaundryDetailsScreen> createState() => _LaundryDetailsScreenState();
}

class _LaundryDetailsScreenState extends State<LaundryDetailsScreen> {
  String? _selectedMethod;
  String? _selectedService;
  double _servicePricePerKg = 0.0;
  int _laundryQuantityKg = 5;

  int _shirtCount = 0;
  int _dressCount = 0;
  int _trouserCount = 0;
  int _beddingCount = 0;

  String? _detergentArrangement;

  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _customServiceController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _laundryServices = [
    {'title': 'Wash & Fold', 'priceText': 'From €3/kg', 'unitPrice': 3.0},
    {'title': 'Wash & Iron', 'priceText': 'From €5/kg', 'unitPrice': 5.0},
    {'title': 'Ironing Only', 'priceText': 'From €3/kg', 'unitPrice': 3.0},
    {'title': 'Dry Cleaning', 'priceText': 'Price after inspection', 'unitPrice': 0.0},
    {'title': 'Bedding / Linen', 'priceText': 'From €8/item', 'unitPrice': 8.0},
    {'title': 'Curtains', 'priceText': 'Price after inspection', 'unitPrice': 0.0},
    {'title': 'Delicate Garments', 'priceText': 'Price after inspection', 'unitPrice': 0.0},
    {'title': 'Other Laundry Service', 'priceText': '', 'unitPrice': 0.0},
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
          const QuickServicesHeader(
            title: 'Service Requirements',
            subtitle: 'Laundry & Ironing',
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
                      final priceText = svc['priceText'] as String;
                      final unitPrice = svc['unitPrice'] as double;
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppColors.primaryGold : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                    Text(
                                      priceText,
                                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600], fontSize: 11),
                                    ),
                                  ],
                                ),
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

                  const SizedBox(height: 20),

                  // Estimated Laundry Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Estimated Laundry Quantity',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_laundryQuantityKg > 1) {
                                  setState(() => _laundryQuantityKg--);
                                }
                              },
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Icon(Icons.remove, size: 14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '$_laundryQuantityKg kg',
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _laundryQuantityKg++);
                              },
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Icon(Icons.add, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Detergent Arrangement
                  Text(
                    'Detergent Arrangement',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: ['Customer Provides Detergent', 'Professional Brings Detergent'].map((opt) {
                        final isSelected = _detergentArrangement == opt;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _detergentArrangement = opt),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Colors.amber.shade900.withOpacity(0.25) : const Color(0xFFFFF8E1))
                                    : Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? AppColors.primaryGold : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? (isDark ? AppColors.primaryGold : const Color(0xFFD97706)) : null,
                                        fontSize: 12,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Details (Tell us what you need, Describe issue, Upload Photos)
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

                  // Notice Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Final quantity and price will be confirmed before service begins.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      final finalServiceType = _selectedService == 'Other Laundry Service' && _customServiceController.text.trim().isNotEmpty
                          ? _customServiceController.text.trim()
                          : _selectedService;

                      final calculatedSubtotal = _servicePricePerKg * _laundryQuantityKg;
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Laundry & Ironing',
                        laundryServiceMethod: _selectedMethod,
                        laundryServiceType: finalServiceType,
                        laundryPackagePrice: _servicePricePerKg,
                        laundryQuantityKg: _laundryQuantityKg,
                        specialCareShirtCount: _shirtCount,
                        specialCareDressCount: _dressCount,
                        specialCareTrouserCount: _trouserCount,
                        specialCareBeddingCount: _beddingCount,
                        detergentArrangement: _detergentArrangement,
                        subtotal: 0.0,
                        baseEstimatedHours: (_laundryQuantityKg * 0.25) > 0 ? (_laundryQuantityKg * 0.25) : 0.5,
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
            width: isSelected ? 2 : 1,
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
