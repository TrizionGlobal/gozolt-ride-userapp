import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/saved_payment_method.dart';
import '../providers/ride_providers.dart';
import '../providers/active_ride_provider.dart';
import '../providers/active_ride_state.dart';
import '../widgets/payment_brand_icon.dart';
import '../widgets/stripe_add_card_sheet.dart';
import '../widgets/add_card_sheet.dart';
import '../../../history/presentation/screens/receipt_screen.dart';
import '../../../history/data/models/ride_history_item.dart';
import '../../../home/presentation/providers/home_providers.dart';

class RideCompleteScreen extends ConsumerStatefulWidget {
  const RideCompleteScreen({super.key});

  @override
  ConsumerState<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends ConsumerState<RideCompleteScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0; // Starts at 0 to force user selection
  final _commentController = TextEditingController();
  bool _hasSubmittedRating = false;
  bool _isSubmittingRating = false;
  late AnimationController _checkAnimController;
  late Animation<double> _checkScale;

  // Tip
  double _tipAmount = 0;
  bool _hasSentTip = false;
  bool _tipSkipped = false;
  bool _showCustomTip = false;
  bool _isSendingTip = false;
  final _customTipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );
    _checkAnimController.forward();
    
    // Auto-show rating on screen open if payment is already completed (e.g., Card auto-capture)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideState = ref.read(activeRideProvider);
      if (rideState.isPaid) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && !_hasSubmittedRating) {
            _showRatingModal();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _customTipController.dispose();
    _checkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for payment completion: show success banner → wait 5s → show rating modal
    ref.listen<ActiveRideState>(activeRideProvider, (prev, next) {
      if (prev != null && !prev.isPaid && next.isPaid && !_hasSubmittedRating) {
        // Show success banner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Payment Successful! 🎉',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Show rating modal after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_hasSubmittedRating) {
            _showRatingModal();
          }
        });
      }
    });

    final rideState = ref.watch(activeRideProvider);
    final ride = rideState.ride;
    final driver = rideState.driverInfo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    String formattedPaymentMethod = ride?.paymentMethod ?? 'CASH';
    bool isCash = formattedPaymentMethod.toUpperCase() == 'CASH';
    
    if (formattedPaymentMethod.toUpperCase() == 'CARD' && ride?.paymentMethodId != null) {
      final pmState = ref.watch(paymentMethodsProvider);
      final methods = pmState.value ?? [];
      try {
        final card = methods.firstWhere((m) => m.id == ride!.paymentMethodId);
        formattedPaymentMethod = card.displayName;
      } catch (_) {
        formattedPaymentMethod = 'Card';
      }
    }

    final fare = ride?.actualFare ?? ride?.estimatedFare ?? 0.0;
    final extraFare = ride?.extraFare ?? 0.0;
    final baseFareForDisplay = fare - extraFare;
    final cardColor = Theme.of(context).cardTheme.color;
    final borderColor = Theme.of(context).dividerTheme.color ?? AppColors.borderDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(activeRideProvider.notifier).reset();
                        context.goNamed(RouteNames.home);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                        side: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Home', style: AppTextStyles.titleSmall),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(activeRideProvider.notifier).reset();
                        context.goNamed(RouteNames.searchDestination);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Book Again', style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Checkmark animation
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withOpacity(0.15),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                        width: 2),
                  ),
                  child: const Icon(Icons.check,
                      color: AppColors.success, size: 40),
                ),
              ),
              const SizedBox(height: 12),

              Text('Ride Complete!',
                  style: AppTextStyles.headlineMedium.copyWith(color: textColor)),
              const SizedBox(height: 8),
              Text(
                'You have arrived at your destination',
                style: AppTextStyles.bodyMedium.copyWith(color: secondaryTextColor),
              ),
              const SizedBox(height: 16),

              // Total fare
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      ride?.actualFare != null ? 'Total Fare' : 'Estimated Fare',
                      style: AppTextStyles.bodyMedium.copyWith(color: secondaryTextColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\u20AC${fare.toStringAsFixed(2)}',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primaryGold,
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (extraFare > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.inputDark : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Ride Fare', style: AppTextStyles.bodySmall.copyWith(color: secondaryTextColor)),
                                  Text('\u20AC${baseFareForDisplay.toStringAsFixed(2)}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Extra Tip Added', style: AppTextStyles.bodySmall.copyWith(color: secondaryTextColor)),
                                  Text('\u20AC${extraFare.toStringAsFixed(2)}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Payment method is shown in the section below — no duplicate badge here
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Pay Now / Payment Section ──
              if (!rideState.isPaid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tappable payment method row
                      InkWell(
                        onTap: () => _showPaymentMethodSheet(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Method',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  Icon(
                                    isCash ? Icons.payments_outlined : Icons.credit_card,
                                    size: 18,
                                    color: AppColors.primaryGold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCash ? 'Cash' : formattedPaymentMethod,
                                    style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.primaryGold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right,
                                      size: 18, color: AppColors.primaryGold),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change payment method',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: secondaryTextColor, fontSize: 11),
                      ),
                      if (isCash) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: secondaryTextColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please pay the driver directly in cash.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: secondaryTextColor,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: rideState.isPaymentLoading
                                ? null
                                : () => ref
                                    .read(activeRideProvider.notifier)
                                    .checkoutRide(
                                      paymentMethod: ride?.paymentMethod,
                                      paymentMethodId: ride?.paymentMethodId,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: rideState.isPaymentLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Pay \u20AC${fare.toStringAsFixed(2)} Now',
                                    style: AppTextStyles.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                      if (rideState.errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          rideState.errorMessage!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 22),
                          const SizedBox(width: 10),
                          Text('Payment Completed',
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCash ? Icons.payments_outlined : Icons.credit_card,
                            size: 16,
                            color: AppColors.success.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paid securely via ${isCash ? 'Cash' : formattedPaymentMethod}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if ((rideState.isPaid || isCash) && !_hasSubmittedRating) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _showRatingModal,
                          icon: const Icon(Icons.star_outline, color: AppColors.primaryGold, size: 18),
                          label: Text('Rate', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryGold),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGold.withOpacity(0.15),
                              AppColors.primaryGold.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryGold.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Image.asset(AssetPaths.iconGoCoin, width: 12, height: 12),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '+${(fare * 10).floor()} Coins',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGold.withOpacity(0.15),
                        AppColors.primaryGold.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Image.asset(AssetPaths.iconGoCoin, width: 12, height: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${(fare * 10).floor()} GoCoins Earned!',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Route summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withOpacity(0.2),
                            border: Border.all(color: AppColors.success, width: 2.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (ride != null && ride.pickupAddress.isNotEmpty) ? ride.pickupAddress : 'Pickup location',
                            style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w500, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          2,
                          (_) => Container(
                            width: 2,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: borderColor,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withOpacity(0.2),
                            border: Border.all(color: AppColors.error, width: 2.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (ride != null && ride.dropoffAddress.isNotEmpty) ? ride.dropoffAddress : 'Dropoff location',
                            style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w500, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),

              // Rating section is now in modal
              if (_hasSubmittedRating) ...[
                // After rating submitted
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Thank you for your feedback!',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],


              // Tip Your Driver section (Hidden for cash payments, or if driver has no bank details)
              // if (!isCash && !_hasSentTip && !_tipSkipped && (driver?.hasBankDetails ?? false))
              //   _buildTipSection(driver?.name),
              // if (_hasSentTip)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tip of \u20AC${_tipAmount.toStringAsFixed(2)} sent! Thank you!',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Report an issue
              TextButton.icon(
                onPressed: () {
                  context.pushNamed(RouteNames.createTicket, extra: rideState.ride?.id);
                },
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text('Report an Issue'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Payment Method Sheet ──────────────────────────────
  void _showPaymentMethodSheet() {
    final rideState = ref.read(activeRideProvider);
    final ride = rideState.ride;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentMethodSheet(
        currentMethod: ride?.paymentMethod ?? 'CASH',
        currentMethodId: ride?.paymentMethodId,
        onMethodSelected: (method, {String? methodId}) {
          ref.read(activeRideProvider.notifier).updateLocalPaymentMethod(
                method,
                methodId: methodId,
              );
        },
      ),
    );
  }

  // ── Fare Breakdown (Change 3) ──────────────────────────
  Widget _buildFareBreakdown(dynamic rideState) {
    final base = rideState.ride?.baseFare as double?;
    final distance = rideState.ride?.distanceFare as double?;
    final waitTime = rideState.ride?.waitTimeFee as double?;
    final booking = rideState.ride?.bookingFee as double?;
    final surge = rideState.ride?.surgeMultiplier as double?;

    if (base == null && distance == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fare Breakdown',
              style: AppTextStyles.titleSmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          if (base != null)
            _fareRow('Base Fare', '\u20AC${base.toStringAsFixed(2)}'),
          if (distance != null)
            _fareRow('Distance', '\u20AC${distance.toStringAsFixed(2)}'),
          if (waitTime != null && waitTime > 0)
            _fareRow('Wait Time Fee', '\u20AC${waitTime.toStringAsFixed(2)}'),
          if (booking != null)
            _fareRow('Booking Fee', '\u20AC${booking.toStringAsFixed(2)}'),
          if (surge != null && surge > 1.0)
            _fareRow('Surge', '${surge.toStringAsFixed(1)}x'),
            
          const SizedBox(height: 8),
          Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '100% of any extra amount or tips you add goes directly to your driver. Gozolt only takes a small commission on the base ride.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Tip Your Driver Section ──────────────────────────────
  Widget _buildTipSection(String? driverName) {
    const tipAmounts = [1.0, 2.0, 3.0, 5.0];

    return Column(
      children: [
        Text(
          driverName != null
              ? 'Would you like to tip $driverName?'
              : 'Would you like to tip your driver?',
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: 12),

        // Quick-select chips + Custom chip
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ...tipAmounts.map((amount) {
              final isSelected = _tipAmount == amount && !_showCustomTip;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showCustomTip = false;
                    _tipAmount = isSelected ? 0 : amount;
                    _customTipController.clear();
                  });
                },
                child: Container(
                  width: 60,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGold
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGold
                          : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '\u20AC${amount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected
                            ? Theme.of(context).scaffoldBackgroundColor
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Custom chip
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _showCustomTip = !_showCustomTip;
                  if (!_showCustomTip) {
                    _customTipController.clear();
                    _tipAmount = 0;
                  } else {
                    _tipAmount = 0;
                  }
                });
              },
              child: Container(
                width: 60,
                height: 36,
                decoration: BoxDecoration(
                  color: _showCustomTip
                      ? AppColors.primaryGold
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showCustomTip
                        ? AppColors.primaryGold
                        : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Custom',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _showCustomTip
                          ? Theme.of(context).scaffoldBackgroundColor
                          : AppColors.textSecondary,
                      fontWeight:
                          _showCustomTip ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Custom amount TextField
        if (_showCustomTip) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _customTipController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.primaryGold),
              decoration: InputDecoration(
                prefixText: '\u20AC ',
                prefixStyle: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.primaryGold),
                hintText: '0.00',
                hintStyle: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primaryGold),
                ),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0;
                setState(() => _tipAmount = parsed > 999.99 ? 999.99 : parsed);
              },
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Send Tip button (visible when amount > 0)
        if (_tipAmount > 0)
          SizedBox(
            width: 240,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSendingTip ? null : _sendTip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryGold.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSendingTip
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Send \u20AC${_tipAmount.toStringAsFixed(2)} Tip',
                      style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        const SizedBox(height: 4),

        // Skip
        TextButton(
          onPressed: () => setState(() => _tipSkipped = true),
          child: Text('Skip',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Future<void> _sendTip() async {
    if (_tipAmount <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSendingTip = true);
    await Future.wait([
      ref.read(activeRideProvider.notifier).sendTip(_tipAmount),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
    
    if (!mounted) return;
    setState(() {
      _isSendingTip = false;
      _hasSentTip = true;
    });
  }

  Future<void> _submitRating(void Function(void Function()) setModalState) async {
    HapticFeedback.mediumImpact();
    setModalState(() => _isSubmittingRating = true);
    setState(() => _isSubmittingRating = true);
    
    final comment = _commentController.text.trim();
    
    await Future.wait([
      ref.read(activeRideProvider.notifier).rateRide(
            _rating,
            comment: comment.isNotEmpty ? comment : null,
          ),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
        
    if (!mounted) return;
    Navigator.pop(context);
    setState(() {
      _isSubmittingRating = false;
      _hasSubmittedRating = true;
    });
  }

  void _showRatingModal() {
    final driver = ref.read(activeRideProvider).driverInfo;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Rate your driver',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (driver != null) ...[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                      backgroundImage: (driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty)
                          ? NetworkImage(driver.avatarUrl!)
                          : null,
                      child: (driver.avatarUrl == null || driver.avatarUrl!.isEmpty)
                          ? Text(
                              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primaryGold),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      driver.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'How was your ride with ${driver?.name ?? 'your driver'}?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setModalState(() => _rating = starNum);
                          setState(() => _rating = starNum);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starNum <= _rating ? Icons.star : Icons.star_border,
                            color: AppColors.primaryGold,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Comment box
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Write your experience',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      filled: true,
                      fillColor: isDark ? AppColors.inputDark : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_rating == 0 || _isSubmittingRating) ? null : () {
                        _submitRating(setModalState);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryGold.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmittingRating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Rating',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Selection Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodSheet extends ConsumerStatefulWidget {
  final String currentMethod;
  final String? currentMethodId;
  final void Function(String method, {String? methodId}) onMethodSelected;

  const _PaymentMethodSheet({
    required this.currentMethod,
    this.currentMethodId,
    required this.onMethodSelected,
  });

  @override
  ConsumerState<_PaymentMethodSheet> createState() =>
      _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends ConsumerState<_PaymentMethodSheet> {
  late String _selectedMethod;
  String? _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentMethod.toUpperCase();
    _selectedMethodId = widget.currentMethodId;
  }

  void _confirm() {
    widget.onMethodSelected(_selectedMethod, methodId: _selectedMethodId);
    Navigator.of(context).pop();
  }

  void _addCard(List<SavedPaymentMethod> existingMethods) {
    

    final ds = ref.read(paymentRemoteDatasourceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StripeAddCardSheet(
        datasource: ds,
        onCardAdded: (paymentMethodId) async {
          if (paymentMethodId != null) {
            // Save card to our database via confirm-setup
            try {
              await ds.confirmSetupIntent(paymentMethodId);
            } catch (_) {}
            // Reload cards
            ref.invalidate(paymentMethodsProvider);
            // Select the new card
            setState(() {
              _selectedMethod = 'CARD';
              _selectedMethodId = paymentMethodId;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card saved successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardTheme.color;
    final borderColor =
        Theme.of(context).dividerTheme.color ?? AppColors.borderDark;
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 20),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Payment Method',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 16,
                        color:
                            isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Options
          paymentMethodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold)),
            ),
            error: (_, __) => _buildOptionsList([], cardColor, borderColor,
                textColor, secondaryTextColor, isDark),
            data: (methods) => _buildOptionsList(methods, cardColor,
                borderColor, textColor, secondaryTextColor, isDark),
          ),
          // Confirm button
          Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Confirm',
                    style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(
    List<SavedPaymentMethod> methods,
    Color? cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Cash
          _buildOption(
            icon: Icons.payments_outlined,
            title: 'Cash',
            subtitle: 'Pay the driver directly',
            isSelected: _selectedMethod == 'CASH',
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => setState(() {
              _selectedMethod = 'CASH';
              _selectedMethodId = null;
            }),
          ),
          const SizedBox(height: 10),
          // Saved cards
          ...methods.map((pm) {
            final isSelected = _selectedMethod == 'CARD' &&
                _selectedMethodId == pm.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOptionWithBrand(
                brand: pm.brand,
                title: pm.displayName,
                subtitle: pm.isDefault ? 'Default card' : 'Saved card',
                isSelected: isSelected,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => setState(() {
                  _selectedMethod = 'CARD';
                  _selectedMethodId = pm.id;
                }),
              ),
            );
          }),
          // Add New Card
          _buildOption(
            icon: Icons.add_circle_outline,
            title: 'Add New Card',
            subtitle: 'Credit / Debit Card',
            isSelected: false,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => _addCard(methods),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color? cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : borderColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                  size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.titleSmall.copyWith(
                          color: textColor)),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: secondaryTextColor)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryGold : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionWithBrand({
    required CardBrand brand,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color? cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : borderColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            PaymentBrandIcon(brand: brand),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.titleSmall.copyWith(
                          color: textColor)),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: secondaryTextColor)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryGold : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
