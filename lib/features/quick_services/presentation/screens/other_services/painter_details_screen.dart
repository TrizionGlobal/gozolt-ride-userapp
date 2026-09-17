import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_additional_details.dart';

class PainterDetailsScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const PainterDetailsScreen({super.key, required this.bookingData});

  @override
  State<PainterDetailsScreen> createState() => _PainterDetailsScreenState();
}

class _PainterDetailsScreenState extends State<PainterDetailsScreen> {
  final TextEditingController _describeIssueController = TextEditingController();
  final TextEditingController _whatYouNeedController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  String? _propertyType;
  final List<String> _propertyTypes = ['Apartment', 'House', 'Office', 'Shop', 'Other'];

  final List<String> _paintingAreasList = ['Interior Walls', 'Exterior Walls', 'Ceiling', 'Doors / Windows', 'Other'];
  final List<String> _selectedPaintingAreas = [];

  int _roomCount = 1;
  String? _paintArrangement;

  @override
  void initState() {
    super.initState();
    if (widget.bookingData.whatYouNeed != null) {
      _whatYouNeedController.text = widget.bookingData.whatYouNeed!;
    }
    if (widget.bookingData.describeIssue != null) {
      _describeIssueController.text = widget.bookingData.describeIssue!;
    }
    if (widget.bookingData.propertyType != null) {
      _propertyType = widget.bookingData.propertyType;
    }
    if (widget.bookingData.paintingAreas != null) {
      _selectedPaintingAreas.addAll(widget.bookingData.paintingAreas!);
    }
    if (widget.bookingData.roomCount != null) {
      _roomCount = widget.bookingData.roomCount!;
    }
    if (widget.bookingData.paintProvided != null) {
      _paintArrangement = widget.bookingData.paintProvided! ? 'Painter Brings Paint' : 'Customer Provides Paint';
    }
    if (widget.bookingData.uploadedImages != null) {
      _selectedImages.addAll(widget.bookingData.uploadedImages!.map((path) => XFile(path)));
    }
  }

  @override
  void dispose() {
    _describeIssueController.dispose();
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


  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Matches screenshot background
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Service Requirements',
            subtitle: 'Painter',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    title: 'Property Type',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _propertyTypes.map((type) {
                        final isSelected = _propertyType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _propertyType = selected ? type : null);
                          },
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: Colors.transparent,
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? Colors.black : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryGold : Colors.grey.shade400,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                  ),

                  _buildCard(
                    title: 'Painting Area',
                    child: Column(
                      children: _paintingAreasList.map((area) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (_selectedPaintingAreas.contains(area)) {
                                _selectedPaintingAreas.remove(area);
                              } else {
                                _selectedPaintingAreas.add(area);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _selectedPaintingAreas.contains(area),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedPaintingAreas.add(area);
                                        } else {
                                          _selectedPaintingAreas.remove(area);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.primaryGold,
                                    checkColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(area, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  _buildCard(
                    title: 'Number of Rooms / Areas',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () {
                                  if (_roomCount > 1) setState(() => _roomCount--);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text('$_roomCount', style: AppTextStyles.titleMedium),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () {
                                  setState(() => _roomCount++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildCard(
                    title: 'Paint Arrangement',
                    child: Column(
                      children: ['Customer Provides Paint', 'Painter Brings Paint'].map((text) {
                        return InkWell(
                          onTap: () => setState(() => _paintArrangement = text),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Radio<String>(
                                    value: text,
                                    groupValue: _paintArrangement,
                                    onChanged: (val) => setState(() => _paintArrangement = val),
                                    activeColor: AppColors.primaryGold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(text, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

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

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_propertyType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a property type')));
                        return;
                      }
                      if (_selectedPaintingAreas.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one painting area')));
                        return;
                      }
                      
                      final updatedData = widget.bookingData.copyWith(
                        selectedServiceTitle: 'Painter',
                        propertyType: _propertyType,
                        paintingAreas: _selectedPaintingAreas,
                        roomCount: _roomCount,
                        paintProvided: _paintArrangement == 'Painter Brings Paint',
                        whatYouNeed: _whatYouNeedController.text.trim().isNotEmpty ? _whatYouNeedController.text.trim() : null,
                        describeIssue: _describeIssueController.text.trim().isNotEmpty ? _describeIssueController.text.trim() : null,
                        uploadedImages: _selectedImages.map((e) => e.path).toList(),
                        subtotal: 0.0,
                        baseEstimatedHours: (_roomCount * 2.0),
                      );

                      context.pushNamed(
                        RouteNames.quickServicesOtherServicesReview,
                        extra: updatedData,
                      );
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
