import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/active_ride_provider.dart';
import '../providers/active_ride_state.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Text('Cancel Ride',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.error)),
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
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
                        fillColor: AppColors.inputDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderDark),
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
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderDark),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep Ride'),
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
                            AppColors.error.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Cancel Ride'),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error.withValues(alpha: 0.08)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: isSelected ? AppColors.error : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 56),
            const SizedBox(height: 16),
            Text(
              'Ride Cancelled',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ride has been cancelled successfully.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.goNamed(RouteNames.searchDestination);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Book New Ride'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.goNamed(RouteNames.home);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Go to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
