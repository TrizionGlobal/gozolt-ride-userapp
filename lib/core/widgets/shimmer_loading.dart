import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Base shimmer wrapper that applies the shimmer effect.
class ShimmerWrap extends StatelessWidget {
  final Widget child;
  const ShimmerWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.borderDark,
      child: child,
    );
  }
}

/// Rectangular shimmer placeholder.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Circular shimmer placeholder (for avatars).
class ShimmerCircle extends StatelessWidget {
  final double radius;
  const ShimmerCircle({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Text-line shimmer placeholder.
class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({super.key, required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Pre-built shimmer skeletons ─────────────────────────

/// Shimmer skeleton for ride history cards.
class ShimmerRideCard extends StatelessWidget {
  const ShimmerRideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            // Route dots column
            Column(
              children: [
                const ShimmerCircle(radius: 5),
                Container(width: 2, height: 20, color: AppColors.borderDark),
                const ShimmerCircle(radius: 5),
              ],
            ),
            const SizedBox(width: 12),
            // Text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerText(width: 180),
                  SizedBox(height: 14),
                  ShimmerText(width: 160),
                  SizedBox(height: 10),
                  ShimmerText(width: 80, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerBox(width: 50, height: 22, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for notification cards.
class ShimmerNotificationCard extends StatelessWidget {
  const ShimmerNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            const ShimmerCircle(radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerText(width: 140),
                  SizedBox(height: 8),
                  ShimmerText(width: 200),
                  SizedBox(height: 6),
                  ShimmerText(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for ticket cards.
class ShimmerTicketCard extends StatelessWidget {
  const ShimmerTicketCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 40, height: 40, borderRadius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerText(width: 160),
                  SizedBox(height: 8),
                  ShimmerText(width: 200),
                  SizedBox(height: 6),
                  ShimmerText(width: 80, height: 10),
                ],
              ),
            ),
            const ShimmerBox(width: 50, height: 20, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for payment method / saved place cards.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            const ShimmerCircle(radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerText(width: 120),
                  SizedBox(height: 6),
                  ShimmerText(width: 180, height: 10),
                ],
              ),
            ),
            const ShimmerBox(width: 20, height: 20, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Generates a list of shimmer items.
Widget buildShimmerList({
  required Widget Function() itemBuilder,
  int count = 4,
  EdgeInsets padding = const EdgeInsets.fromLTRB(16, 16, 16, 32),
}) {
  return Padding(
    padding: padding,
    child: Column(
      children: List.generate(count, (_) => itemBuilder()),
    ),
  );
}
