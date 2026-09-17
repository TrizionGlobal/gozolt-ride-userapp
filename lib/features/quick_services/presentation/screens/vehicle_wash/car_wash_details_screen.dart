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
  String? _selectedVehicleType;
  String? _selectedVehicleMake;
  String? _selectedVehicleModel;
  String? _selectedColour;
  String? _selectedWashPackage;
  double _selectedPackagePrice = 0.0;
  int _vehicleCount = 1;
  String? _selectedCondition;
  String? _waterAccess;
  String? _electricityAccess;

  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _customVehicleTypeController = TextEditingController();
  final TextEditingController _customMakeController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  final TextEditingController _customColourController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final TextEditingController _describeIssueController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _vehicleTypes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Convertible',
    'Crossover',
    'Van / Minivan',
    'Other',
  ];

  final List<String> _vehicleMakes = [
    'Toyota',
    'Honda',
    'BMW',
    'Mercedes',
    'Audi',
    'Ford',
    'Volkswagen',
    'Hyundai',
    'Other',
  ];

  static const Map<String, List<String>> _makeModelsMap = {
    'Toyota': ['Corolla', 'Camry', 'RAV4', 'Yaris', 'Other Model'],
    'Honda': ['Civic', 'Accord', 'CR-V', 'Fit', 'Other Model'],
    'BMW': ['3 Series', '5 Series', 'X3', 'X5', 'Other Model'],
    'Mercedes': ['C-Class', 'E-Class', 'GLC', 'A-Class', 'Other Model'],
    'Audi': ['A4', 'A6', 'Q5', 'Q3', 'Other Model'],
    'Ford': ['Focus', 'Fiesta', 'Mustang', 'Explorer', 'Other Model'],
    'Volkswagen': ['Golf', 'Polo', 'Passat', 'Tiguan', 'Other Model'],
    'Hyundai': ['Tucson', 'i30', 'Elantra', 'Santa Fe', 'Other Model'],
    'Other': ['Other Model'],
  };

  List<String> get _currentModels =>
      _selectedVehicleMake != null ? (_makeModelsMap[_selectedVehicleMake] ?? const ['Other Model']) : const [];

  final List<String> _colours = [
    'Black',
    'White',
    'Silver',
    'Grey',
    'Blue',
    'Red',
    'Other',
  ];

  final List<Map<String, dynamic>> _washPackages = [
    {'title': 'Exterior Wash', 'price': 15.0, 'displayPrice': '€15'},
    {'title': 'Interior Cleaning', 'price': 18.0, 'displayPrice': '€18'},
    {'title': 'Full Wash', 'price': 30.0, 'displayPrice': '€30'},
  ];

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
    _registrationController.dispose();
    _customVehicleTypeController.dispose();
    _customMakeController.dispose();
    _customModelController.dispose();
    _customColourController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentModels = _currentModels;
    if (_selectedVehicleMake != null && _selectedVehicleModel != null && !currentModels.contains(_selectedVehicleModel)) {
      _selectedVehicleModel = currentModels.isNotEmpty ? currentModels.first : null;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Vehicle & Wash Details',
            subtitle: 'Car Wash',
          ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Type
                  Text(
                    'Vehicle Type',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    hint: Text('Select Vehicle Type', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                    decoration: _inputDecoration(),
                    items: _vehicleTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (val) => setState(() => _selectedVehicleType = val),
                  ),
                  if (_selectedVehicleType == 'Other') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customVehicleTypeController,
                      style: AppTextStyles.bodyMedium,
                      decoration: _inputDecoration(hintText: 'Enter Vehicle Type (e.g. RV, Bus, ATV)'),
                    ),
                  ],

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
                              'Vehicle Make',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedVehicleMake,
                              hint: Text('Select Make', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                              decoration: _inputDecoration(),
                              items: _vehicleMakes.map((make) => DropdownMenuItem(value: make, child: Text(make, style: AppTextStyles.bodyMedium))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedVehicleMake = val;
                                    final models = _makeModelsMap[_selectedVehicleMake] ?? ['Other Model'];
                                    _selectedVehicleModel = models.first;
                                  });
                                }
                              },
                            ),
                            if (_selectedVehicleMake == 'Other') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customMakeController,
                                style: AppTextStyles.bodyMedium,
                                decoration: _inputDecoration(hintText: 'Enter Make (e.g. Tesla)'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Model',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedVehicleModel,
                              hint: Text('Select Model', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                              decoration: _inputDecoration(),
                              items: currentModels.map((model) => DropdownMenuItem(value: model, child: Text(model, style: AppTextStyles.bodyMedium))).toList(),
                              onChanged: (val) => setState(() => _selectedVehicleModel = val),
                            ),
                            if (_selectedVehicleModel == 'Other' || _selectedVehicleModel == 'Other Model') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customModelController,
                                style: AppTextStyles.bodyMedium,
                                decoration: _inputDecoration(hintText: 'Enter Model (e.g. Model Y)'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Colour & Registration Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Colour',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedColour,
                              hint: Text('Select Colour', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                              decoration: _inputDecoration(),
                              items: _colours.map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.bodyMedium))).toList(),
                              onChanged: (val) => setState(() => _selectedColour = val),
                            ),
                            if (_selectedColour == 'Other') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customColourController,
                                style: AppTextStyles.bodyMedium,
                                decoration: _inputDecoration(hintText: 'Enter Colour (e.g. Gold)'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registration Number',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _registrationController,
                              style: AppTextStyles.bodyMedium,
                              decoration: _inputDecoration(hintText: 'e.g. ABC 123'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Select Wash Package
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Select Wash Package',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Vehicles: ', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700])),
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
                                    if (_vehicleCount > 1) {
                                      setState(() => _vehicleCount--);
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
                                    '$_vehicleCount',
                                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() => _vehicleCount++);
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
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Package options
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
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                displayPrice,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? (isDark ? AppColors.primaryGold : Colors.black) : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Vehicle Condition
                  Text(
                    'Vehicle Condition',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vehicleConditions.map((cond) {
                      final isSelected = _selectedCondition == cond;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCondition = cond),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.amber.shade900.withOpacity(0.3) : const Color(0xFFFFF8E1))
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cond,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? (isDark ? AppColors.primaryGold : const Color(0xFFD97706)) : null,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 14, color: AppColors.primaryGold),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // On-Site Facilities
                  Text(
                    'On-Site Facilities',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Water Access
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Water Access',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: ['Available', 'Not Available'].map((opt) {
                            final isSelected = _waterAccess == opt;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _waterAccess = opt),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? Colors.amber.shade900.withOpacity(0.3) : const Color(0xFFFFF8E1))
                                        : Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        opt,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? (isDark ? AppColors.primaryGold : const Color(0xFFD97706)) : null,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.check_circle, size: 14, color: AppColors.primaryGold),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Electricity Access
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Electricity Access',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: ['Available', 'Not Available'].map((opt) {
                            final isSelected = _electricityAccess == opt;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _electricityAccess = opt),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? Colors.amber.shade900.withOpacity(0.3) : const Color(0xFFFFF8E1))
                                        : Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        opt,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? (isDark ? AppColors.primaryGold : const Color(0xFFD97706)) : null,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.check_circle, size: 14, color: AppColors.primaryGold),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
                            'Final price may change for heavy dirt, stains or additional work.',
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
                      final finalVehicleType = _selectedVehicleType == 'Other' && _customVehicleTypeController.text.trim().isNotEmpty
                          ? _customVehicleTypeController.text.trim()
                          : _selectedVehicleType;
                      final finalMake = _selectedVehicleMake == 'Other' && _customMakeController.text.trim().isNotEmpty
                          ? _customMakeController.text.trim()
                          : _selectedVehicleMake;
                      final finalModel = (_selectedVehicleModel == 'Other' || _selectedVehicleModel == 'Other Model') && _customModelController.text.trim().isNotEmpty
                          ? _customModelController.text.trim()
                          : _selectedVehicleModel;
                      final finalColour = _selectedColour == 'Other' && _customColourController.text.trim().isNotEmpty
                          ? _customColourController.text.trim()
                          : _selectedColour;

                      final calculatedSubtotal = _selectedPackagePrice * _vehicleCount;
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Car Wash',
                        carType: finalVehicleType,
                        vehicleMake: finalMake,
                        vehicleModel: finalModel,
                        vehicleColour: finalColour,
                        vehicleRegistration: _registrationController.text.trim().isNotEmpty
                            ? _registrationController.text.trim()
                            : null,
                        carWashPackage: _selectedWashPackage,
                        carWashPackagePrice: _selectedPackagePrice,
                        vehicleCount: _vehicleCount,
                        vehicleCondition: _selectedCondition,
                        waterAccess: _waterAccess,
                        electricityAccess: _electricityAccess,
                        subtotal: 0.0,
                        baseEstimatedHours: 0.0,
                        materialPreference: _materialPreference,
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
