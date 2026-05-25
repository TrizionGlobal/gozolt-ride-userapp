import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/rewards_providers.dart';

class RedeemBottomSheet extends ConsumerStatefulWidget {
  const RedeemBottomSheet({super.key});

  @override
  ConsumerState<RedeemBottomSheet> createState() => _RedeemBottomSheetState();
}

class _RedeemBottomSheetState extends ConsumerState<RedeemBottomSheet> {
  final _pointsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(rewardSummaryProvider);
    final rulesAsync = ref.watch(rewardRulesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(Icons.redeem,
                      color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 8),
                  Text('Redeem GoCoins',
                      style: AppTextStyles.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),

              // Available balance
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (context, error) => const SizedBox.shrink(),
                data: (summary) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars,
                          color: AppColors.primaryGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Available: ${summary.currentPoints.toStringAsFixed(0)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preset buttons
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (context, error) => const SizedBox.shrink(),
                data: (summary) => Row(
                  children: [
                    _presetButton(200, summary.currentPoints),
                    const SizedBox(width: 8),
                    _presetButton(500, summary.currentPoints),
                    const SizedBox(width: 8),
                    _presetButton(1000, summary.currentPoints),
                    const SizedBox(width: 8),
                    _presetButton(2000, summary.currentPoints),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _pointsController.text =
                              summary.currentPoints.toStringAsFixed(0);
                          setState(() => _errorText = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                          ),
                          child: Center(
                            child: Text(
                              'All',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryGold : AppColors.primaryGold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Points input
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() => _errorText = null),
                decoration: InputDecoration(
                  hintText: 'Enter coins to redeem',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                  errorText: _errorText,
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // EUR conversion
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (context, error) => const SizedBox.shrink(),
                data: (summary) {
                  final points =
                      int.tryParse(_pointsController.text) ?? 0;
                  double coinValueInEur = 0.0025;
                  if (summary.tier == 'PLATINUM') {
                    coinValueInEur = 0.01;
                  } else if (summary.tier == 'GOLD') {
                    coinValueInEur = 0.0075;
                  } else if (summary.tier == 'SILVER') {
                    coinValueInEur = 0.005;
                  } else {
                    coinValueInEur = 0.0025;
                  }
                  final eurValue = points * coinValueInEur;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                    ),
                    child: Center(
                      child: Text(
                        '$points coins = \u20AC${eurValue.toStringAsFixed(2)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: points > 0
                              ? AppColors.primaryGold
                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Minimum notice
              Text(
                'Minimum 200 coins to redeem',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 20),

              // Redeem button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    disabledBackgroundColor:
                        AppColors.primaryGold.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundDark),
                        )
                      : const Text('Redeem', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetButton(int amount, double maxPoints) {
    final enabled = amount <= maxPoints;
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                _pointsController.text = amount.toString();
                setState(() => _errorText = null);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled 
                ? (Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200]) 
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? (Theme.of(context).dividerTheme.color ?? AppColors.borderDark) : AppColors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              amount.toString(),
              style: AppTextStyles.labelLarge.copyWith(
                color: enabled 
                    ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight) 
                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRedeem() async {
    final points = int.tryParse(_pointsController.text);
    final summary = ref.read(rewardSummaryProvider).value;
    final rules = ref.read(rewardRulesProvider).value;

    if (points == null || points <= 0) {
      setState(() => _errorText = 'Enter a valid number');
      return;
    }
    if (points < (rules?.redemption.minimumPoints ?? 200)) {
      setState(() => _errorText = 'Minimum ${rules?.redemption.minimumPoints ?? 200} coins required');
      return;
    }
    if (summary != null && points > summary.currentPoints) {
      setState(() => _errorText = 'Insufficient coins');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ds = ref.read(rewardsRemoteDatasourceProvider);
      await ds.redeemPoints(points);

      if (mounted) {
        Navigator.pop(context);
        double coinValueInEur = 0.0025;
        if (summary?.tier == 'PLATINUM') {
          coinValueInEur = 0.01;
        } else if (summary?.tier == 'GOLD') {
          coinValueInEur = 0.0075;
        } else if (summary?.tier == 'SILVER') {
          coinValueInEur = 0.005;
        }
        final eurValue = points * coinValueInEur;
        _showSuccessDialog(points, eurValue);
        // Refresh data
        ref.invalidate(rewardSummaryProvider);
        ref.read(rewardHistoryProvider.notifier).load();
      }
    } catch (e) {
      // Extract a friendly error message from the API response if available
      String message = 'Redemption failed. Please try again.';
      final err = e.toString();
      if (err.contains('Minimum redemption')) {
        message = 'Minimum 200 coins required to redeem.';
      } else if (err.contains('Insufficient')) {
        message = 'You don\'t have enough coins.';
      } else if (err.contains('401') || err.contains('Unauthorized')) {
        message = 'Session expired. Please log in again.';
      }
      setState(() {
        _isSubmitting = false;
        _errorText = message;
      });
    }
  }

  void _showSuccessDialog(int points, double eurValue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Redeemed!', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '$points coins converted to \u20AC${eurValue.toStringAsFixed(2)} wallet balance',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              'This has been credited directly to your wallet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Great!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
