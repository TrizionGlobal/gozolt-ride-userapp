import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../providers/airport_transfer_provider.dart';
import '../providers/airport_transfer_vehicle_provider.dart';
import '../widgets/airport_transfer_header.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

class AirportTransferDetailsScreen extends ConsumerWidget {
  const AirportTransferDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vehicle = ref.watch(selectedAirportTransferVehicleProvider);

    final draft = ref.watch(airportTransferDraftProvider);

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            const AirportTransferHeader(
              title: 'Transfer Details',
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Please select a transfer vehicle first.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
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

    final imageHeight = (MediaQuery.sizeOf(context).width * 0.48)
        .clamp(180.0, 230.0)
        .toDouble();

    final normalizedFeatures =
        vehicle.features.map((feature) => feature.toLowerCase()).toList();

    final transmissionText = normalizedFeatures.any(
      (feature) => feature.contains('manual'),
    )
        ? 'Manual'
        : 'Automatic';

    final airConditioningText = normalizedFeatures.any(
      (feature) => feature.contains('non-ac') || feature.contains('without ac'),
    )
        ? 'Non-AC'
        : 'Air conditioning';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AirportTransferHeader(
            title: 'Transfer Details',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                24,
              ),
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: imageHeight,
                        child: vehicle.imageUrl.isEmpty
                            ? _VehicleImageFallback(
                                isDark: isDark,
                              )
                            : Image.network(
                                vehicle.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _VehicleImageFallback(
                                    isDark: isDark,
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vehicle.isRecommended ||
                                vehicle.isBestValue) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (vehicle.isBestValue)
                                    const _StatusBadge(
                                      text: 'BEST VALUE',
                                      backgroundColor: Color(0xFFE8F7EA),
                                      foregroundColor: Color(0xFF43A047),
                                    ),
                                  if (vehicle.isRecommended)
                                    const _StatusBadge(
                                      text: 'RECOMMENDED',
                                      backgroundColor: Color(0xFFFFF5D7),
                                      foregroundColor: Color(0xFFE9A900),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              vehicle.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 17,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vehicle.supplierName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: AppColors.primaryGold,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  vehicle.supplierRating.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'VEHICLE DETAILS',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _VehicleDetailRow(
                              isDark: isDark,
                              icon: Icons.category_outlined,
                              label: 'Vehicle type',
                              value: vehicle.type,
                            ),
                            const SizedBox(height: 9),
                            _VehicleDetailRow(
                              isDark: isDark,
                              icon: Icons.people_alt_outlined,
                              label: 'Capacity',
                              value: vehicle.passengerText,
                            ),
                            const SizedBox(height: 9),
                            _VehicleDetailRow(
                              isDark: isDark,
                              icon: Icons.luggage_outlined,
                              label: 'Luggage',
                              value: vehicle.luggageText,
                            ),
                            const SizedBox(height: 9),
                            _VehicleDetailRow(
                              isDark: isDark,
                              icon: Icons.ac_unit_rounded,
                              label: 'Comfort',
                              value: airConditioningText,
                            ),
                            const SizedBox(height: 9),
                            _VehicleDetailRow(
                              isDark: isDark,
                              icon: Icons.settings_outlined,
                              label: 'Transmission',
                              value: transmissionText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailsCard(
                  isDark: isDark,
                  title: 'YOUR JOURNEY',
                  child: Column(
                    children: [
                      _JourneyLocationRow(
                        isDark: isDark,
                        icon: Icons.radio_button_checked,
                        iconColor: const Color(0xFF43A047),
                        label: 'PICKUP',
                        value:
                            draft.pickupLocation?.address ?? 'Pickup location',
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
                      _JourneyLocationRow(
                        isDark: isDark,
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFE15B5B),
                        label: 'DROP-OFF',
                        value: draft.dropoffLocation?.address ??
                            'Drop-off location',
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          _JourneyInfo(
                            icon: Icons.calendar_today_outlined,
                            text: pickupDate,
                            isDark: isDark,
                          ),
                          if (draft.pickupTime != null &&
                              draft.pickupTime!.isNotEmpty)
                            _JourneyInfo(
                              icon: Icons.schedule_outlined,
                              text: draft.pickupTime!,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailsCard(
                  isDark: isDark,
                  title: 'TRANSFER BENEFITS',
                  child: Column(
                    children: [
                      _TransferBenefitRow(
                        isDark: isDark,
                        icon: Icons.schedule_rounded,
                        title: 'Free waiting',
                        value: '60 minutes',
                      ),
                      _TransferBenefitDivider(isDark: isDark),
                      _TransferBenefitRow(
                        isDark: isDark,
                        icon: Icons.flight_rounded,
                        title: 'Flight delay',
                        value: 'Monitored automatically',
                      ),
                      _TransferBenefitDivider(isDark: isDark),
                      _TransferBenefitRow(
                        isDark: isDark,
                        icon: Icons.shield_outlined,
                        title: 'Cancellation',
                        value: 'Free up to 24 hours',
                      ),
                      _TransferBenefitDivider(isDark: isDark),
                      _TransferBenefitRow(
                        isDark: isDark,
                        icon: Icons.person_outline_rounded,
                        title: 'Meet & Greet',
                        value: 'Included',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailsCard(
                  isDark: isDark,
                  title: 'PRICE SUMMARY',
                  child: Column(
                    children: [
                      _PriceRow(
                        isDark: isDark,
                        label: 'Transfer',
                        value: vehicle.formattedPrice,
                      ),
                      const SizedBox(height: 10),
                      _PriceRow(
                        isDark: isDark,
                        label: 'Taxes & VAT',
                        value: 'Included',
                      ),
                      const SizedBox(height: 13),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
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
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 19,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Your fixed price includes the selected vehicle and journey. Subject to supplier and driver availability.',
                          style: AppTextStyles.bodySmall.copyWith(
                            height: 1.4,
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
                label: 'Continue',
                width: double.infinity,
                onPressed: () {
                  context.pushNamed(
                    RouteNames.airportTransferPassengerDetails,
                    );
                },
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Next: ',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    TextSpan(
                      text: 'Passenger & Flight Details',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  final bool isDark;
  final String title;
  final Widget child;

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
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _VehicleDetailRow extends StatelessWidget {
  const _VehicleDetailRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primaryGold,
          ),
        ),
        const SizedBox(width: 10),
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
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyLocationRow extends StatelessWidget {
  const _JourneyLocationRow({
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
                  letterSpacing: 0.7,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
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

class _JourneyInfo extends StatelessWidget {
  const _JourneyInfo({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryGold,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _TransferBenefitRow extends StatelessWidget {
  const _TransferBenefitRow({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.value,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.16,
            ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.primaryGold : AppColors.backgroundDark,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 145,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferBenefitDivider extends StatelessWidget {
  const _TransferBenefitDivider({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 49,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
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
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VehicleImageFallback extends StatelessWidget {
  const _VehicleImageFallback({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.backgroundDark : const Color(0xFFF2F4F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.airport_shuttle_rounded,
        size: 70,
        color: isDark ? AppColors.textSecondary : const Color(0xFF9BA4AD),
      ),
    );
  }
}
