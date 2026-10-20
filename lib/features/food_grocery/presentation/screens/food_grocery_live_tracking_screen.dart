import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../providers/food_grocery_order_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../providers/food_grocery_delivery_verification_provider.dart';
import '../providers/food_grocery_payment_provider.dart';

class FoodGroceryLiveTrackingScreen extends ConsumerStatefulWidget {
  const FoodGroceryLiveTrackingScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryLiveTrackingScreen> createState() =>
      _FoodGroceryLiveTrackingScreenState();
}

class _FoodGroceryLiveTrackingScreenState
    extends ConsumerState<FoodGroceryLiveTrackingScreen> {
  bool _isRefreshing = false;

  Future<void> _advanceTracking() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    await ref
        .read(foodGroceryOrderProvider.notifier)
        .advanceTemporaryTracking();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshing = false;
    });
  }

  void _continueToArrival() {
    final order = ref.read(
      foodGroceryOrderProvider,
    );

    final payment = ref.read(
      foodGroceryPaymentProvider,
    );

    ref
        .read(
          foodGroceryDeliveryVerificationProvider.notifier,
        )
        .initialiseTemporaryDelivery(
          orderId: order.orderId ?? 'Pending',
          amount: order.total,
          isCash: payment.isCash,
        );

    context.pushNamed(
      RouteNames.foodGroceryDeliveryArrival,
    );
  }

  void _showContactMessage(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$action will be connected to the '
            'assigned delivery partner.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryGoldDark,
        ),
      );
  }

  String _estimatedArrival(
    FoodGroceryTrackingStage stage,
  ) {
    switch (stage) {
      case FoodGroceryTrackingStage.supplierAccepted:
        return '35–45 min';
      case FoodGroceryTrackingStage.preparing:
        return '30–40 min';
      case FoodGroceryTrackingStage.readyForPickup:
        return '25–35 min';
      case FoodGroceryTrackingStage.pickedUp:
        return '20–30 min';
      case FoodGroceryTrackingStage.onTheWay:
        return '10–20 min';
      case FoodGroceryTrackingStage.arrivingSoon:
        return '2–5 min';
    }
  }

  bool _partnerAssigned(
    FoodGroceryTrackingStage stage,
  ) {
    return stage.index >= FoodGroceryTrackingStage.pickedUp.index;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final order = ref.watch(
      foodGroceryOrderProvider,
    );

    final cart = ref.watch(
      foodGroceryCartProvider,
    );

    final delivery = ref.watch(
      foodGroceryDeliveryProvider,
    );

    final supplierName = cart.supplierName ?? 'Selected supplier';

    final deliveryAddress =
        delivery.selectedAddress?.fullAddress ?? 'Selected delivery address';

    final deliveryLatitude = delivery.selectedAddress?.latitude;

    final deliveryLongitude = delivery.selectedAddress?.longitude;

    if (!order.isSupplierAccepted) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            const FoodGroceryHeader(
              title: 'Live Order Tracking',
            ),
            Expanded(
              child: _MissingTrackingView(
                isDark: isDark,
              ),
            ),
          ],
        ),
      );
    }

    final eta = _estimatedArrival(
      order.trackingStage,
    );

    final partnerAssigned = _partnerAssigned(
      order.trackingStage,
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Live Order Tracking',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _TrackingMapPlaceholder(
                    isDark: isDark,
                    stage: order.trackingStage,
                    supplierName: supplierName,
                    deliveryAddress: deliveryAddress,
                    deliveryLatitude: deliveryLatitude,
                    deliveryLongitude: deliveryLongitude,
                  ),
                  const SizedBox(height: 12),
                  _CurrentStatusCard(
                    isDark: isDark,
                    order: order,
                    eta: eta,
                  ),
                  const SizedBox(height: 12),
                  _TrackingTimelineCard(
                    isDark: isDark,
                    currentStage: order.trackingStage,
                  ),
                  const SizedBox(height: 12),
                  _DeliveryPartnerCard(
                    isDark: isDark,
                    assigned: partnerAssigned,
                    onCall: () {
                      _showContactMessage(
                        'Calling',
                      );
                    },
                    onMessage: () {
                      _showContactMessage(
                        'Messaging',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _OrderReferenceCard(
                    isDark: isDark,
                    orderId: order.orderId ?? 'Pending',
                    supplierName: supplierName,
                    total: order.total,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: SizedBox(
            height: 50,
            child: order.isArrivingSoon
                ? ElevatedButton(
                    onPressed: _continueToArrival,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DELIVERY ARRIVAL',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  )
                : OutlinedButton(
                    onPressed: _isRefreshing ? null : _advanceTracking,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                      foregroundColor: AppColors.primaryGold,
                      side: const BorderSide(
                        color: AppColors.primaryGold,
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGold,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                'REFRESH LIVE STATUS',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TrackingMapPlaceholder extends StatelessWidget {
  const _TrackingMapPlaceholder({
    required this.isDark,
    required this.stage,
    required this.supplierName,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
  });

  final bool isDark;
  final FoodGroceryTrackingStage stage;
  final String supplierName;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  // TODO(FOOD_GROCERY_API):
  // Replace this temporary supplier location with coordinates
  // returned by the selected restaurant/store API.
  static const LatLng _temporarySupplierLocation = LatLng(
    35.8992,
    14.5141,
  );

  // Used only when a manually entered address does not yet
  // contain coordinates.
  static const LatLng _maltaDeliveryFallback = LatLng(
    35.9122,
    14.5042,
  );

  LatLng get _customerLocation {
    final latitude = deliveryLatitude;
    final longitude = deliveryLongitude;

    if (latitude == null || longitude == null) {
      return _maltaDeliveryFallback;
    }

    return LatLng(
      latitude,
      longitude,
    );
  }

  bool get _showDeliveryPartner {
    return stage.index >= FoodGroceryTrackingStage.pickedUp.index;
  }

  double get _deliveryProgress {
    switch (stage) {
      case FoodGroceryTrackingStage.supplierAccepted:
        return 0;
      case FoodGroceryTrackingStage.preparing:
        return 0.03;
      case FoodGroceryTrackingStage.readyForPickup:
        return 0.08;
      case FoodGroceryTrackingStage.pickedUp:
        return 0.20;
      case FoodGroceryTrackingStage.onTheWay:
        return 0.62;
      case FoodGroceryTrackingStage.arrivingSoon:
        return 0.90;
    }
  }

  LatLng get _deliveryPartnerLocation {
    final customer = _customerLocation;
    final progress = _deliveryProgress;

    final latitude = _temporarySupplierLocation.latitude +
        (customer.latitude - _temporarySupplierLocation.latitude) * progress;

    final longitude = _temporarySupplierLocation.longitude +
        (customer.longitude - _temporarySupplierLocation.longitude) * progress;

    return LatLng(
      latitude,
      longitude,
    );
  }

  LatLng get _cameraTarget {
    final customer = _customerLocation;

    return LatLng(
      (_temporarySupplierLocation.latitude + customer.latitude) / 2,
      (_temporarySupplierLocation.longitude + customer.longitude) / 2,
    );
  }

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId(
          'supplier',
        ),
        position: _temporarySupplierLocation,
        infoWindow: InfoWindow(
          title: supplierName,
          snippet: 'Pickup location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
      ),
      Marker(
        markerId: const MarkerId(
          'customer',
        ),
        position: _customerLocation,
        infoWindow: InfoWindow(
          title: 'Delivery address',
          snippet: deliveryAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    };

    if (_showDeliveryPartner) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'delivery-partner',
          ),
          position: _deliveryPartnerLocation,
          infoWindow: const InfoWindow(
            title: 'GOZOLT delivery partner',
            snippet: 'Delivering your order',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    return {
      Polyline(
        polylineId: const PolylineId(
          'delivery-route',
        ),
        points: [
          _temporarySupplierLocation,
          _customerLocation,
        ],
        color: AppColors.primaryGold,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraTarget,
                zoom: 13.2,
              ),
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              compassEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              buildingsEnabled: true,
              trafficEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.90)
                    : Colors.white.withValues(
                        alpha: 0.92,
                      ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.circle,
                    size: 8,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (deliveryLatitude == null || deliveryLongitude == null)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark.withValues(alpha: 0.92)
                      : Colors.white.withValues(
                          alpha: 0.94,
                        ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Demo Malta location shown until '
                        'address coordinates are available.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({
    required this.isDark,
    required this.order,
    required this.eta,
  });

  final bool isDark;
  final FoodGroceryOrderState order;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _stageIcon(
                order.trackingStage,
              ),
              size: 24,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.trackingTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.trackingDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                eta,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ETA',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _stageIcon(
    FoodGroceryTrackingStage stage,
  ) {
    switch (stage) {
      case FoodGroceryTrackingStage.supplierAccepted:
        return Icons.check_circle_outline_rounded;
      case FoodGroceryTrackingStage.preparing:
        return Icons.restaurant_rounded;
      case FoodGroceryTrackingStage.readyForPickup:
        return Icons.inventory_2_outlined;
      case FoodGroceryTrackingStage.pickedUp:
        return Icons.shopping_bag_outlined;
      case FoodGroceryTrackingStage.onTheWay:
        return Icons.delivery_dining_rounded;
      case FoodGroceryTrackingStage.arrivingSoon:
        return Icons.near_me_rounded;
    }
  }
}

class _TrackingTimelineCard extends StatelessWidget {
  const _TrackingTimelineCard({
    required this.isDark,
    required this.currentStage,
  });

  final bool isDark;
  final FoodGroceryTrackingStage currentStage;

  @override
  Widget build(BuildContext context) {
    const stages = FoodGroceryTrackingStage.values;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER PROGRESS',
            style: AppTextStyles.labelSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 15),
          for (var index = 0; index < stages.length; index++)
            _TimelineStep(
              isDark: isDark,
              stage: stages[index],
              completed: index < currentStage.index,
              active: index == currentStage.index,
              showLine: index < stages.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.isDark,
    required this.stage,
    required this.completed,
    required this.active,
    required this.showLine,
  });

  final bool isDark;
  final FoodGroceryTrackingStage stage;
  final bool completed;
  final bool active;
  final bool showLine;

  String get title {
    switch (stage) {
      case FoodGroceryTrackingStage.supplierAccepted:
        return 'Order accepted';
      case FoodGroceryTrackingStage.preparing:
        return 'Preparing order';
      case FoodGroceryTrackingStage.readyForPickup:
        return 'Ready for pickup';
      case FoodGroceryTrackingStage.pickedUp:
        return 'Order collected';
      case FoodGroceryTrackingStage.onTheWay:
        return 'On the way';
      case FoodGroceryTrackingStage.arrivingSoon:
        return 'Arriving soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = completed || active;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.success
                        : active
                            ? AppColors.primaryGold
                            : isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                    shape: BoxShape.circle,
                  ),
                  child: completed
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : active
                          ? const Icon(
                              Icons.circle_rounded,
                              size: 9,
                              color: AppColors.backgroundDark,
                            )
                          : null,
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(
                        minHeight: 22,
                      ),
                      color: highlighted
                          ? AppColors.primaryGold
                          : isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 3,
                bottom: 18,
              ),
              child: Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: highlighted
                      ? isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight
                      : isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPartnerCard extends StatelessWidget {
  const _DeliveryPartnerCard({
    required this.isDark,
    required this.assigned,
    required this.onCall,
    required this.onMessage,
  });

  final bool isDark;
  final bool assigned;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.primaryGold.withValues(alpha: 0.15),
            child: Icon(
              assigned ? Icons.person_rounded : Icons.person_search_outlined,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assigned
                      ? 'Delivery partner assigned'
                      : 'Finding a delivery partner',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  assigned
                      ? 'GOZOLT delivery partner'
                      : 'Partner details will appear here',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (assigned) ...[
            _ContactButton(
              icon: Icons.call_outlined,
              onTap: onCall,
            ),
            const SizedBox(width: 7),
            _ContactButton(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onMessage,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withValues(alpha: 0.13),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19,
          color: AppColors.primaryGold,
        ),
      ),
    );
  }
}

class _OrderReferenceCard extends StatelessWidget {
  const _OrderReferenceCard({
    required this.isDark,
    required this.orderId,
    required this.supplierName,
    required this.total,
  });

  final bool isDark;
  final String orderId;
  final String supplierName;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _ReferenceRow(
            isDark: isDark,
            label: 'Order reference',
            value: orderId,
          ),
          const SizedBox(height: 10),
          _ReferenceRow(
            isDark: isDark,
            label: 'Supplier',
            value: supplierName,
          ),
          const SizedBox(height: 10),
          _ReferenceRow(
            isDark: isDark,
            label: 'Total',
            value: '€${total.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({
    required this.isDark,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingTrackingView extends StatelessWidget {
  const _MissingTrackingView({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching_rounded,
              size: 54,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 14),
            Text(
              'Tracking is not available yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Live tracking becomes available after '
              'the supplier accepts your order.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

