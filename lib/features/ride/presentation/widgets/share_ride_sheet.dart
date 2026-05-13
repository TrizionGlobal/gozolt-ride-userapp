import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/active_ride_provider.dart';

class ShareRideSheet extends ConsumerStatefulWidget {
  const ShareRideSheet({super.key});

  @override
  ConsumerState<ShareRideSheet> createState() => _ShareRideSheetState();
}

class _ShareRideSheetState extends ConsumerState<ShareRideSheet> {
  bool _isLoading = false;
  String? _trackingUrl;

  @override
  void initState() {
    super.initState();
    _generateLink();
  }

  Future<void> _generateLink() async {
    setState(() => _isLoading = true);
    final url = await ref.read(activeRideProvider.notifier).shareRide();
    if (mounted) {
      setState(() {
        _trackingUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(activeRideProvider);
    final driver = rideState.driverInfo;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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

              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_location,
                    color: AppColors.primaryGold, size: 28),
              ),
              const SizedBox(height: 16),

              Text('Share Live Location',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),

              Text(
                'Share your live ride tracking with family or friends',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Driver + vehicle info
              if (driver != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car,
                          color: AppColors.primaryGold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${driver.name} \u2022 ${driver.vehicleDescription} \u2022 ${driver.formattedPlate}',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Tracking link
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold, strokeWidth: 2),
                )
              else if (_trackingUrl != null) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link,
                          color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _trackingUrl!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _trackingUrl!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success, size: 20),
                                  const SizedBox(width: 10),
                                  const Text('Link copied'),
                                ],
                              ),
                              backgroundColor: Theme.of(context).cardTheme.color,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy,
                            color: AppColors.primaryGold, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Share button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Share.share(
                        'Track my Gozolt ride in real-time: $_trackingUrl',
                        subject: 'My Gozolt Live Location',
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share with Contacts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
