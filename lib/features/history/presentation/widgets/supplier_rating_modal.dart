import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class SupplierRatingModal extends StatefulWidget {
  final String supplierName;
  final String serviceTitle;
  final String? bookingReference;
  final Future<void> Function(int rating, String? review) onSubmitRating;
  final VoidCallback? onDismiss;

  const SupplierRatingModal({
    super.key,
    required this.supplierName,
    required this.serviceTitle,
    this.bookingReference,
    required this.onSubmitRating,
    this.onDismiss,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String supplierName,
    required String serviceTitle,
    String? bookingReference,
    required Future<void> Function(int rating, String? review) onSubmitRating,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SupplierRatingModal(
          supplierName: supplierName,
          serviceTitle: serviceTitle,
          bookingReference: bookingReference,
          onSubmitRating: onSubmitRating,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  @override
  State<SupplierRatingModal> createState() => _SupplierRatingModalState();
}

class _SupplierRatingModalState extends State<SupplierRatingModal> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? comment = _commentController.text.trim();
      if (comment.isEmpty) {
        comment = null;
      } else {
        comment = comment[0].toUpperCase() + comment.substring(1);
      }

      await widget.onSubmitRating(
        _rating,
        comment,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thank you for rating ${widget.supplierName}!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row with Supplier Icon and Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primaryGold,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Supplier Rating',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      size: 22,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            widget.onDismiss?.call();
                            Navigator.of(context).pop(false);
                          },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Supplier Name
              Text(
                widget.supplierName.isNotEmpty ? widget.supplierName : 'Supplier',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Service Title
              Text(
                widget.serviceTitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              if (widget.bookingReference != null && widget.bookingReference!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.bookingReference!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),

              // 5 Stars Row
              IgnorePointer(
                ignoring: _isSubmitting,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isFilled = starIndex <= _rating;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _rating = starIndex;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedScale(
                          scale: isFilled ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 44,
                            color: isFilled
                                ? AppColors.primaryGold
                                : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),

              // Rating text label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getRatingLabel(_rating),
                  key: ValueKey<int>(_rating),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _rating > 0
                        ? AppColors.primaryGold
                        : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Comment / Review Field
              IgnorePointer(
                ignoring: _isSubmitting,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141416) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share details of your experience with ${widget.supplierName}... (optional)',
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_rating > 0 && !_isSubmitting) ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    disabledBackgroundColor: _isSubmitting
                        ? AppColors.primaryGold
                        : (isDark
                            ? AppColors.primaryGold.withValues(alpha: 0.2)
                            : Colors.grey[300]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.backgroundDark,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Submitting...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.backgroundDark,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Maybe Later Button
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        widget.onDismiss?.call();
                        Navigator.of(context).pop(false);
                      },
                child: Text(
                  'Maybe Later',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
