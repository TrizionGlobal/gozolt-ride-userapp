import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/saved_payment_method.dart';
import '../providers/ride_providers.dart';
import '../providers/active_ride_provider.dart';
import '../providers/active_ride_state.dart';
import '../../history/presentation/screens/receipt_screen.dart';

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
    
    // Automatically show rating modal if ride is paid and not rated yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideState = ref.read(activeRideProvider);
      if (rideState.isPaid && !_hasSubmittedRating) {
        _showRatingModal();
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
    // Listen for payment completion to trigger rating modal
    ref.listen<ActiveRideState>(activeRideProvider, (prev, next) {
      if (prev != null && !prev.isPaid && next.isPaid && !_hasSubmittedRating) {
        _showRatingModal();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Checkmark animation
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 80,
                  height: 80,
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
              const SizedBox(height: 20),

              Text('Ride Complete!',
                  style: AppTextStyles.headlineMedium.copyWith(color: textColor)),
              const SizedBox(height: 8),
              Text(
                'You have arrived at your destination',
                style: AppTextStyles.bodyMedium.copyWith(color: secondaryTextColor),
              ),
              const SizedBox(height: 24),

              // Total fare
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
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
                    const SizedBox(height: 8),
                    Text(
                      '\u20AC${fare.toStringAsFixed(2)}',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primaryGold,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_outlined, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              formattedPaymentMethod.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.green, 
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Pay Now Section ──
              if (!rideState.isPaid && !isCash)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                size: 18,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 8),
                              Text(formattedPaymentMethod, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryGold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: rideState.isPaymentLoading ? null : () => ref.read(activeRideProvider.notifier).checkoutRide(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: rideState.isPaymentLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text('Pay \u20AC${fare.toStringAsFixed(2)} Now', style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCash)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              const Icon(
                                Icons.money,
                                size: 18,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 8),
                              Text('Cash', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryGold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please pay the driver directly.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: secondaryTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                      const SizedBox(width: 10),
                      Text('Payment Successful', style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
              if ((rideState.isPaid || isCash) && !_hasSubmittedRating) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _showRatingModal,
                    icon: const Icon(Icons.star_outline, color: AppColors.primaryGold, size: 20),
                    label: Text('Rate Driver', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGold),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Fare Breakdown (Change 3)
              _buildFareBreakdown(rideState),
              const SizedBox(height: 16),

              // GoCoins earned badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Image.asset(AssetPaths.iconGoCoin, width: 16, height: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '+${(fare * 10).floor()} GoCoins Earned!',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
                            (ride?.pickupAddress?.isNotEmpty == true) ? ride!.pickupAddress : 'Pickup location',
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
                            (ride?.dropoffAddress?.isNotEmpty == true) ? ride!.dropoffAddress : 'Dropoff location',
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


              // Tip Your Driver section (Hidden for cash payments)
              if (!isCash && !_hasSentTip && !_tipSkipped) _buildTipSection(driver?.name),
              if (_hasSentTip)
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
              const SizedBox(height: 24),

              // Report an issue
              TextButton.icon(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.createTicket,
                    extra: rideState.ride?.id,
                  );
                },
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text('Report an Issue'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),

              // View Receipt (Change 6)
              TextButton.icon(
                onPressed: () async {
                  if (rideState.ride != null) {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                    );
                    try {
                      final bytes = await generateInvoicePdf(rideState.ride!);
                      if (context.mounted) Navigator.pop(context); // close loading
                      await Printing.sharePdf(bytes: bytes, filename: 'Gozolt_Invoice_${rideState.ride!.id.substring(0, 8)}.pdf');
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context); // close loading
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
                      }
                    }
                  }
                },
                icon: const Icon(Icons.share, size: 16),
                label: Text('Download & Share Receipt', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryGold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(activeRideProvider.notifier).reset();
                    context.goNamed(RouteNames.searchDestination);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Book Another Ride',
                      style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(activeRideProvider.notifier).reset();
                    context.goNamed(RouteNames.home);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                    side: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Go to Home Screen', style: AppTextStyles.titleSmall),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fare Breakdown (Change 3) ──────────────────────────
  Widget _buildFareBreakdown(dynamic rideState) {
    final base = rideState.baseFare as double?;
    final distance = rideState.distanceFare as double?;
    final time = rideState.timeFare as double?;
    final booking = rideState.bookingFee as double?;
    final surge = rideState.surgeMultiplier as double?;

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
          if (time != null)
            _fareRow('Time', '\u20AC${time.toStringAsFixed(2)}'),
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
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSendingTip ? null : _sendTip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryGold.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSendingTip
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Send \u20AC${_tipAmount.toStringAsFixed(2)} Tip',
                      style: AppTextStyles.button,
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
    await ref.read(activeRideProvider.notifier).sendTip(_tipAmount);
    
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
    await ref.read(activeRideProvider.notifier).rateRide(
          _rating,
          comment: comment.isNotEmpty ? comment : null,
        );
        
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
