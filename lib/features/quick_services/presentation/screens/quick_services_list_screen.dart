import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/quick_services_header.dart';
import '../../data/models/quick_service_booking_data.dart';

class _SubService {
  final String title;
  final IconData icon;

  const _SubService(this.title, this.icon);
}

class _ServiceCategory {
  final String title;
  final IconData icon;
  final List<_SubService> subServices;

  const _ServiceCategory(this.title, this.icon, this.subServices);
}

const List<_ServiceCategory> _categories = [
  _ServiceCategory('Home Services', Icons.home, [
    _SubService('Home Cleaning', Icons.cleaning_services),
    _SubService('Pest Control', Icons.pest_control),
    _SubService('Gardening', Icons.yard),
    _SubService('Plumbing', Icons.plumbing),
    _SubService('Carpenter', Icons.carpenter),
    _SubService('Handyman', Icons.handyman),
  ]),
  _ServiceCategory('PC & Mobile', Icons.computer, [
    _SubService('Mobile', Icons.smartphone),
    _SubService('Laptop/Computer', Icons.laptop),
    _SubService('Printer / Scanner', Icons.print),
  ]),
  _ServiceCategory('Vehicle Mechanic', Icons.directions_car, [
    _SubService('Car', Icons.directions_car),
    _SubService('Bike', Icons.two_wheeler),
    _SubService('Truck', Icons.local_shipping),
  ]),
  _ServiceCategory('Electrical Mechanic', Icons.electrical_services, [
    _SubService('Home', Icons.home_repair_service),
    _SubService('Lift / Elevator', Icons.elevator),
  ]),
  _ServiceCategory('Beautician / Wellness', Icons.spa, [
    _SubService('Male', Icons.man),
    _SubService('Female', Icons.woman),
    _SubService('Kids', Icons.child_care),
    _SubService('Others', Icons.diversity_3),
  ]),
  _ServiceCategory('AC & Appliance Repair', Icons.ac_unit, [
    _SubService('Refrigerator', Icons.kitchen),
    _SubService('Air Conditioner', Icons.ac_unit),
    _SubService('Washing Machine', Icons.local_laundry_service),
    _SubService('Television', Icons.tv),
    _SubService('Fan', Icons.air),
    _SubService('Mixer', Icons.blender),
    _SubService('Gas Stove', Icons.microwave),
    _SubService('Water Purifier', Icons.water_drop),
    _SubService('Others', Icons.miscellaneous_services),
  ]),
  _ServiceCategory('Hire a Person', Icons.person_outline, [
    _SubService('Male', Icons.man),
    _SubService('Female', Icons.woman),
    _SubService('Others', Icons.group),
  ]),
  _ServiceCategory('Security Personnel', Icons.security, [
    _SubService('Event Security', Icons.event),
    _SubService('Bouncer / Door Security', Icons.security),
    _SubService('Others', Icons.group),
  ]),

  _ServiceCategory('Laundry Worker', Icons.local_laundry_service, [
    _SubService('Home', Icons.home),
    _SubService('Hotel', Icons.hotel),
    _SubService('Hospital', Icons.local_hospital),
    _SubService('Others', Icons.miscellaneous_services),
  ]),
  _ServiceCategory('Vehicle Wash', Icons.local_car_wash, [
    _SubService('Car', Icons.directions_car),
    _SubService('Bike', Icons.two_wheeler),
    _SubService('Truck', Icons.local_shipping),
  ]),
  _ServiceCategory('Other Services', Icons.miscellaneous_services, [
    _SubService('Painter', Icons.format_paint),
    _SubService('Event Organisers', Icons.event),
    _SubService('Suppliers', Icons.inventory),
  ]),
];

class QuickServicesListScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const QuickServicesListScreen({super.key, required this.bookingData});

  @override
  State<QuickServicesListScreen> createState() => _QuickServicesListScreenState();
}

class _QuickServicesListScreenState extends State<QuickServicesListScreen> {
  void _showSubServicesModal(BuildContext context, _ServiceCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      Icon(category.icon, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.title,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.subServices.map((subService) {
                      return GestureDetector(
                        onTap: () {
                          // We no longer set _selectedCategoryTitle so it doesn't stay highlighted
                          // when navigating back.
                          Navigator.pop(context);
                          
                          final updatedData = widget.bookingData.copyWith(selectedServiceTitle: subService.title);
                          
                          if (subService.title == 'Plumbing') {
                            context.pushNamed(RouteNames.quickServicesPlumbing, extra: updatedData);
                          } else if (subService.title == 'Carpenter') {
                            context.pushNamed(RouteNames.quickServicesCarpenter, extra: updatedData);
                          } else if (category.title == 'AC & Appliance Repair') {
                            context.pushNamed(RouteNames.quickServicesApplianceRepair, extra: updatedData);
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Bike') {
                            context.pushNamed(RouteNames.quickServicesBikeMechanic, extra: updatedData);
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Car') {
                            context.pushNamed(RouteNames.quickServicesCarMechanic, extra: updatedData);
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Truck') {
                            context.pushNamed(RouteNames.quickServicesTruckMechanic, extra: updatedData);
                          } else if (category.title == 'Electrical Mechanic' && subService.title == 'Lift / Elevator') {
                            context.pushNamed(RouteNames.quickServicesLiftElevator, extra: updatedData);
                          } else if (category.title == 'Electrical Mechanic' && subService.title == 'Home') {
                            context.pushNamed(RouteNames.quickServicesElectrical, extra: updatedData);
                          } else if (subService.title == 'Handyman' || subService.title == 'Handyman Services') {
                            context.pushNamed(RouteNames.quickServicesHandyman, extra: updatedData);
                          } else if (subService.title == 'Mobile' || subService.title == 'Mobile Repair at Home') {
                            context.pushNamed(RouteNames.quickServicesMobileRepair, extra: updatedData);
                          } else if (subService.title == 'Computer' || subService.title == 'Laptop/Computer' || subService.title == 'Computer & Laptop Repair' || subService.title == 'Computer & Laptop') {
                            context.pushNamed(RouteNames.quickServicesComputerRepair, extra: updatedData);
                          } else if (subService.title == 'Printer / Scanner') {
                            context.pushNamed(RouteNames.quickServicesPrinterScanner, extra: updatedData);
                          } else if (category.title == 'Vehicle Wash' && subService.title == 'Truck') {
                            context.pushNamed(RouteNames.quickServicesTruckWash, extra: updatedData);
                          } else if (category.title == 'Vehicle Wash' || subService.title == 'Car Wash' || subService.title == 'Car') {
                            context.pushNamed(RouteNames.quickServicesCarWash, extra: updatedData);
                          } else if (category.title == 'Laundry Worker' || subService.title == 'Laundry & Ironing' || subService.title == 'Laundry') {
                            context.pushNamed(RouteNames.quickServicesLaundry, extra: updatedData);
                          } else if (category.title == 'Beautician / Wellness' || category.title == 'Beauty & Wellness') {
                            context.pushNamed(RouteNames.quickServicesBeautyWellness, extra: updatedData);
                          } else if (subService.title == 'Gardening' || category.title == 'Gardening') {
                            context.pushNamed(RouteNames.quickServicesGardening, extra: updatedData);
                          } else if (subService.title == 'Pest Control') {
                            context.pushNamed(RouteNames.quickServicesPestControl, extra: updatedData);
                          } else if (category.title == 'Other Services' && subService.title == 'Painter') {
                            context.pushNamed(
                              RouteNames.quickServicesPainter, 
                              extra: updatedData.copyWith(selectedServiceTitle: subService.title)
                            );
                          } else if (category.title == 'Other Services' && subService.title == 'Event Organisers') {
                            context.pushNamed(
                              RouteNames.quickServicesEventOrganisers, 
                              extra: updatedData.copyWith(selectedServiceTitle: subService.title)
                            );
                          } else if (category.title == 'Other Services' && subService.title == 'Suppliers') {
                            context.pushNamed(
                              RouteNames.quickServicesSuppliers, 
                              extra: updatedData.copyWith(selectedServiceTitle: subService.title)
                            );
                          } else {
                            // Default to Home Cleaning details template
                            context.pushNamed(RouteNames.quickServicesHomeCleaning, extra: updatedData);
                          }
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 48 - 8) / 2, // 2 columns
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(subService.icon, color: const Color(0xFF324461), size: 36),
                              const SizedBox(height: 8),
                              Text(
                                subService.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Choose a Service Category',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 8) / 2;
                          final itemHeight = itemWidth / 1.5;
                          
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(
                              top: 10,
                              bottom: MediaQuery.of(context).padding.bottom + 20,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_categories.length, (index) {
                                final category = _categories[index];
                                final isLastOddItem = index == _categories.length - 1 && _categories.length % 2 != 0;
                                final width = isLastOddItem ? constraints.maxWidth : itemWidth;
                          return GestureDetector(
                            onTap: () {
                              if (category.title == 'AC & Appliance Repair') {
                                context.pushNamed(
                                  RouteNames.quickServicesApplianceRepair,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: null),
                                );
                              } else if (category.title == 'Hire a Person') {
                                context.pushNamed(
                                  RouteNames.quickServicesHirePerson,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: 'Hire a Person'),
                                );
                              } else if (category.title == 'Security Personnel' || category.title == 'Security / Bouncer') {
                                context.pushNamed(
                                  RouteNames.quickServicesSecurityPersonnel,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: 'Security Personnel'),
                                );
                              } else if (category.title == 'Mobile Repair at Home') {
                                context.pushNamed(
                                  RouteNames.quickServicesMobileRepair,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: 'Mobile Repair at Home'),
                                );
                              } else if (category.title == 'Computer & Laptop Repair' || category.title == 'Computer & Laptop') {
                                context.pushNamed(
                                  RouteNames.quickServicesComputerRepair,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: 'Computer & Laptop Repair'),
                                );
                              } else if (category.title == 'Beautician / Wellness' || category.title == 'Beauty & Wellness') {
                                context.pushNamed(
                                  RouteNames.quickServicesBeautyWellness,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: 'Beauty & Wellness'),
                                );
                              } else if (category.title == 'Laundry Worker' || category.title == 'Laundry') {
                                context.pushNamed(
                                  RouteNames.quickServicesLaundry,
                                  extra: widget.bookingData.copyWith(selectedServiceTitle: 'Laundry & Ironing'),
                                );
                              } else {
                                _showSubServicesModal(context, category);
                              }
                            },
                            child: SizedBox(
                              width: width,
                              height: itemHeight,
                              child: _ServiceCategoryCard(
                                category: category,
                                isSelected: false,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  final _ServiceCategory category;
  final bool isSelected;

  const _ServiceCategoryCard({required this.category, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGold.withOpacity(0.1) : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(category.icon, color: isSelected ? AppColors.primaryGold : const Color(0xFF324461), size: 40),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              category.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.primaryGold : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
