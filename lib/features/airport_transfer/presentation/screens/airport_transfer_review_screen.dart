import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_date_utils.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../providers/airport_transfer_passenger_provider.dart';
import '../providers/airport_transfer_provider.dart';
import '../providers/airport_transfer_vehicle_provider.dart';
import '../../data/datasources/airport_transfer_remote_datasource.dart';
import '../../../ride/presentation/providers/ride_providers.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../widgets/airport_transfer_header.dart';
import '../widgets/airport_transfer_payment_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/asset_paths.dart';

class AirportTransferReviewScreen extends ConsumerStatefulWidget {
  const AirportTransferReviewScreen({super.key});

  @override
  ConsumerState<AirportTransferReviewScreen> createState() =>
      _AirportTransferReviewScreenState();
}

class _AirportTransferReviewScreenState
    extends ConsumerState<AirportTransferReviewScreen>
    with WidgetsBindingObserver {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _showAgreementError = false;
  bool _isBooking = false;
  bool _useGoCoins = false;

  AirportPaymentOption _paymentOption = AirportPaymentOption.card;
  String? _selectedCardId;
  String? _pendingBookingId;
  String? _pendingBookingReference;
  double _pendingAmount = 0.0;
  String? _pendingPickupDateTime;
  String? _pendingReturnDateTime;
  String? _pendingPickupLocation;
  String? _pendingDropoffLocation;
  Timer? _pollingTimer;

  static final Uri _termsUrl = Uri.parse(
    'https://sites.google.com/view/gozoltlegal-supplier/terms-of-service',
  );

  static final Uri _privacyUrl = Uri.parse(
    'https://sites.google.com/view/gozoltlegal-supplier/privacy-policy',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingBookingId != null) {
      _verifyPendingOnlinePayment();
    }
  }

  Future<void> _verifyPendingOnlinePayment() async {
    if (_pendingBookingId == null || !mounted) return;
    try {
      final res = await ref
          .read(airportTransferRemoteDatasourceProvider)
          .verifyPayment(_pendingBookingId!);
      final isPaid = res['isPaid'] == true ||
          res['paymentStatus'] == 'PAID' ||
          res['booking']?['paymentStatus'] == 'PAID';
      if (isPaid && mounted) {
        _pollingTimer?.cancel();
        final bookingRef = _pendingBookingReference ??
            res['bookingReference']?.toString() ??
            res['booking']?['bookingReference']?.toString() ??
            _pendingBookingId!;
        final amountPaid = (res['amount'] is num)
            ? (res['amount'] as num).toDouble()
            : _pendingAmount;
        _pendingBookingId = null;

        // Clean up draft and state
        ref.read(airportTransferDraftProvider.notifier).reset();
        ref.read(airportTransferPassengerDetailsProvider.notifier).reset();
        ref.read(selectedAirportTransferVehicleProvider.notifier).clear();

        context.pushReplacementNamed(
          RouteNames.airportTransferPaymentConfirmation,
          extra: <String, dynamic>{
            'bookingId': bookingRef,
            'bookingReference': bookingRef,
            'amount': amountPaid,
            'paymentMethod': 'Online Payment (Stripe)',
            'stripePaymentIntentId': res['stripePaymentIntentId']?.toString(),
            'serviceTitle': 'Airport Transfer',
            'pickupLocation': _pendingPickupLocation,
            'dropoffLocation': _pendingDropoffLocation,
            'pickupDateTime': _pendingPickupDateTime,
            'returnDateTime': _pendingReturnDateTime,
          },
        );
      }
    } catch (_) {}
  }

  Future<void> _openLegalPage(Uri url) async {
    final opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open this page. Please try again.',
            ),
          ),
        );
    }
  }

  Future<void> _proceedToPayment(double totalAmount) async {
    if (_isBooking) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AirportTransferPaymentSheet(
          amount: totalAmount,
          initialCardId: _selectedCardId,
          initialOption: _paymentOption,
          onConfirm: (option, {cardId}) async {
            setState(() {
              _paymentOption = option;
              _selectedCardId = cardId;
            });
            return await _processBooking(option, cardId: cardId, totalAmount: totalAmount);
          },
        );
      },
    );
  }

  Future<bool> _processBooking(
    AirportPaymentOption option, {
    String? cardId,
    required double totalAmount,
  }) async {
    setState(() {
      _isBooking = true;
    });

    String? createdBookingId;
    String? createdBookingRef;

    try {
      final draft = ref.read(airportTransferDraftProvider);
      final passenger = ref.read(airportTransferPassengerDetailsProvider);
      final vehicle = ref.read(selectedAirportTransferVehicleProvider);
      final datasource = ref.read(airportTransferRemoteDatasourceProvider);
      final userProfile = ref.read(userProfileProvider).valueOrNull;

      if (vehicle == null) {
        throw Exception('Please select a transfer vehicle first.');
      }
      if (draft.pickupLocation == null || draft.dropoffLocation == null) {
        throw Exception('Pickup and drop-off locations are required.');
      }
      if (draft.pickupDate == null) {
        throw Exception('Pickup date is required.');
      }

      final scheduledPickup = AppDateUtils.createWallClockUtc(
        draft.pickupDate!,
        draft.pickupTime,
      );

      final scheduledReturn = (draft.isRoundTrip && draft.returnDate != null)
          ? AppDateUtils.createWallClockUtc(
              draft.returnDate!,
              draft.returnTime,
            )
          : null;

      final profileName =
          '${userProfile?.firstName ?? ''} ${userProfile?.lastName ?? ''}'.trim();
      final leadName = passenger.fullName.trim().isNotEmpty
          ? passenger.fullName.trim()
          : (profileName.isNotEmpty ? profileName : 'Guest Passenger');
      final leadEmail = passenger.email.trim().isNotEmpty
          ? passenger.email.trim()
          : (userProfile?.email?.trim().isNotEmpty == true
              ? userProfile!.email!.trim()
              : 'passenger@gozolt.com');
      final leadPhone = passenger.phoneNumber.trim().isNotEmpty
          ? passenger.phoneNumber.trim()
          : (userProfile?.phone?.trim().isNotEmpty == true
              ? userProfile!.phone!.trim()
              : '+356 7900 0000');

      final resolvedFlightNumber = passenger.flightNumber.isNotEmpty
          ? passenger.flightNumber
          : draft.flightNumber;
      final detailedNotes = [
        if (passenger.nationality.isNotEmpty) 'Nationality: ${passenger.nationality}',
        if (passenger.whatsAppNumber.isNotEmpty) 'WhatsApp: ${passenger.whatsAppNumber}',
        if (passenger.airline.isNotEmpty) 'Airline: ${passenger.airline}',
        if (passenger.arrivalTerminal.isNotEmpty) 'Terminal: ${passenger.arrivalTerminal}',
        if (passenger.meetAndGreetRequired)
          'Meet & Greet Sign: "${passenger.welcomeSignName.isNotEmpty ? passenger.welcomeSignName : leadName}"',
        if (passenger.meetAndGreetInstructions.isNotEmpty)
          'Meet Instructions: ${passenger.meetAndGreetInstructions}',
        if (passenger.specialAssistance.isNotEmpty)
          'Special Assistance: ${passenger.specialAssistance}',
      ].join(' | ');

      final paymentMethodStr =
          option == AirportPaymentOption.card ? 'CARD' : 'ONLINE';

      final res = await datasource.createBooking(
        vehicleId: vehicle.id,
        transferType: draft.isRoundTrip ? 'ROUND_TRIP' : 'ONE_WAY',
        flightNumber: resolvedFlightNumber.isNotEmpty ? resolvedFlightNumber : null,
        returnFlightNumber:
            draft.returnFlightNumber.isNotEmpty ? draft.returnFlightNumber : null,
        pickupLocation: draft.pickupLocation!.address,
        dropoffLocation: draft.dropoffLocation!.address,
        pickupLat: draft.pickupLocation!.latitude,
        pickupLng: draft.pickupLocation!.longitude,
        dropoffLat: draft.dropoffLocation!.latitude,
        dropoffLng: draft.dropoffLocation!.longitude,
        pickupDateTime: scheduledPickup,
        returnDateTime: scheduledReturn,
        adults: draft.adults,
        children: draft.children,
        infants: draft.infants,
        standardLuggage: draft.standardLuggage,
        largeLuggage: draft.largeLuggage,
        leadPassengerName: leadName,
        leadPassengerEmail: leadEmail,
        leadPassengerPhone: leadPhone,
        specialRequests: detailedNotes.isNotEmpty ? detailedNotes : null,
        paymentMethod: paymentMethodStr,
        paymentMethodId: option == AirportPaymentOption.card ? cardId : null,
        totalAmount: totalAmount,
      );

      createdBookingId = res['id']?.toString();
      createdBookingRef = res['bookingReference']?.toString() ??
          'GZLT-TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      if (option == AirportPaymentOption.card) {
        // Saved Card charged successfully
        ref.read(airportTransferDraftProvider.notifier).reset();
        ref.read(airportTransferPassengerDetailsProvider.notifier).reset();
        ref.read(selectedAirportTransferVehicleProvider.notifier).clear();

        if (mounted) {
          context.pushReplacementNamed(
            RouteNames.airportTransferPaymentConfirmation,
            extra: <String, dynamic>{
              'bookingId': createdBookingRef,
              'bookingReference': createdBookingRef,
              'amount': totalAmount,
              'paymentMethod': 'Saved Card',
              'stripePaymentIntentId': res['stripePaymentIntentId']?.toString(),
              'pickupLocation': draft.pickupLocation!.address,
              'dropoffLocation': draft.dropoffLocation!.address,
              'serviceTitle': 'Airport Transfer',
              'pickupDateTime': scheduledPickup.toIso8601String(),
              'returnDateTime': scheduledReturn?.toIso8601String(),
            },
          );
        }
        return true;
      } else {
        // Online Payment - Launch Stripe Checkout
        final checkoutUrl = res['checkoutUrl']?.toString();
        if (checkoutUrl != null) {
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        _pendingBookingId = createdBookingId;
        _pendingBookingReference = createdBookingRef;
        _pendingAmount = totalAmount;
        _pendingPickupDateTime = scheduledPickup.toIso8601String();
        _pendingReturnDateTime = scheduledReturn?.toIso8601String();
        _pendingPickupLocation = draft.pickupLocation?.address;
        _pendingDropoffLocation = draft.dropoffLocation?.address;

        // Start polling verification
        _pollingTimer?.cancel();
        _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (timer.tick > 90) {
            timer.cancel();
          } else {
            _verifyPendingOnlinePayment();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Opening secure Stripe Checkout... Please complete your payment.',
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return true;
      }
    } catch (error) {
      if (!mounted) return false;

      final message = error.toString().replaceFirst('Exception: ', '');

      // Navigate to Payment Failure screen with retry options
      context.pushNamed(
        RouteNames.airportTransferPaymentFailure,
        extra: <String, dynamic>{
          'bookingId': createdBookingId ?? '',
          'bookingReference': createdBookingRef ?? '',
          'amount': totalAmount,
          'errorMessage': message,
          'serviceTitle': 'Airport Transfer',
          'onRetry': () {
            _proceedToPayment(totalAmount);
          },
        },
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = ref.watch(airportTransferDraftProvider);

    final passenger = ref.watch(
      airportTransferPassengerDetailsProvider,
    );

    final vehicle = ref.watch(
      selectedAirportTransferVehicleProvider,
    );

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            const AirportTransferHeader(
              title: 'Review & Book',
            ),
            Expanded(
              child: Center(
                child: Text(
                  'No transfer vehicle selected.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Distance-based dynamic airport transfer fare calculation.
    final double subtotal = vehicle.displayPrice;

    // GoCoins logic (standardized with Car Rental and Quick Services)
    final rewardSummary = ref.watch(rewardSummaryProvider).value;
    final int balance = (rewardSummary?.currentPoints.toInt() ?? 0) > 0
        ? rewardSummary!.currentPoints.toInt()
        : (ref.watch(userRewardsPointsProvider).value ?? 0);

    final int conversionRate =
        (ref.watch(rewardRulesProvider).value?.redemption.pointsToEurRatio ?? 400.0).toInt();

    final double maxEurValue = conversionRate > 0 ? (balance / conversionRate) : 0.0;
    final double appliedEurValue = maxEurValue > subtotal ? subtotal : maxEurValue;
    final int coinsUsed = (appliedEurValue * conversionRate).round();

    final double discount = _useGoCoins && balance > 0 ? appliedEurValue : 0.0;
    final double finalTotal = (subtotal - discount).clamp(0.0, double.infinity);

    String formatAmount(double amount) {
      final symbol = (vehicle.currency == 'EUR' || vehicle.currency.isEmpty) ? '€' : vehicle.currency;
      return '$symbol${amount.toStringAsFixed(2)}';
    }

    final pickupDate = AppDateUtils.formatDate(draft.pickupDate);
    final pickupTime = AppDateUtils.formatTimeString(draft.pickupTime);
    final returnDate = AppDateUtils.formatDate(draft.returnDate);
    final returnTime = AppDateUtils.formatTimeString(draft.returnTime);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AirportTransferHeader(
            title: 'Review & Book',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB( 16, 14, 16, 26),
              children: [
                _ReviewCard(
                  isDark: isDark,
                  title: 'JOURNEY',
                  icon: Icons.route_outlined,
                  children: [
                    _LocationRow(
                      isDark: isDark,
                      icon: Icons.radio_button_checked,
                      iconColor: const Color(0xFF43A047),
                      label: 'PICKUP',
                      value: draft.pickupLocation?.address ?? 'Pickup location',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 9,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 2,
                          height: 18,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    _LocationRow(
                      isDark: isDark,
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFE15B5B),
                      label: 'DROP-OFF',
                      value:
                          draft.dropoffLocation?.address ?? 'Drop-off location',
                    ),
                    const SizedBox(height: 13),
                    _ReviewDivider(isDark: isDark),
                    const SizedBox(height: 13),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Journey type',
                      value: draft.isRoundTrip ? 'Round Trip' : 'One Way',
                    ),
                    if (draft.isRoundTrip) ...[
                      _ReviewRow(
                        isDark: isDark,
                        label: 'First trip date',
                        value: pickupDate,
                      ),
                      _ReviewRow(
                        isDark: isDark,
                        label: 'First trip time',
                        value: pickupTime,
                      ),
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Return trip date',
                        value: returnDate,
                      ),
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Return trip time',
                        value: returnTime,
                      ),
                    ] else ...[
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Pickup date',
                        value: pickupDate,
                      ),
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Pickup time',
                        value: pickupTime,
                      ),
                    ],
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Passengers',
                      value: '${draft.totalPassengers}',
                    ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Luggage',
                      value: '${draft.totalLuggage}',
                      showBottomSpacing: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ReviewCard(
                  isDark: isDark,
                  title: 'SELECTED VEHICLE',
                  icon: Icons.airport_shuttle_outlined,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 58,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : const Color(0xFFF2F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: vehicle.imageUrl.isEmpty
                              ? const Icon(
                                  Icons.airport_shuttle_rounded,
                                  color: AppColors.primaryGold,
                                  size: 32,
                                )
                              : Image.network(
                                  vehicle.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Icon(
                                      Icons.airport_shuttle_rounded,
                                      color: AppColors.primaryGold,
                                      size: 32,
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vehicle.type,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                vehicle.supplierName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),  
                        const SizedBox(width: 8),
                        Text(
                          vehicle.formattedPrice,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    _ReviewDivider(isDark: isDark),
                    const SizedBox(height: 13),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Passenger capacity',
                      value: vehicle.passengerText,
                    ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Luggage capacity',
                      value: vehicle.luggageText,
                      showBottomSpacing: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ReviewCard(
                  isDark: isDark,
                  title: 'PASSENGER & CONTACT',
                  icon: Icons.person_outline_rounded,
                  action: _CardEditButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.inputDark.withValues(alpha: 0.5)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primaryGold,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRIMARY PASSENGER',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondaryLight,
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  passenger.fullName.isEmpty
                                      ? 'Not provided'
                                      : passenger.fullName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (passenger.nationality.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    passenger.nationality,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContactDetailTile(
                      isDark: isDark,
                      icon: Icons.phone_outlined,
                      label: 'PHONE NUMBER',
                      value: passenger.phoneNumber,
                    ),
                    const SizedBox(height: 10),
                    _ContactDetailTile(
                      isDark: isDark,
                      icon: Icons.email_outlined,
                      label: 'EMAIL ADDRESS',
                      value: passenger.email,
                    ),
                    if (passenger.whatsAppNumber.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _ContactDetailTile(
                        isDark: isDark,
                        icon: Icons.chat_outlined,
                        label: 'WHATSAPP NUMBER',
                        value: passenger.whatsAppNumber,
                        badge: (passenger.whatsAppNumber == passenger.phoneNumber)
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Same as phone',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                _ReviewCard(
                  isDark: isDark,
                  title: 'FLIGHT & MEET DETAILS',
                  icon: Icons.flight_rounded,
                  action: _CardEditButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.inputDark.withValues(alpha: 0.5)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.flight_takeoff_rounded,
                                  size: 19,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FLIGHT NUMBER',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColors.textSecondaryLight,
                                        fontSize: 10,
                                        letterSpacing: 0.6,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      passenger.flightNumber.isEmpty
                                          ? 'Not provided'
                                          : passenger.flightNumber,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimaryLight,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tracked',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: const Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (passenger.airline.isNotEmpty ||
                              passenger.arrivalTerminal.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.borderDark.withValues(alpha: 0.5)
                                  : AppColors.borderLight.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (passenger.airline.isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.airlines_outlined,
                                          size: 15,
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Airline',
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                  color: isDark
                                                      ? AppColors.textSecondary
                                                      : AppColors
                                                          .textSecondaryLight,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                passenger.airline,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: isDark
                                                      ? AppColors.textPrimary
                                                      : AppColors
                                                          .textPrimaryLight,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (passenger.airline.isNotEmpty &&
                                    passenger.arrivalTerminal.isNotEmpty)
                                  const SizedBox(width: 12),
                                if (passenger.arrivalTerminal.isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.meeting_room_outlined,
                                          size: 15,
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Arrival Terminal',
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                  color: isDark
                                                      ? AppColors.textSecondary
                                                      : AppColors
                                                          .textSecondaryLight,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              Text(
                                                passenger.arrivalTerminal
                                                        .toLowerCase()
                                                        .contains('terminal')
                                                    ? passenger.arrivalTerminal
                                                    : 'Terminal ${passenger.arrivalTerminal}',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: isDark
                                                      ? AppColors.textPrimary
                                                      : AppColors
                                                          .textPrimaryLight,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (passenger.meetAndGreetRequired) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold
                              .withValues(alpha: isDark ? 0.08 : 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.waving_hand_rounded,
                                    size: 15,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Meet & Greet Service',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'INCLUDED',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: AppColors.primaryGold,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'NAME ON WELCOME SIGN',
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondary
                                                : AppColors.textSecondaryLight,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          passenger.welcomeSignName.isNotEmpty
                                              ? passenger.welcomeSignName
                                              : (passenger.fullName.isNotEmpty
                                                  ? passenger.fullName
                                                  : 'Not specified'),
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: isDark
                                                ? AppColors.textPrimary
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (passenger
                                .meetAndGreetInstructions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.backgroundDark
                                          .withValues(alpha: 0.5)
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                            .withValues(alpha: 0.5)
                                        : AppColors.borderLight
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.notes_rounded,
                                          size: 14,
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Meeting Instructions',
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondary
                                                : AppColors.textSecondaryLight,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      passenger.meetAndGreetInstructions,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimaryLight,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.inputDark.withValues(alpha: 0.5)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Meet & Greet: Not requested',
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
                    ],
                    if (passenger.specialAssistance.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.accessible_rounded,
                                size: 16,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SPECIAL ASSISTANCE & REQUIREMENTS',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppColors.textSecondaryLight,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    passenger.specialAssistance,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimaryLight,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_useGoCoins && balance > 0)
                          ? AppColors.primaryGold
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      width: (_useGoCoins && balance > 0) ? 1.5 : 0.5,
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
                        child: Image.asset(
                          AssetPaths.iconGoCoin,
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Redeem GoCoins',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Balance: $balance Coins',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (appliedEurValue > 0 && balance > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Save €${appliedEurValue.toStringAsFixed(2)} with $coinsUsed coins',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch.adaptive(
                          value: _useGoCoins && balance > 0,
                          onChanged: balance > 0
                              ? (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _useGoCoins = val;
                                  });
                                }
                              : null,
                          activeTrackColor: AppColors.primaryGold,
                          inactiveTrackColor:
                              Theme.of(context).dividerTheme.color,
                        ),
                      ),
                    ],
                  ),
                ),
                _ReviewCard(
                  isDark: isDark,
                  title: 'PAYMENT SUMMARY',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    if (vehicle.distanceKm != null) ...[
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Distance',
                        value: '${vehicle.distanceKm!.toStringAsFixed(1)} km',
                      ),
                    ],
                    _ReviewRow(
                      isDark: isDark,
                      label: draft.isRoundTrip ? 'Round-trip Total' : 'One-way Transfer',
                      value: formatAmount(subtotal),
                    ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Taxes & VAT',
                      value: 'Included',
                    ),
                    const SizedBox(height: 3),
                    _ReviewDivider(isDark: isDark),
                    const SizedBox(height: 12),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Subtotal',
                      value: formatAmount(subtotal),
                    ),
                    if (_useGoCoins && discount > 0)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'GoCoins Discount',
                        value: '-${formatAmount(discount)}',
                      ),
                    const SizedBox(height: 3),
                    _ReviewDivider(isDark: isDark),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Final total',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          formatAmount(finalTotal),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ReviewCard(
                  isDark: isDark,
                  title: 'BOOKING TERMS',
                  icon: Icons.verified_user_outlined,
                  children: [
                    _LegalAgreementRow(
                      isDark: isDark,
                      value: _acceptTerms,
                      leadingText: 'I accept the ',
                      linkText: 'Terms & Conditions',
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;

                          if (_acceptTerms && _acceptPrivacy) {
                            _showAgreementError = false;
                          }
                        });
                      },
                      onLinkPressed: () {
                        _openLegalPage(_termsUrl);
                      },
                    ),
                    const SizedBox(height: 10),
                    _LegalAgreementRow(
                      isDark: isDark,
                      value: _acceptPrivacy,
                      leadingText: 'I accept the ',
                      linkText: 'Privacy Policy',
                      onChanged: (value) {
                        setState(() {
                          _acceptPrivacy = value ?? false;
                          if (_acceptTerms && _acceptPrivacy) {
                            _showAgreementError = false;
                          }
                        });
                      },
                      onLinkPressed: () {
                        _openLegalPage(_privacyUrl);
                      },
                    ),
                  ],
                ),
              ],
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
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GozoltButton(
                  label: _isBooking ? 'Processing...' : 'Book Transfer',
                  width: double.infinity,
                  onPressed: _isBooking
                      ? null
                      : () {
                          if (!_acceptTerms || !_acceptPrivacy) {
                            setState(() {
                              _showAgreementError = true;
                            });
                            return;
                          }
                          setState(() {
                            _showAgreementError = false;
                          });
                          _proceedToPayment(finalTotal);
                        }),
              if (!_acceptTerms || !_acceptPrivacy) ...[
                if (_showAgreementError) const SizedBox(height: 7),
                if (_showAgreementError)
                  Text(
                    'Accept the Terms & Conditions and Privacy Policy to continue',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
    this.action,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }
}

class _CardEditButton extends StatelessWidget {
  const _CardEditButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_outlined,
              size: 13,
              color: AppColors.primaryGold,
            ),
            const SizedBox(width: 4),
            Text(
              'Edit',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactDetailTile extends StatelessWidget {
  const _ContactDetailTile({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.inputDark
                : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.primaryGold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'Not provided' : value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          badge!,
        ],
      ],
    );
  }
}

class _LegalAgreementRow extends StatelessWidget {
  const _LegalAgreementRow({
    required this.isDark,
    required this.value,
    required this.leadingText,
    required this.linkText,
    required this.onChanged,
    required this.onLinkPressed,
  });

  final bool isDark;
  final bool value;
  final String leadingText;
  final String linkText;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onLinkPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primaryGold,
            checkColor: AppColors.backgroundDark,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                leadingText,
                style: AppTextStyles.bodySmall.copyWith(
                  height: 1.4,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onLinkPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                  ),
                  child: Text(
                    linkText,
                    style: AppTextStyles.bodySmall.copyWith(
                      height: 1.4,
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.isDark,
    required this.label,
    required this.value,
    this.showBottomSpacing = true,
  });

  final bool isDark;
  final String label;
  final String value;
  final bool showBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomSpacing ? 9 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDivider extends StatelessWidget {
  const _ReviewDivider({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
