import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

class QuickServicesAdditionalDetailsReview extends StatelessWidget {
  final String? instructionText; // maps to comments or whatYouNeed
  final String? describeIssue;
  final List<String>? uploadedImages;

  const QuickServicesAdditionalDetailsReview({
    super.key,
    this.instructionText,
    this.describeIssue,
    this.uploadedImages,
  });

  @override
  Widget build(BuildContext context) {
    final hasIssue = describeIssue != null && describeIssue!.trim().isNotEmpty;
    final hasImages = uploadedImages != null && uploadedImages!.isNotEmpty;

    if (!hasIssue && !hasImages) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (hasIssue) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Issue description: $describeIssue',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (hasImages) const SizedBox(height: 10),
          ],
          if (hasImages) ...[
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Text('Attached Photo (${uploadedImages!.length})', style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: uploadedImages!.length,
                itemBuilder: (context, index) {
                  final path = uploadedImages![index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: path.startsWith('http')
                          ? Image.network(
                              path,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                              ),
                            )
                          : Image.file(
                              File(path),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    ));
  }
}
