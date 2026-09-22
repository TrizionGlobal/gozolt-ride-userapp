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
  final String? iconPath;

  const _SubService(this.title, this.icon, {this.iconPath});
}

class _ServiceCategory {
  final String title;
  final IconData icon;
  final String? iconPath;
  final List<_SubService> subServices;

  const _ServiceCategory(this.title, this.icon, this.subServices, {this.iconPath});
}

const List<_ServiceCategory> _categories = [
  _ServiceCategory('Home Services', Icons.home_repair_service, iconPath: 'assets/images/updated_userapp_images/quick_services_images/home_service.png', [
    _SubService('Home Cleaning', Icons.cleaning_services, iconPath: 'assets/images/updated_userapp_images/quick_services_images/home_cleaning.png'),
    _SubService('Pest Control', Icons.pest_control, iconPath: 'assets/images/updated_userapp_images/quick_services_images/pest_control.png'),
    _SubService('Gardening', Icons.yard, iconPath: 'assets/images/updated_userapp_images/quick_services_images/gardening.png'),
    _SubService('Plumbing', Icons.plumbing, iconPath: 'assets/images/updated_userapp_images/quick_services_images/plumber.png'),
    _SubService('Carpenter', Icons.carpenter, iconPath: 'assets/images/updated_userapp_images/quick_services_images/carpentar.png'),
    // _SubService('Handyman', Icons.handyman),
  ]),
  _ServiceCategory('PC & Mobile Repair', Icons.computer, iconPath: 'assets/images/updated_userapp_images/quick_services_images/pc&mobile_repair.png', [
    _SubService('Mobile', Icons.smartphone, iconPath: 'assets/images/updated_userapp_images/quick_services_images/mobile.png'),
    _SubService('Laptop/Computer', Icons.laptop, iconPath: 'assets/images/updated_userapp_images/quick_services_images/laptop.png'),
    _SubService('Printer / Scanner', Icons.print, iconPath: 'assets/images/updated_userapp_images/quick_services_images/printer.png'),
  ]),
  _ServiceCategory('Vehicle Mechanic', Icons.directions_car, iconPath: 'assets/images/updated_userapp_images/quick_services_images/vehicle_mechanic.png', [
    _SubService('Car', Icons.directions_car, iconPath: 'assets/images/updated_userapp_images/quick_services_images/car_mechanic.png'),
    _SubService('Bike', Icons.two_wheeler, iconPath: 'assets/images/updated_userapp_images/quick_services_images/bike_mechanic.png'),
    _SubService('Truck', Icons.local_shipping, iconPath: 'assets/images/updated_userapp_images/quick_services_images/truck_mechanic.png'),
  ]),
  _ServiceCategory('Vehicle Wash', Icons.local_car_wash, iconPath: 'assets/images/updated_userapp_images/quick_services_images/vehicle_wash.png', [
    _SubService('Car', Icons.directions_car, iconPath: 'assets/images/updated_userapp_images/quick_services_images/car_wash.png'),
    _SubService('Bike', Icons.two_wheeler, iconPath: 'assets/images/updated_userapp_images/quick_services_images/bike_wash.png'),
    _SubService('Truck', Icons.local_shipping, iconPath: 'assets/images/updated_userapp_images/quick_services_images/truck_wash.png'),
  ]),
  _ServiceCategory('Electrical Repair', Icons.electrical_services, iconPath: 'assets/images/updated_userapp_images/quick_services_images/electric_mechanic.png', [
    _SubService('Home', Icons.home_repair_service, iconPath: 'assets/images/updated_userapp_images/quick_services_images/home_repair.png'),
    _SubService('Commercial', Icons.business, iconPath: 'assets/images/updated_userapp_images/quick_services_images/commercial_repair.png'),
    _SubService('Events', Icons.event, iconPath: 'assets/images/updated_userapp_images/quick_services_images/events_repair.png'),
  ]),
  _ServiceCategory('Appliance Repair', Icons.ac_unit, iconPath: 'assets/images/updated_userapp_images/quick_services_images/appliances.png', [
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
  _ServiceCategory('Beautician /Wellness', Icons.spa, iconPath: 'assets/images/updated_userapp_images/quick_services_images/beautician.png', [
    _SubService('Male', Icons.man),
    _SubService('Female', Icons.woman),
    _SubService('Kids', Icons.child_care),
    _SubService('Others', Icons.diversity_3),
  ]),
  _ServiceCategory('Laundry', Icons.local_laundry_service, iconPath: 'assets/images/updated_userapp_images/quick_services_images/laundry.png', [
    _SubService('Home', Icons.home, iconPath: 'assets/images/updated_userapp_images/quick_services_images/home_laundry.png'),
    _SubService('Hospital', Icons.local_hospital, iconPath: 'assets/images/updated_userapp_images/quick_services_images/hospital_laundry.png'),
    _SubService('Hotel', Icons.hotel, iconPath: 'assets/images/updated_userapp_images/quick_services_images/hotel_laundry.png'),
    _SubService('Commercials', Icons.business, iconPath: 'assets/images/updated_userapp_images/quick_services_images/commercial_laundry.png'),
  ]),
  _ServiceCategory('Hire a Person', Icons.person_outline, iconPath: 'assets/images/updated_userapp_images/quick_services_images/hire_a_person.png', [
    _SubService('Male', Icons.man),
    _SubService('Female', Icons.woman),
    _SubService('Others', Icons.group),
  ]),
  _ServiceCategory('Security/Bouncer', Icons.security, iconPath: 'assets/images/updated_userapp_images/quick_services_images/security_personal.png', [
    _SubService('Event Security', Icons.event),
    _SubService('Bouncer / Door Security', Icons.security),
    _SubService('Others', Icons.group),
  ]),
  _ServiceCategory('Other Services', Icons.miscellaneous_services, iconPath: 'assets/images/updated_userapp_images/quick_services_images/other_services.png', [
    _SubService('Painter', Icons.format_paint, iconPath: 'assets/images/updated_userapp_images/quick_services_images/painter.png'),
    _SubService('Event Organisers', Icons.event, iconPath: 'assets/images/updated_userapp_images/quick_services_images/event_organisers.png'),
    _SubService('Suppliers', Icons.inventory, iconPath: 'assets/images/updated_userapp_images/quick_services_images/suppliers.png'),
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
                      if (category.iconPath != null)
                        Image.asset(category.iconPath!, width: 32, height: 32, fit: BoxFit.contain)
                      else
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
                          
                          final updatedData = widget.bookingData.copyWith(category: category.title, selectedServiceTitle: subService.title);
                          
                          // Determine the nextRoute for the location/schedule screen
                          String nextRoute;
                          if (subService.title == 'Plumbing') {
                            nextRoute = RouteNames.quickServicesPlumbing;
                          } else if (subService.title == 'Carpenter') {
                            nextRoute = RouteNames.quickServicesCarpenter;
                          } else if (category.title == 'Appliance Repair') {
                            nextRoute = RouteNames.quickServicesApplianceRepair;
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Bike') {
                            nextRoute = RouteNames.quickServicesBikeMechanic;
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Car') {
                            nextRoute = RouteNames.quickServicesCarMechanic;
                          } else if (category.title == 'Vehicle Mechanic' && subService.title == 'Truck') {
                            nextRoute = RouteNames.quickServicesTruckMechanic;
                          } else if (category.title == 'Electrical Repair' && (subService.title == 'Commercial' || subService.title == 'Lift / Elevator')) {
                            nextRoute = RouteNames.quickServicesLiftElevator;
                          } else if (category.title == 'Electrical Repair' && subService.title == 'Events') {
                            nextRoute = RouteNames.quickServicesEventsElectric;
                          } else if (category.title == 'Electrical Repair' && subService.title == 'Home') {
                            nextRoute = RouteNames.quickServicesElectrical;
                          } else if (subService.title == 'Handyman' || subService.title == 'Handyman Services') {
                            nextRoute = RouteNames.quickServicesHandyman;
                          } else if (subService.title == 'Mobile' || subService.title == 'Mobile Repair') {
                            nextRoute = RouteNames.quickServicesMobileRepair;
                          } else if (subService.title == 'Computer' || subService.title == 'Laptop/Computer' || subService.title == 'Computer & Laptop Repair' || subService.title == 'Computer & Laptop') {
                            nextRoute = RouteNames.quickServicesComputerRepair;
                          } else if (subService.title == 'Printer / Scanner') {
                            nextRoute = RouteNames.quickServicesPrinterScanner;
                          } else if (category.title == 'Vehicle Wash' && subService.title == 'Truck') {
                            nextRoute = RouteNames.quickServicesTruckWash;
                          } else if (category.title == 'Vehicle Wash' || subService.title == 'Car Wash' || subService.title == 'Car') {
                            nextRoute = RouteNames.quickServicesCarWash;
                          } else if (category.title == 'Laundry Worker' || category.title == 'Laundry' || subService.title == 'Laundry & Ironing' || subService.title == 'Laundry') {
                            if (subService.title == 'Hospital') {
                              nextRoute = RouteNames.quickServicesHospitalLaundry;
                            } else if (subService.title == 'Hotel') {
                              nextRoute = RouteNames.quickServicesHotelLaundry;
                            } else if (subService.title == 'Commercials') {
                              nextRoute = RouteNames.quickServicesCommercialLaundry;
                            } else {
                              nextRoute = RouteNames.quickServicesLaundry;
                            }
                          } else if (category.title == 'Beautician /Wellness') {
                            nextRoute = RouteNames.quickServicesBeautyWellness;
                          } else if (subService.title == 'Gardening' || category.title == 'Gardening') {
                            nextRoute = RouteNames.quickServicesGardening;
                          } else if (subService.title == 'Pest Control') {
                            nextRoute = RouteNames.quickServicesPestControl;
                          } else if (category.title == 'Other Services' && subService.title == 'Painter') {
                            nextRoute = RouteNames.quickServicesPainter;
                          } else if (category.title == 'Other Services' && subService.title == 'Event Organisers') {
                            nextRoute = RouteNames.quickServicesEventOrganisers;
                          } else if (category.title == 'Other Services' && subService.title == 'Suppliers') {
                            nextRoute = RouteNames.quickServicesSuppliers;
                          } else if (category.title == 'Security / Bouncer' || category.title == 'Security Personnel' || subService.title == 'Security / Bouncer') {
                            nextRoute = RouteNames.quickServicesSecurityPersonnel;
                          } else if (category.title == 'Hire Person' || subService.title == 'Hire Person') {
                            nextRoute = RouteNames.quickServicesHirePerson;
                          } else {
                            nextRoute = RouteNames.quickServicesHomeCleaning;
                          }

                          // Always go through location & schedule screen first
                          context.pushNamed(
                            RouteNames.quickServicesLocation,
                            extra: {
                              'bookingData': updatedData,
                              'nextRoute': nextRoute,
                            },
                          );
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
                              if (subService.iconPath != null)
                                Image.asset(
                                  subService.iconPath!, 
                                  width: (category.title == 'Vehicle Mechanic' || category.title == 'Vehicle Wash') ? 60 : 42, 
                                  height: (category.title == 'Vehicle Mechanic' || category.title == 'Vehicle Wash') ? 60 : 42, 
                                  fit: BoxFit.contain,
                                )
                              else
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
                              if (category.title == 'Appliance Repair') {
                                context.pushNamed(RouteNames.quickServicesApplianceRepair, extra: widget.bookingData.copyWith(category: category.title, selectedServiceTitle: null));
                              } else if (category.title == 'Hire a Person') {
                                context.pushNamed(RouteNames.quickServicesHirePerson, extra: widget.bookingData.copyWith(category: category.title, selectedServiceTitle: 'Hire a Person'));
                              } else if (category.title == 'Security/Bouncer') {
                                context.pushNamed(RouteNames.quickServicesSecurityPersonnel, extra: widget.bookingData.copyWith(category: category.title, selectedServiceTitle: 'Security Personnel'));
                              } else if (category.title == 'Mobile Repair') {
                                context.pushNamed(RouteNames.quickServicesMobileRepair, extra: widget.bookingData.copyWith(category: category.title, selectedServiceTitle: 'Mobile Repair'));
                              } else if (category.title == 'Computer & Laptop Repair' || category.title == 'Computer & Laptop') {
                                context.pushNamed(RouteNames.quickServicesComputerRepair, extra: widget.bookingData.copyWith(category: category.title, selectedServiceTitle: 'Computer & Laptop Repair'));
                              } else if (category.title == 'Beautician /Wellness') {
                                context.pushNamed(RouteNames.quickServicesBeautyWellness, extra: widget.bookingData.copyWith(category: category.title, selectedServiceTitle: 'Beauty & Wellness'));
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
          if (category.iconPath != null)
            Image.asset(
              category.iconPath!, 
              width: (category.title == 'Vehicle Mechanic' || category.title == 'Vehicle Wash') ? 75 : 50, 
              height: (category.title == 'Vehicle Mechanic' || category.title == 'Vehicle Wash') ? 60 : 50, 
              fit: BoxFit.contain
            )
          else
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
