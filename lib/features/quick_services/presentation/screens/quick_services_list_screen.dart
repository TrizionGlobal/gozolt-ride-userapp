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
    _SubService('Hospital', Icons.local_hospital),
    _SubService('Hotel', Icons.hotel),
    _SubService('Commercials', Icons.business),
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
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesPlumbing});
                          } else if (subService.title == 'Carpenter') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesCarpenter});
                          } else if (category.title == 'AC & Appliance Repair') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesApplianceRepair});
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Bike') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesBikeMechanic});
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Car') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesCarMechanic});
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Truck') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesTruckMechanic});
                          } else if (category.title == 'Electrical Mechanic' && subService.title == 'Lift / Elevator') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesLiftElevator});
                          } else if (category.title == 'Electrical Mechanic' && subService.title == 'Home') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesElectrical});
                          } else if (subService.title == 'Handyman' || subService.title == 'Handyman Services') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesHandyman});
                          } else if (subService.title == 'Mobile' || subService.title == 'Mobile Repair at Home') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesMobileRepair});
                          } else if (subService.title == 'Computer' || subService.title == 'Laptop/Computer' || subService.title == 'Computer & Laptop Repair' || subService.title == 'Computer & Laptop') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesComputerRepair});
                          } else if (subService.title == 'Printer / Scanner') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesPrinterScanner});
                          } else if (category.title == 'Vehicle Wash' && subService.title == 'Truck') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesTruckWash});
                          } else if (category.title == 'Vehicle Wash' || subService.title == 'Car Wash' || subService.title == 'Car') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesCarWash});
                          } else if (category.title == 'Laundry Worker' || subService.title == 'Laundry & Ironing' || subService.title == 'Laundry') {
                            if (subService.title == 'Home' || subService.title == 'Laundry & Ironing' || subService.title == 'Laundry') {
                              context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesLaundry});
                            } else if (subService.title == 'Hospital') {
                              context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesHospitalLaundry});
                            } else if (subService.title == 'Hotel') {
                              context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesHotelLaundry});
                            } else if (subService.title == 'Commercials') {
                              context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesCommercialLaundry});
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Coming Soon!'),
                                  content: Text('${subService.title} laundry services are coming soon.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else if (category.title == 'Beautician / Wellness' || category.title == 'Beauty & Wellness') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesBeautyWellness});
                          } else if (subService.title == 'Gardening' || category.title == 'Gardening') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesGardening});
                          } else if (subService.title == 'Pest Control') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesPestControl});
                          } else if (category.title == 'Other Services' && subService.title == 'Painter') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData.copyWith(selectedServiceTitle: subService.title), 'nextRoute': RouteNames.quickServicesPainter});
                          } else if (category.title == 'Other Services' && subService.title == 'Event Organisers') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData.copyWith(selectedServiceTitle: subService.title), 'nextRoute': RouteNames.quickServicesEventOrganisers});
                          } else if (category.title == 'Other Services' && subService.title == 'Suppliers') {
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData.copyWith(selectedServiceTitle: subService.title), 'nextRoute': RouteNames.quickServicesSuppliers});
                          } else {
                            // Default to Home Cleaning details template
                            context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': updatedData, 'nextRoute': RouteNames.quickServicesHomeCleaning});
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
                                context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': widget.bookingData.copyWith(selectedServiceTitle: null), 'nextRoute': RouteNames.quickServicesApplianceRepair});
                              } else if (category.title == 'Hire a Person') {
                                context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': widget.bookingData.copyWith(selectedServiceTitle: 'Hire a Person'), 'nextRoute': RouteNames.quickServicesHirePerson});
                              } else if (category.title == 'Security Personnel' || category.title == 'Security / Bouncer') {
                                context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': widget.bookingData.copyWith(selectedServiceTitle: 'Security Personnel'), 'nextRoute': RouteNames.quickServicesSecurityPersonnel});
                              } else if (category.title == 'Mobile Repair at Home') {
                                context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': widget.bookingData.copyWith(selectedServiceTitle: 'Mobile Repair at Home'), 'nextRoute': RouteNames.quickServicesMobileRepair});
                              } else if (category.title == 'Computer & Laptop Repair' || category.title == 'Computer & Laptop') {
                                context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': widget.bookingData.copyWith(selectedServiceTitle: 'Computer & Laptop Repair'), 'nextRoute': RouteNames.quickServicesComputerRepair});
                              } else if (category.title == 'Beautician / Wellness' || category.title == 'Beauty & Wellness') {
                                context.pushNamed(RouteNames.quickServicesLocation, extra: {'bookingData': widget.bookingData.copyWith(selectedServiceTitle: 'Beauty & Wellness'), 'nextRoute': RouteNames.quickServicesBeautyWellness});
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
