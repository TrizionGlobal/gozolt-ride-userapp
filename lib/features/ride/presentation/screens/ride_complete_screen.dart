import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../providers/active_ride_provider.dart';

class RideCompleteScreen extends ConsumerStatefulWidget {
  const RideCompleteScreen({super.key});

  @override
  ConsumerState<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends ConsumerState<RideCompleteScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _hasSubmittedRating = false;
  late AnimationController _checkAnimController;
  late Animation<double> _checkScale;

  // Tip
  double _tipAmount = 0;
  bool _hasSentTip = false;
  bool _tipSkipped = false;
  bool _showCustomTip = false;
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
    final rideState = ref.watch(activeRideProvider);
    final ride = rideState.ride;
    final driver = rideState.driverInfo;
    final fare = ride?.actualFare ?? ride?.estimatedFare ?? 19.80;

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
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'You have arrived at your destination',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Total fare
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    Text(
                      ride?.actualFare != null ? 'Total Fare' : 'Estimated Fare',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u20AC${fare.toStringAsFixed(2)}',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primaryGold,
                        fontSize: 42,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride?.paymentMethod ?? 'Cash',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Pay Now Section ──
              if (!rideState.isPaid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method', style: AppTextStyles.bodyMedium),
                          Row(
                            children: [
                              Icon(
                                ride?.paymentMethod == 'CARD' ? Icons.credit_card :
                                ride?.paymentMethod == 'UPI' ? Icons.account_balance :
                                ride?.paymentMethod == 'WALLET' ? Icons.account_balance_wallet : Icons.money,
                                size: 16,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 6),
                              Text(ride?.paymentMethod ?? 'CASH', style: AppTextStyles.titleSmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: rideState.isPaymentLoading ? null : () => ref.read(activeRideProvider.notifier).checkoutRide(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: rideState.isPaymentLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text('Pay \u20AC${fare.toStringAsFixed(2)} Now', style: AppTextStyles.button),
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
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Text('Payment Successful', style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Fare Breakdown (Change 3)
              _buildFareBreakdown(rideState),
              const SizedBox(height: 16),

              // GoCoins earned badge
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withOpacity(0.15),
                      AppColors.primaryGold.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryGold.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withOpacity(0.2),
                      ),
                      child: Image.asset(AssetPaths.iconGoCoin,
                          width: 20, height: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '+${(fare * 2).floor()} GoCoins Earned!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Route summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ride?.pickupAddress ?? 'Pickup',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Column(
                        children: List.generate(
                          2,
                          (_) => Container(
                            width: 2,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ride?.dropoffAddress ?? 'Dropoff',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rating section
              if (!_hasSubmittedRating) ...[
                Text(
                  'Rate your experience',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                if (driver != null)
                  Text(
                    'How was your ride with ${driver.name}?',
                    style: AppTextStyles.bodySmall,
                  ),
                const SizedBox(height: 12),

                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _rating = starNum);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          starNum <= _rating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.primaryGold,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Comment
                TextField(
                  controller: _commentController,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Add a comment (optional)',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[100],
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
                      borderSide:
                          const BorderSide(color: AppColors.primaryGold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Rating',
                        style: AppTextStyles.button),
                  ),
                ),
              ] else ...[
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
              ],
              const SizedBox(height: 20),

              // Tip Your Driver section
              if (!_hasSentTip && !_tipSkipped) _buildTipSection(driver?.name),
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
                label: const Text('Report an Issue'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),

              // View Receipt (Change 6)
              TextButton.icon(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.receipt,
                    extra: rideState.ride?.id ?? '',
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('View Receipt'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(activeRideProvider.notifier).reset();
                    context.goNamed(RouteNames.searchDestination);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Another Ride',
                      style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(activeRideProvider.notifier).reset();
                    context.goNamed(RouteNames.home);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                    side: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Home Screen'),
                ),
              ),
              const SizedBox(height: 32),
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
              onPressed: _sendTip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
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
    ref.read(activeRideProvider.notifier).sendTip(_tipAmount);
    setState(() => _hasSentTip = true);
  }

  Future<void> _submitRating() async {
    HapticFeedback.mediumImpact();
    final comment = _commentController.text.trim();
    await ref.read(activeRideProvider.notifier).rateRide(
          _rating,
          comment: comment.isNotEmpty ? comment : null,
        );
    setState(() => _hasSubmittedRating = true);
  }
}
