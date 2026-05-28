import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class DriverEnRouteView extends StatelessWidget {
  final int etaMinutes;
  final VoidCallback onCancel;

  const DriverEnRouteView({
    super.key,
    required this.etaMinutes,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Removing the cancel button as it's moved to trip details
  }
}
