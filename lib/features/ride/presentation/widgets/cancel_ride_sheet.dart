import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/active_ride_provider.dart';
import '../providers/active_ride_state.dart';
import '../providers/ride_providers.dart';

class CancelRideSheet extends ConsumerStatefulWidget {
  final ActiveRideStatus? currentStatus;
  const CancelRideSheet({super.key, this.currentStatus});

  @override
  ConsumerState<CancelRideSheet> createState() => _CancelRideSheetState();
}

class _CancelRideSheetState extends ConsumerState<CancelRideSheet> {
  String? _selectedReason;
  final _otherController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    'Driver going wrong direction',
    'Pick up time taking too long',
    'Driver asked me to cancel',
    'Safety concerns',
    'Driver didn\'t show up',
    'Need to edit my details',
    'Driver/Vehicle info didn\'t match',
    'Others',
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Text('Cancel Ride',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Please tell us why you want to cancel',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          // Cancellation fee warning
          if (widget.currentStatus == ActiveRideStatus.driverArrived ||
              widget.currentStatus == ActiveRideStatus.inProgress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.currentStatus == ActiveRideStatus.inProgress
                            ? 'A cancellation fee of \u20AC8.00 will apply since the ride is in progress.'
                            : 'A cancellation fee of \u20AC5.00 may apply since the driver has arrived.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Reasons list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ..._reasons.map((reason) => _buildReasonTile(reason)),
                  if (_selectedReason == 'Others') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otherController,
                      maxLines: 3,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Please describe your reason...',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
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
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight,
                        side: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Keep Ride', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReason == null || _isSubmitting
                          ? null
                          : _submitCancellation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.error.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Cancel Ride', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error.withOpacity(0.08)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.error : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: isSelected ? AppColors.error : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? (isSelected ? Colors.white : AppColors.textSecondary)
                      : (isSelected ? AppColors.textPrimaryLight : AppColors.textPrimaryLight.withOpacity(0.7)),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCancellation() async {
    String reason = _selectedReason!;
    if (reason == 'Others') {
      reason = _otherController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please describe your reason'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(activeRideProvider.notifier).cancelRide(reason);
      if (mounted) {
        Navigator.pop(context);
        _showCancelSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel ride: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCancelSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(ctx).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 56),
              const SizedBox(height: 16),
              Text(
                'Ride Cancelled',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ride has been cancelled successfully.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(activeRideProvider.notifier).reset();
                      ref.read(rideBookingProvider.notifier).reset();
                      ref.read(isScheduleModeProvider.notifier).state = false;
                      context.goNamed(RouteNames.home);
                    },
                    child: Text('Go to Home',
                        style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(activeRideProvider.notifier).reset();
                      ref.read(rideBookingProvider.notifier).reset();
                      ref.read(isScheduleModeProvider.notifier).state = false;
                      context.goNamed(RouteNames.searchDestination);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGold,
                    ),
                    child: const Text('Book New Ride',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
