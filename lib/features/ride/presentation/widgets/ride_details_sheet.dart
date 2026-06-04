import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/active_ride_provider.dart';
import '../providers/active_ride_state.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import 'cancel_ride_sheet.dart';
import 'share_ride_sheet.dart';

class RideDetailsSheet extends ConsumerWidget {
  const RideDetailsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(activeRideProvider);
    final ride = rideState.ride;
    final driver = rideState.driverInfo;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text('Trip Overview', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 20),

              // Route Section (Custom Gozolt Style)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondaryLight, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ride?.pickupAddress ?? 'Meet at the pickup point',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 2,
                          height: 20,
                          color: AppColors.primaryGold.withOpacity(0.3),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dropoff Destination',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondaryLight, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ride?.dropoffAddress ?? 'Destination',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PIN Section (Custom Gozolt Style)
              if (rideState.otpPin != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGold.withOpacity(0.15), AppColors.primaryGold.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: AppColors.primaryGold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Security PIN', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Share this with the driver', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          rideState.otpPin!,
                          style: AppTextStyles.titleSmall.copyWith(color: Colors.black, letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              if (rideState.otpPin != null) const SizedBox(height: 20),

              // Payment Section
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                ),
                title: Text('\u20AC${ride?.estimatedFare?.toStringAsFixed(2) ?? '0.00'}', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Wallet: \u20AC0.00 + ${ride?.paymentMethod ?? 'Cash'}', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushNamed(RouteNames.paymentMethods);
                  },
                  child: Text('Change', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                ),
              ),
              Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5), height: 12),

              // Share trip status
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ios_share_rounded, size: 20),
                ),
                title: Text('Share ride tracking', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (ctx) => const ShareRideSheet(),
                    );
                  },
                  child: Text('Share', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Cancel ride button (hide if ride is in progress or completed)
              if (rideState.status != ActiveRideStatus.inProgress && rideState.status != ActiveRideStatus.completed) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CancelRideSheet(currentStatus: rideState.status),
                      );
                    },
                    child: const Text('Cancel Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5),
                      backgroundColor: AppColors.error.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.cardDark : Colors.grey[200],
                    foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Close', style: AppTextStyles.titleSmall.copyWith(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
