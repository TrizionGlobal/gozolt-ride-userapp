import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class CarWashDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const CarWashDetailsScreen({super.key, required this.bookingData});

  @override
  State<CarWashDetailsScreen> createState() => _CarWashDetailsScreenState();
}

class _CarWashDetailsScreenState extends State<CarWashDetailsScreen> {
  String _materialPreference = 'Bring materials';
  
  // List to hold multiple vehicles
  final List<CarWashVehicle> _savedVehicles = [];

  // Controllers for the current vehicle form
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  
  String? _selectedWashPackage;
  double _selectedPackagePrice = 0.0;
  String? _selectedCondition;

  // Global properties (not per vehicle)
  String? _waterAccess;
  String? _electricityAccess;
  String _serviceMode = 'On-Site';

  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> get _washPackages {
    final title = widget.bookingData.selectedServiceTitle ?? '';
    if (title.contains('Bike')) {
      return [
        {'title': 'Standard Wash', 'price': 10.0, 'displayPrice': '€10'},
        {'title': 'Detailed Wash', 'price': 15.0, 'displayPrice': '€15'},
      ];
    }
    return [
      {'title': 'Exterior Wash', 'price': 15.0, 'displayPrice': '€15'},
      {'title': 'Interior Cleaning', 'price': 18.0, 'displayPrice': '€18'},
      {'title': 'Full Wash', 'price': 30.0, 'displayPrice': '€30'},
    ];
  }

  final List<String> _vehicleConditions = [
    'Normal',
    'Heavy Dirt / Mud',
    'Pet Hair',
    'Sand',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _whatYouNeedController.dispose();
    _describeIssueController.dispose();
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

  void _addVehicle(String vName) {
    if (_vehicleTypeController.text.trim().isEmpty ||
        _vehicleMakeController.text.trim().isEmpty ||
        _vehicleModelController.text.trim().isEmpty ||
        _selectedWashPackage == null ||
        _selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all $vName details, select a wash package and condition.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _savedVehicles.add(CarWashVehicle(
        type: _vehicleTypeController.text.trim(),
        make: _vehicleMakeController.text.trim(),
        model: _vehicleModelController.text.trim(),
        washPackage: _selectedWashPackage!,
        washPackagePrice: _selectedPackagePrice,
        condition: _selectedCondition!,
      ));

      // Reset form
      _vehicleTypeController.clear();
      _vehicleMakeController.clear();
      _vehicleModelController.clear();
      _selectedWashPackage = null;
      _selectedPackagePrice = 0.0;
      _selectedCondition = null;
      
      // Remove focus to dismiss keyboard and focus outlines
      FocusScope.of(context).unfocus();
    });
  }

  void _removeVehicle(int index) {
    setState(() {
      _savedVehicles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String getVehicleName() {
      final title = widget.bookingData.selectedServiceTitle?.toLowerCase() ?? '';
      if (title.contains('bike')) return 'Bike';
      if (title.contains('truck')) return 'Truck';
      if (title.contains('car')) return 'Car';
      return 'Car';
    }
    final vName = getVehicleName();
    final fullServiceName = '$vName Wash';
    String getTypePlaceholder() {
      if (vName == 'Bike') return 'e.g. Sports';
      if (vName == 'Truck') return 'e.g. Box Truck';
      return 'e.g. Sedan';
    }
    String getMakePlaceholder() {
      if (vName == 'Bike') return 'e.g. Yamaha';
      if (vName == 'Truck') return 'e.g. Volvo';
      return 'e.g. Toyota';
    }
    String getModelPlaceholder() {
      if (vName == 'Bike') return 'e.g. YZF-R1';
      if (vName == 'Truck') return 'e.g. FH16';
      return 'e.g. Corolla';
    }


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          QuickServicesHeader(
            currentStep: 1,
            title: 'Service Requirements',
            subtitle: fullServiceName,
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SERVICE MODE ---
                  Text(
                    'Service Mode',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _serviceMode = 'On-Site';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _serviceMode == 'On-Site' ? AppColors.primaryGold.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _serviceMode == 'On-Site' ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'On-Site',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: _serviceMode == 'On-Site' ? FontWeight.bold : FontWeight.normal,
                                  color: _serviceMode == 'On-Site' ? AppColors.primaryGold : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _serviceMode = 'Pickup & Return';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _serviceMode == 'Pickup & Return' ? AppColors.primaryGold.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _serviceMode == 'Pickup & Return' ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Pickup & Return',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: _serviceMode == 'Pickup & Return' ? FontWeight.bold : FontWeight.normal,
                                  color: _serviceMode == 'Pickup & Return' ? AppColors.primaryGold : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- VEHICLE FORM ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add a $vName',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Vehicle Type
                        Text(
                          '$vName Type',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _vehicleTypeController,
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(hintText: getTypePlaceholder()),
                        ),
                        const SizedBox(height: 14),

                        // Vehicle Make & Model Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$vName Make',
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _vehicleMakeController,
                                    textCapitalization: TextCapitalization.words,
                                    style: AppTextStyles.bodyMedium,
                                    decoration: _inputDecoration(hintText: getMakePlaceholder()),
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
                                    '$vName Model',
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _vehicleModelController,
                                    textCapitalization: TextCapitalization.words,
                                    style: AppTextStyles.bodyMedium,
                                    decoration: _inputDecoration(hintText: getModelPlaceholder()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Select Wash Package
                        Text(
                          'Select Wash Package',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: _washPackages.map((package) {
                            final title = package['title'] as String;
                            final price = package['price'] as double;
                            final displayPrice = package['displayPrice'] as String;
                            final isSelected = _selectedWashPackage == title;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedWashPackage = title;
                                  _selectedPackagePrice = price;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? AppColors.primaryGold : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      displayPrice,
                                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Vehicle Condition
                        Text(
                          '$vName Condition',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _vehicleConditions.map((condition) {
                            final isSelected = _selectedCondition == condition;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCondition = condition),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGold.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  condition,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? (isDark ? AppColors.primaryGold : const Color(0xFFD97706)) : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Add Vehicle Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _addVehicle(vName),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.primaryGold : const Color(0xFFD97706),
                              side: BorderSide(color: isDark ? AppColors.primaryGold : const Color(0xFFD97706)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline, size: 20),
                                const SizedBox(width: 8),
                                Text('Add $vName', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LIST OF ADDED VEHICLES ---
                  if (_savedVehicles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Added ${vName}s (${_savedVehicles.length})',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _savedVehicles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vehicle = _savedVehicles[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.directions_car, color: AppColors.primaryGold, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${vehicle.make} ${vehicle.model}',
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Type: ${vehicle.type}',
                                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removeVehicle(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.washPackage,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Condition: ${vehicle.condition}',
                                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '€${vehicle.washPackagePrice.toStringAsFixed(0)}',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: isDark ? AppColors.primaryGold : const Color(0xFFD97706),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  


                  const SizedBox(height: 40),

                  // Cleaning Materials Selection
                  Text(
                    'Cleaning materials',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
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
                          child: const Icon(Icons.cleaning_services, size: 24, color: AppColors.primaryGold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bring materials', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                _materialPreference == 'Bring materials' ? '+€5.00 extra charge' : 'Use my materials (No extra charge)',
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

                  const SizedBox(height: 20),

                  // Additional Details Widget (Parking Instructions & Image Picker)
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



                  // Continue Button
                  ElevatedButton(
                    onPressed: () {
                      if (_savedVehicles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please add at least one $vName to proceed.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      double calculatedSubtotal = _savedVehicles.fold(
                        0.0,
                        (sum, vehicle) => sum + vehicle.washPackagePrice,
                      );

                      double pickupFee = _serviceMode == 'Pickup & Return' ? 10.0 * _savedVehicles.length : 0.0;

                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: fullServiceName,
                        carWashVehicles: _savedVehicles,
                        waterAccess: _waterAccess,
                        electricityAccess: _electricityAccess,
                        subtotal: calculatedSubtotal,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
                        vehicleServiceMode: _serviceMode,
                        pickupAndReturnFee: pickupFee,
                        comments: _whatYouNeedController.text.trim().isNotEmpty
                            ? _whatYouNeedController.text.trim()
                            : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty
                            ? _describeIssueController.text.trim()
                            : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                      );

                      context.pushNamed(
                        RouteNames.quickServicesCarWashReview,
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

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
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
