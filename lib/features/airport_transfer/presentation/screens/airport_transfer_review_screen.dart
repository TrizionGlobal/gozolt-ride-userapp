import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../providers/airport_transfer_passenger_provider.dart';
import '../providers/airport_transfer_provider.dart';
import '../providers/airport_transfer_vehicle_provider.dart';
import '../widgets/airport_transfer_header.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isBooking = false;

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

  Future<void> _bookTransfer() async {
    if (!_acceptTerms || !_acceptPrivacy || _isBooking) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    // The API developer will replace this with:
    // await airportTransferRepository.createBooking(...)

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    setState(() {
      _isBooking = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Airport transfer is ready for booking API integration.',
          ),
        ),
      );
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
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                26,
              ),
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
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w800,
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
                _ReviewCard(
                  isDark: isDark,
                  title: 'PAYMENT SUMMARY',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Transfer',
                      value: vehicle.formattedPrice,
                    ),
                    _ReviewRow(
                      isDark: isDark,
                      label: 'Taxes & VAT',
                      value: 'Included',
                    ),
                    _ReviewDivider(isDark: isDark),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          vehicle.formattedPrice,
                          style: AppTextStyles.headlineSmall.copyWith(
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
                onPressed: _acceptTerms && _acceptPrivacy && !_isBooking
                    ? _bookTransfer
                    : null,
              ),
              if (!_acceptTerms || !_acceptPrivacy) ...[
                const SizedBox(height: 7),
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
  });

  final bool isDark;
  final String label;
  final String value;
  final bool showBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomSpacing ? 10 : 0,
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
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
