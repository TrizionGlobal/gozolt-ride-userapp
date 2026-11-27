import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/router/route_names.dart';
import '../../data/datasources/food_grocery_remote_datasource.dart';
import 'food_grocery_delivery_chat_screen.dart';
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
  bool _isLoading = true;
  LatLng? _liveDriverLocation;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentOrder = ref.read(foodGroceryOrderProvider);
      if (currentOrder.orderId == null) {
        await ref.read(foodGroceryOrderProvider.notifier).getActiveOrder();
      } else {
        ref.read(foodGroceryOrderProvider.notifier).pollOrderStatus(currentOrder.orderId!);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final order = ref.read(foodGroceryOrderProvider);
      if (order.orderId != null && !order.isSupplierAccepted) {
        context.pushReplacementNamed(RouteNames.foodGroceryAwaitingSupplier);
        return;
      }

      _setupSubscriptions();

      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!mounted) return;
        final o = ref.read(foodGroceryOrderProvider);
        if (o.orderId != null) {
          ref.read(foodGroceryOrderProvider.notifier).pollOrderStatus(o.orderId!);
        }
      });
    });
  }

  void _setupSubscriptions() {
    final socket = ref.read(socketServiceProvider);
    _subscriptions.add(
      socket.onFoodGroceryOrderStatus.listen((data) {
        if (!mounted) return;
        final order = ref.read(foodGroceryOrderProvider);
        if (order.orderId != null) {
          ref.read(foodGroceryOrderProvider.notifier).pollOrderStatus(order.orderId!);
        }
        final statusStr = data['status']?.toString();
        if (statusStr == 'ARRIVED_AT_CUSTOMER' || statusStr == 'ARRIVING_SOON') {
          _continueToArrival();
        }
      }),
    );
    _subscriptions.add(
      socket.onFoodGroceryDriverLocation.listen((data) {
        if (!mounted) return;
        final currentOrderId = ref.read(foodGroceryOrderProvider).orderId;
        final eventOrderId =
            data['orderId']?.toString() ?? data['id']?.toString();
        if (currentOrderId != null &&
            eventOrderId != null &&
            eventOrderId != currentOrderId) {
          return;
        }
        final lat = (data['latitude'] as num?)?.toDouble() ??
            (data['lat'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble() ??
            (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() {
            _liveDriverLocation = LatLng(lat, lng);
          });
        }
      }),
    );
    _subscriptions.add(
      socket.onFoodGrocerySubstitution.listen((_) {
        if (!mounted) return;
        context.pushNamed(RouteNames.foodGrocerySubstitution);
      }),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _advanceTracking() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    final order = ref.read(foodGroceryOrderProvider);
    if (order.orderId != null) {
      await ref.read(foodGroceryOrderProvider.notifier).pollOrderStatus(order.orderId!);
    }

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

    final pin = order.orderData?['deliveryPin']?.toString();

    ref
        .read(
          foodGroceryDeliveryVerificationProvider.notifier,
        )
        .initialiseTemporaryDelivery(
          orderId: order.orderId ?? 'Pending',
          amount: order.total,
          isCash: payment.isCash,
          deliveryPin: pin,
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
      case FoodGroceryTrackingStage.awaitingSupplier:
        return '40–50 min';
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
      case FoodGroceryTrackingStage.arrivedAtCustomer:
        return 'Arrived';
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

    ref.listen<FoodGroceryOrderState>(foodGroceryOrderProvider, (_, next) {
      if (next.orderId != null && !next.isSupplierAccepted && mounted) {
        _pollTimer?.cancel();
        context.pushReplacementNamed(RouteNames.foodGroceryAwaitingSupplier);
      }
    });

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Column(
          children: [
            FoodGroceryHeader(
              title: 'Live Order Tracking',
            ),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final order = ref.watch(
      foodGroceryOrderProvider,
    );

    final cart = ref.watch(
      foodGroceryCartProvider,
    );

    final delivery = ref.watch(
      foodGroceryDeliveryProvider,
    );

    final resolvedSupplierName = order.vendorDisplayName.isNotEmpty
        ? order.vendorDisplayName
        : (order.orderData?['business']?['name'] as String? ??
            order.orderData?['businessName'] as String? ??
            cart.supplierName ??
            (order.vendorTypeLabel == 'store' ? 'Store' : 'Restaurant'));

    final structuredOrderId = order.displayBookingId.isNotEmpty
        ? order.displayBookingId
        : (order.orderId != null && order.orderId!.isNotEmpty
            ? 'GZ-FG-${order.orderId!.replaceAll('-', '').toUpperCase().substring(0, 8)}'
            : 'GZ-FG-PENDING');

    final resolvedTotal = order.total > 0
        ? order.total
        : (order.orderData?['totalAmount'] as num?)?.toDouble() ?? 0.0;

    final deliveryAddressData = order.orderData?['deliveryAddress'];
    final resolvedAddress = delivery.selectedAddress ??
        (deliveryAddressData is Map
            ? FoodGroceryRemoteDatasource.parseAddress(
                Map<String, dynamic>.from(deliveryAddressData),
              )
            : null);

    final deliveryAddress = resolvedAddress?.fullAddress ??
        order.orderData?['deliveryAddress']?['fullAddress']?.toString() ??
        'Selected delivery address';

    final deliveryLatitude = resolvedAddress?.latitude ??
        (order.orderData?['deliveryLat'] as num?)?.toDouble() ??
        (order.orderData?['deliveryAddress']?['latitude'] as num?)?.toDouble();

    final deliveryLongitude = resolvedAddress?.longitude ??
        (order.orderData?['deliveryLng'] as num?)?.toDouble() ??
        (order.orderData?['deliveryAddress']?['longitude'] as num?)?.toDouble();

    if (order.orderId == null || order.status == FoodGroceryOrderStatus.idle) {
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
                onBrowse: () {
                  context.goNamed(RouteNames.foodGroceryHome);
                },
              ),
            ),
          ],
        ),
      );
    }

    if (!order.isSupplierAccepted) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            FoodGroceryHeader(
              title: 'Order Status',
              deliveryLocation: resolvedAddress != null
                  ? (resolvedAddress.addressLine.isNotEmpty
                      ? resolvedAddress.addressLine
                      : resolvedAddress.fullAddress)
                  : null,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Connecting to ${order.vendorTypeLabel}...',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Redirecting to order status...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
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

    final businessObj = order.orderData?['business'] as Map<String, dynamic>?;
    final supplierLat = (businessObj?['latitude'] as num?)?.toDouble() ??
        (order.orderData?['businessLatitude'] as num?)?.toDouble();
    final supplierLng = (businessObj?['longitude'] as num?)?.toDouble() ??
        (order.orderData?['businessLongitude'] as num?)?.toDouble();

    final driverObj = order.orderData?['driver'] as Map<String, dynamic>?;
    final driverUser = driverObj?['user'] as Map<String, dynamic>?;
    final driverName = driverUser?['fullName'] as String? ??
        driverObj?['name'] as String? ??
        order.orderData?['driverName'] as String?;
    final driverPhone = driverUser?['phone'] as String? ??
        driverObj?['phone'] as String? ??
        order.orderData?['driverPhone'] as String?;
    final driverVehicle = driverObj?['vehicleModel'] as String? ??
        driverObj?['vehicleType'] as String? ??
        'GOZOLT Fleet Courier';

    final eta = _estimatedArrival(
      order.trackingStage,
    );

    final partnerAssigned = (driverName != null && driverName.trim().isNotEmpty) ||
        order.orderData?['driver'] != null ||
        order.orderData?['driverId'] != null ||
        _partnerAssigned(order.trackingStage);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          FoodGroceryHeader(
            title: 'Live Order Tracking',
            deliveryLocation: resolvedAddress != null
                ? (resolvedAddress.addressLine.isNotEmpty
                    ? resolvedAddress.addressLine
                    : resolvedAddress.fullAddress)
                : null,
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
                    supplierName: resolvedSupplierName,
                    deliveryAddress: deliveryAddress,
                    deliveryLatitude: deliveryLatitude,
                    deliveryLongitude: deliveryLongitude,
                    supplierLatitude: supplierLat,
                    supplierLongitude: supplierLng,
                    driverLocation: _liveDriverLocation ??
                        (order.orderData?['driverLocation'] is Map
                            ? (() {
                                final dl = Map<String, dynamic>.from(
                                  order.orderData!['driverLocation'] as Map,
                                );
                                final lat = (dl['lat'] as num?)?.toDouble() ??
                                    (dl['latitude'] as num?)?.toDouble();
                                final lng = (dl['lng'] as num?)?.toDouble() ??
                                    (dl['longitude'] as num?)?.toDouble();
                                return (lat != null && lng != null)
                                    ? LatLng(lat, lng)
                                    : null;
                              })()
                            : null),
                    hasDriverAssigned:
                        order.orderData?['driver'] != null || partnerAssigned,
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
                    driverName: driverName,
                    driverPhone: driverPhone,
                    driverVehicle: driverVehicle,
                    onCall: () async {
                      if (driverPhone != null && driverPhone.trim().isNotEmpty) {
                        final uri = Uri(scheme: 'tel', path: driverPhone.trim());
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                          return;
                        }
                      }
                      _showContactMessage(
                        'Calling',
                      );
                    },
                    onMessage: () {
                      context.pushNamed(
                        RouteNames.foodGroceryDeliveryChat,
                        extra: FoodGroceryDeliveryChatArguments(
                          orderId: structuredOrderId,
                          partnerName: driverName ?? 'Delivery Partner',
                          partnerPhone: driverPhone,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _OrderReferenceCard(
                    isDark: isDark,
                    orderId: structuredOrderId,
                    supplierName: resolvedSupplierName,
                    vendorTypeLabel: order.vendorTypeLabel,
                    total: resolvedTotal,
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

class _TrackingMapPlaceholder extends StatefulWidget {
  const _TrackingMapPlaceholder({
    required this.isDark,
    required this.stage,
    required this.supplierName,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.supplierLatitude,
    this.supplierLongitude,
    this.driverLocation,
    this.hasDriverAssigned = false,
  });

  final bool isDark;
  final FoodGroceryTrackingStage stage;
  final String supplierName;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? supplierLatitude;
  final double? supplierLongitude;
  final LatLng? driverLocation;
  final bool hasDriverAssigned;

  @override
  State<_TrackingMapPlaceholder> createState() =>
      _TrackingMapPlaceholderState();
}

class _TrackingMapPlaceholderState extends State<_TrackingMapPlaceholder>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isMapReady = false;
  List<LatLng> _routePoints = const [];
  String? _lastRouteKey;

  BitmapDescriptor? _navigatorIcon;
  late AnimationController _posController;
  late AnimationController _rotController;
  LatLng? _oldPos;
  LatLng? _newPos;
  double _oldRot = 0;
  double _newRot = 0;

  static const _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#181818"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
  ]''';

  static const LatLng _maltaDefaultSupplier = LatLng(35.8992, 14.5141);
  static const LatLng _maltaDeliveryFallback = LatLng(35.9122, 14.5042);

  LatLng get _supplierLocation {
    if (widget.supplierLatitude != null && widget.supplierLongitude != null) {
      return LatLng(widget.supplierLatitude!, widget.supplierLongitude!);
    }
    return _maltaDefaultSupplier;
  }

  LatLng get _customerLocation {
    final latitude = widget.deliveryLatitude;
    final longitude = widget.deliveryLongitude;
    if (latitude == null || longitude == null) {
      return _maltaDeliveryFallback;
    }
    return LatLng(latitude, longitude);
  }

  bool get _areLocationsNearby {
    final s = _supplierLocation;
    final c = _customerLocation;
    return (s.latitude - c.latitude).abs() < 1.5 &&
        (s.longitude - c.longitude).abs() < 1.5;
  }

  bool get _showDeliveryPartner {
    return widget.hasDriverAssigned ||
        widget.stage.index >= FoodGroceryTrackingStage.pickedUp.index ||
        widget.driverLocation != null;
  }

  double get _deliveryProgress {
    switch (widget.stage) {
      case FoodGroceryTrackingStage.awaitingSupplier:
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
      case FoodGroceryTrackingStage.arrivedAtCustomer:
        return 1.0;
    }
  }

  LatLng get _deliveryPartnerLocation {
    if (widget.driverLocation != null) {
      return widget.driverLocation!;
    }
    final supplier = _supplierLocation;
    final customer = _customerLocation;
    final progress = _deliveryProgress;
    return LatLng(
      supplier.latitude + (customer.latitude - supplier.latitude) * progress,
      supplier.longitude + (customer.longitude - supplier.longitude) * progress,
    );
  }

  LatLng get _initialCameraTarget {
    if (!_areLocationsNearby) {
      return widget.driverLocation ?? _customerLocation;
    }
    final customer = _customerLocation;
    final supplier = _supplierLocation;
    return LatLng(
      (supplier.latitude + customer.latitude) / 2,
      (supplier.longitude + customer.longitude) / 2,
    );
  }

  @override
  void initState() {
    super.initState();
    _posController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _posController.addListener(() {
      if (mounted) setState(() {});
    });
    _rotController.addListener(() {
      if (mounted) setState(() {});
    });

    if (_showDeliveryPartner) {
      _newPos = _deliveryPartnerLocation;
      _newRot = _computeBearing(
        _newPos!,
        widget.stage.index >= FoodGroceryTrackingStage.pickedUp.index
            ? _customerLocation
            : _supplierLocation,
      );
    }

    _loadNavigatorIcon();
    _fetchRouteIfNeeded();
  }

  @override
  void dispose() {
    _posController.dispose();
    _rotController.dispose();
    super.dispose();
  }

  Future<void> _loadNavigatorIcon() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/navigators/food_grocery_navigator.png',
        width: 48,
      );
      if (mounted) {
        setState(() => _navigatorIcon = icon);
      }
    } catch (e) {
      debugPrint('Error loading food_grocery_navigator.png: $e');
    }
  }

  double _computeBearing(LatLng from, LatLng to) {
    if ((from.latitude - to.latitude).abs() < 1e-6 &&
        (from.longitude - to.longitude).abs() < 1e-6) {
      return _newRot;
    }
    final lat1 = from.latitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final dLng = (to.longitude - from.longitude) * math.pi / 180.0;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  @override
  void didUpdateWidget(covariant _TrackingMapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final driverChanged =
        oldWidget.driverLocation?.latitude != widget.driverLocation?.latitude ||
            oldWidget.driverLocation?.longitude !=
                widget.driverLocation?.longitude ||
            oldWidget.stage != widget.stage ||
            oldWidget.hasDriverAssigned != widget.hasDriverAssigned;

    if (driverChanged && _showDeliveryPartner) {
      final nextPos = _deliveryPartnerLocation;
      final target = widget.stage.index >= FoodGroceryTrackingStage.pickedUp.index
          ? _customerLocation
          : _supplierLocation;
      final nextRot = _computeBearing(
        _newPos ?? nextPos,
        (_newPos != null &&
                ((_newPos!.latitude - nextPos.latitude).abs() > 1e-5 ||
                    (_newPos!.longitude - nextPos.longitude).abs() > 1e-5))
            ? nextPos
            : target,
      );

      if (_newPos == null) {
        _newPos = nextPos;
        _newRot = nextRot;
      } else {
        _oldPos = _newPos;
        _newPos = nextPos;
        _posController.forward(from: 0);

        _oldRot = _newRot;
        _newRot = nextRot;
        _rotController.forward(from: 0);
      }

      if (_isMapReady) {
        _fitCameraToBounds();
      }
    }

    if (oldWidget.deliveryLatitude != widget.deliveryLatitude ||
        oldWidget.deliveryLongitude != widget.deliveryLongitude ||
        oldWidget.supplierLatitude != widget.supplierLatitude ||
        oldWidget.supplierLongitude != widget.supplierLongitude ||
        driverChanged) {
      _fetchRouteIfNeeded();
    }
  }

  Future<void> _fitCameraToBounds() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    if (!mounted) return;

    if (!_areLocationsNearby) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          widget.driverLocation ?? _customerLocation,
          14.5,
        ),
      );
      return;
    }

    final points = <LatLng>[_supplierLocation, _customerLocation];
    if (_showDeliveryPartner) {
      points.add(_deliveryPartnerLocation);
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    if ((maxLat - minLat).abs() < 0.001 && (maxLng - minLng).abs() < 0.001) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_customerLocation, 15.0),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 52),
    );
  }

  Future<void> _fetchRouteIfNeeded() async {
    if (!_areLocationsNearby) {
      if (_routePoints.isNotEmpty && mounted) {
        setState(() => _routePoints = const []);
      }
      return;
    }

    final isBeforePickup =
        widget.stage.index < FoodGroceryTrackingStage.pickedUp.index;
    final origin = _showDeliveryPartner && widget.driverLocation != null
        ? widget.driverLocation!
        : (_showDeliveryPartner ? _deliveryPartnerLocation : _supplierLocation);
    final dest = isBeforePickup && widget.driverLocation != null
        ? _supplierLocation
        : _customerLocation;
    final routeKey =
        '${origin.latitude.toStringAsFixed(3)},${origin.longitude.toStringAsFixed(3)}_${dest.latitude.toStringAsFixed(3)},${dest.longitude.toStringAsFixed(3)}';
    if (_lastRouteKey == routeKey) return;
    _lastRouteKey = routeKey;

    try {
      final dio = Dio();
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=polyline';
      final response = await dio.get(url);
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['code'] == 'Ok' &&
          (data['routes'] as List).isNotEmpty) {
        final encoded = data['routes'][0]['geometry'] as String;
        final pts = _decodePolyline(encoded);
        if (mounted) {
          setState(() => _routePoints = pts);
        }
      }
    } catch (_) {}
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;
    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation,
        infoWindow: InfoWindow(
          title: 'Delivery address',
          snippet: widget.deliveryAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    if (_areLocationsNearby) {
      markers.add(
        Marker(
          markerId: const MarkerId('supplier'),
          position: _supplierLocation,
          infoWindow: InfoWindow(
            title: widget.supplierName,
            snippet: 'Pickup location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }

    if (_showDeliveryPartner &&
        (widget.driverLocation != null || _areLocationsNearby)) {
      final currentPos = _newPos ?? _deliveryPartnerLocation;
      final lerpPos = _oldPos != null
          ? LatLng(
              ui.lerpDouble(
                  _oldPos!.latitude, currentPos.latitude, _posController.value)!,
              ui.lerpDouble(_oldPos!.longitude, currentPos.longitude,
                  _posController.value)!,
            )
          : currentPos;
      final lerpRot =
          ui.lerpDouble(_oldRot, _newRot, _rotController.value) ?? _newRot;

      markers.add(
        Marker(
          markerId: const MarkerId('delivery-partner'),
          position: lerpPos,
          rotation: lerpRot,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(
            title: 'GOZOLT delivery partner',
            snippet: 'Delivering your order',
          ),
          icon: _navigatorIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (!_areLocationsNearby) return {};
    final pts = _routePoints.isNotEmpty
        ? _routePoints
        : [_supplierLocation, _customerLocation];
    return {
      Polyline(
        polylineId: const PolylineId('delivery-route'),
        points: pts,
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
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraTarget,
                zoom: 14.2,
              ),
              style: widget.isDark ? _darkMapStyle : null,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (mounted) {
                  setState(() => _isMapReady = true);
                }
                Future.delayed(
                  const Duration(milliseconds: 250),
                  _fitCameraToBounds,
                );
              },
              markers: _isMapReady ? _markers : {},
              polylines: _isMapReady ? _polylines : {},
              mapType: MapType.normal,
              compassEnabled: false,
              myLocationEnabled: true,
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
                color: widget.isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                      color: widget.isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _fitCameraToBounds,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.backgroundDark.withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: widget.isDark
                      ? AppColors.primaryGold
                      : AppColors.backgroundDark,
                ),
              ),
            ),
          ),
          if (widget.deliveryLatitude == null ||
              widget.deliveryLongitude == null)
            Positioned(
              left: 10,
              right: 54,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.backgroundDark.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.94),
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
                        'Demo Malta location shown until address coordinates are available.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: widget.isDark
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
      case FoodGroceryTrackingStage.awaitingSupplier:
        return Icons.hourglass_top_rounded;
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
      case FoodGroceryTrackingStage.arrivedAtCustomer:
        return Icons.location_on_rounded;
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
      case FoodGroceryTrackingStage.awaitingSupplier:
        return 'Waiting for confirmation';
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
      case FoodGroceryTrackingStage.arrivedAtCustomer:
        return 'Arrived at destination';
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
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    required this.onCall,
    required this.onMessage,
  });

  final bool isDark;
  final bool assigned;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
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
                      ? (driverName?.isNotEmpty == true
                          ? driverName!
                          : 'Delivery partner assigned')
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
                      ? (driverVehicle?.isNotEmpty == true
                          ? driverVehicle!
                          : 'GOZOLT delivery partner')
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
    required this.vendorTypeLabel,
    required this.total,
  });

  final bool isDark;
  final String orderId;
  final String supplierName;
  final String vendorTypeLabel;
  final double total;

  @override
  Widget build(BuildContext context) {
    final displayId = orderId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _ReferenceRow(
            isDark: isDark,
            label: 'Order ID',
            value: displayId,
          ),
          const SizedBox(height: 10),
          _ReferenceRow(
            isDark: isDark,
            label: vendorTypeLabel == 'store' ? 'Store' : 'Restaurant',
            value: supplierName,
          ),
          const SizedBox(height: 10),
          _ReferenceRow(
            isDark: isDark,
            label: 'Order Total',
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondary
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
    this.onBrowse,
  });

  final bool isDark;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 54,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 14),
            Text(
              'No active order to track',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'You do not have any food or grocery orders in progress right now.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            if (onBrowse != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.restaurant_rounded, size: 18),
                label: const Text(
                  'BROWSE FOOD & GROCERIES',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

