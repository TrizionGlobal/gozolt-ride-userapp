import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'quick_services_image_picker.dart';

class QuickServicesAdditionalDetails extends StatelessWidget {
  final TextEditingController whatYouNeedController;
  final TextEditingController describeIssueController;
  final List<XFile> images;
  final VoidCallback onAddImages;
  final Function(XFile) onRemoveImage;
  final bool showTellUsWhatYouNeed;

  const QuickServicesAdditionalDetails({
    super.key,
    required this.whatYouNeedController,
    required this.describeIssueController,
    required this.images,
    required this.onAddImages,
    required this.onRemoveImage,
    this.showTellUsWhatYouNeed = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTellUsWhatYouNeed) ...[
          // Tell us what you need
          Text(
            'Tell us what you need',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: whatYouNeedController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Provide specific instructions...',
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryGold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Describe issue
        Text(
          'Describe issue',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF324461)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: describeIssueController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the problem in detail...',
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGold),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Image Picker
        QuickServicesImagePicker(
          images: images,
          onAddPressed: onAddImages,
          onRemovePressed: onRemoveImage,
        ),
      ],
    );
  }
}
