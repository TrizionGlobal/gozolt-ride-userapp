import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../providers/airport_transfer_passenger_provider.dart';
import '../providers/airport_transfer_provider.dart';
import '../providers/airport_transfer_vehicle_provider.dart';
import '../../../ride/presentation/providers/ride_providers.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../widgets/airport_transfer_header.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/booking_payment_sheet.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../../../../core/constants/asset_paths.dart';

class AirportTransferReviewScreen extends ConsumerStatefulWidget {
  const AirportTransferReviewScreen({super.key});

  @override
  ConsumerState<AirportTransferReviewScreen> createState() =>
      _AirportTransferReviewScreenState();
}

class _AirportTransferReviewScreenState
    extends ConsumerState<AirportTransferReviewScreen> {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _showAgreementError = false;
  bool _isBooking = false;
  bool _useGoCoins = false;

  String _formatDateAndTime(
    BuildContext context,
    DateTime? date,
    String? storedTime,
  ) {
    if (date == null) return 'Not selected';

    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    if (storedTime == null || storedTime.isEmpty) {
      return formattedDate;
    }

    final parts = storedTime.split(':');

    if (parts.length != 2) {
      return '$formattedDate, $storedTime';
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return '$formattedDate, $storedTime';
    }

    final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(
        hour: hour,
        minute: minute,
      ),
      alwaysUse24HourFormat: true,
    );

    return '$formattedDate, $formattedTime';
  }

  PaymentMethodType _paymentMethodType = PaymentMethodType.cash;
  String? _selectedCardId;

  static final Uri _termsUrl = Uri.parse(
    'https://gozolt.com.mt/terms-and-conditions',
  );

  static final Uri _privacyUrl = Uri.parse(
    'https://gozolt.com.mt/privacy-policy',
  );

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

  Future<void> _proceedToPayment() async {
    if (_isBooking) return;

    var paymentConfirmed = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BookingPaymentSheet(
          currentType: _paymentMethodType,
          currentCardId: _selectedCardId,
          onConfirm: (
            PaymentMethodType type, {
            String? cardId,
          }) {
            if (!mounted) return;

            setState(() {
              _paymentMethodType = type;
              _selectedCardId = type == PaymentMethodType.card ? cardId : null;
            });

            paymentConfirmed = true;
          },
        );
      },
    );

    if (paymentConfirmed && mounted) {
      await _bookTransfer();
    }
  }

  Future<void> _bookTransfer() async {
    if (_isBooking) return;

    setState(() {
      _isBooking = true;
    });

    try {
      // TODO(AIRPORT_TRANSFER_API):
      // Replace this temporary delay and booking ID with the real
      // Airport Transfer create-booking API response.
      //
      // For card bookings, send _selectedCardId to the backend.
      // For cash bookings, send paymentMethod as CASH.

      await Future<void>.delayed(
        const Duration(milliseconds: 800),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final temporaryBookingId =
          'GZLT-${timestamp.substring(timestamp.length - 8)}';

      final paymentMethod =
          _paymentMethodType == PaymentMethodType.cash ? 'Cash' : 'Card';

      final paymentStatus = _paymentMethodType == PaymentMethodType.cash
          ? 'Pay after ride completion'
          : 'Card selected - payment confirmation pending';

      if (!mounted) return;

      context.pushReplacementNamed(
        RouteNames.airportTransferConfirmation,
        extra: <String, dynamic>{
          'bookingId': temporaryBookingId,
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentStatus,
        },
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create the transfer booking. Please try again.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
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
    final rewardsAsync = ref.watch(userRewardsPointsProvider);

    final rewardSummaryAsync = ref.watch(rewardSummaryProvider);
    final rewardRulesAsync = ref.watch(rewardRulesProvider);

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

    // Temporary Airport Transfer fare calculation.
    // The supplier/API will provide the final quoted fares later.
    final double oneWayFare = vehicle.fixedPrice;
    final double returnFare = draft.isRoundTrip ? vehicle.fixedPrice : 0.0;

    final double subtotal = oneWayFare + returnFare;

    // GO Coins calculation.
    final int availableCoins = rewardsAsync.value ??
        rewardSummaryAsync.value?.currentPoints.toInt() ??
        0;

    final double conversionRate =
        rewardRulesAsync.value?.redemption.pointsToEurRatio.toDouble() ?? 400.0;

    final int minimumPoints =
        rewardRulesAsync.value?.redemption.minimumPoints ?? 200;

    final bool canUseGoCoins = availableCoins >= minimumPoints && subtotal > 0;

    final double maximumCoinValue = availableCoins / conversionRate;

    final double applicableCoinValue =
        maximumCoinValue > subtotal ? subtotal : maximumCoinValue;

    final double goCoinsDiscount =
        _useGoCoins && canUseGoCoins ? applicableCoinValue : 0.0;

    final int coinsUsed = (goCoinsDiscount * conversionRate).round();

    final double finalTotal = subtotal - goCoinsDiscount;

    String formatAmount(double amount) {
      return '${vehicle.currency}${amount.toStringAsFixed(2)}';
    }

    final pickupDate = draft.pickupDate == null
        ? 'Date not selected'
        : DateFormat('dd MMM yyyy').format(draft.pickupDate!);

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
                      value: draft.isRoundTrip ? 'Return' : 'One Way',
                    ),
                    if (draft.isRoundTrip) ...[
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Pickup date & time',
                        value: _formatDateAndTime(
                          context,
                          draft.pickupDate,
                          draft.pickupTime,
                        ),
                        compactValue: true,
                      ),
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Return date & time',
                        value: _formatDateAndTime(
                          context,
                          draft.returnDate,
                          draft.returnTime,
                        ),
                        compactValue: true,
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
                        value: draft.pickupTime ?? 'Not selected',
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
                  children: [
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Primary passenger',
                      value: passenger.fullName,
                    ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Phone',
                      value: passenger.phoneNumber,
                    ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Email',
                      value: passenger.email,
                    ),
                    if (passenger.whatsAppNumber.isNotEmpty)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'WhatsApp',
                        value: passenger.whatsAppNumber,
                      ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Nationality',
                      value: passenger.nationality,
                      showBottomSpacing: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ReviewCard(
                  isDark: isDark,
                  title: 'FLIGHT & MEET DETAILS',
                  icon: Icons.flight_rounded,
                  children: [
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Flight number',
                      value: passenger.flightNumber,
                    ),
                    if (passenger.airline.isNotEmpty)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Airline',
                        value: passenger.airline,
                      ),
                    if (passenger.arrivalTerminal.isNotEmpty)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Terminal',
                        value: passenger.arrivalTerminal,
                      ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Meet & Greet',
                      value: passenger.meetAndGreetRequired
                          ? 'Required — Included'
                          : 'Not required',
                      showBottomSpacing: passenger.meetAndGreetRequired ||
                          passenger.specialAssistance.isNotEmpty,
                    ),
                    if (passenger.meetAndGreetRequired) ...[
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Welcome sign',
                        value: passenger.welcomeSignName,
                      ),
                      if (passenger.meetAndGreetInstructions.isNotEmpty)
                        _ReviewRow(
                          isDark: isDark,
                          label: 'Meeting instructions',
                          value: passenger.meetAndGreetInstructions,
                        ),
                    ],
                    if (passenger.specialAssistance.isNotEmpty)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Special assistance',
                        value: passenger.specialAssistance,
                        showBottomSpacing: false,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _useGoCoins
                          ? AppColors.primaryGold
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      width: _useGoCoins ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          AssetPaths.iconGoCoin,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use GO Coins',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$availableCoins coins available',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (_useGoCoins && canUseGoCoins) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Save ${formatAmount(goCoinsDiscount)} '
                                'using $coinsUsed coins',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (!canUseGoCoins) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Minimum $minimumPoints coins required',
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
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _useGoCoins && canUseGoCoins,
                        activeTrackColor: AppColors.primaryGold,
                        onChanged: canUseGoCoins
                            ? (value) {
                                setState(() {
                                  _useGoCoins = value;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                _ReviewCard(
                  isDark: isDark,
                  title: 'PAYMENT SUMMARY',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _ReviewRow(
                      isDark: isDark,
                      label: 'One-way fare',
                      value: formatAmount(oneWayFare),
                    ),
                    if (draft.isRoundTrip)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'Return fare',
                        value: formatAmount(returnFare),
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
                    if (_useGoCoins && goCoinsDiscount > 0)
                      _ReviewRow(
                        isDark: isDark,
                        label: 'GO Coins',
                        value: '-${formatAmount(goCoinsDiscount)}',
                      ),
                    const SizedBox(height: 3),
                    _ReviewDivider(isDark: isDark),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Final total',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          formatAmount(finalTotal),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Booking remains subject to supplier and driver availability.',
                              style: AppTextStyles.bodySmall.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          _proceedToPayment();
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
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;

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
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
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
    this.compactValue = false,
  });

  final bool isDark;
  final String label;
  final String value;
  final bool showBottomSpacing;
  final bool compactValue;

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
            flex: 4,
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
            flex: 6,
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.right,
              maxLines: compactValue ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textSecondaryLight,
                fontWeight: compactValue
                    ? FontWeight.w400
                    : FontWeight.w500,
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
