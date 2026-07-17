import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/dio_provider.dart';
import '../providers/unrated_ride_provider.dart';

class UnratedRideModal extends ConsumerStatefulWidget {
  final UnratedRideState rideState;

  const UnratedRideModal({Key? key, required this.rideState}) : super(key: key);

  @override
  ConsumerState<UnratedRideModal> createState() => _UnratedRideModalState();
}

class _UnratedRideModalState extends ConsumerState<UnratedRideModal> {
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/rides/${widget.rideState.ride.id}/rate', data: {
        'rating': _rating,
        'comment': '',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully! Thank you.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      ref.read(unratedRideProvider.notifier).dismissUnratedRide(widget.rideState.ride.id);
      Navigator.of(context).pop(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating. Please try again.')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.rideState.ride;
    final driver = widget.rideState.driverInfo;
    final fare = ride.actualFare ?? ride.estimatedFare ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'How was your recent ride?',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          if (driver != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryGold.withOpacity(0.2),
                  backgroundImage: driver.avatarUrl != null
                      ? NetworkImage(driver.avatarUrl!)
                      : null,
                  child: driver.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.primaryGold)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ride fare: \u20AC${fare.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else ...[
            Text(
              'Ride completed with \u20AC${fare.toStringAsFixed(2)} fare',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 40,
                    color: index < _rating ? AppColors.primaryGold : (isDark ? Colors.grey[700] : Colors.grey.withOpacity(0.4)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: !_isSubmitting 
                      ? () {
                          ref.read(unratedRideProvider.notifier).dismissUnratedRide(ride.id);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Skip for now',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Submit', 
                          style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          
          // Extra padding for bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
