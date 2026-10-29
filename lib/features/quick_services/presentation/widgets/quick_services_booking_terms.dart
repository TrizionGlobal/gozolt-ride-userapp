import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/quick_services_booking_draft.dart';

class QuickServicesBookingTerms extends StatelessWidget {
  const QuickServicesBookingTerms({super.key});

  static final Uri _termsUrl = Uri.parse(
    'https://sites.google.com/view/gozoltlegal-supplier/terms-of-service',
  );

  static final Uri _privacyUrl = Uri.parse(
    'https://sites.google.com/view/gozoltlegal-supplier/privacy-policy',
  );

  static Future<void> _openLegalPage(BuildContext context, Uri url) async {
    final opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open this page. Please try again.',
            ),
          ),
        );
    }
  }

  /// Validates that both terms and privacy policy checkboxes are accepted.
  /// If not, shows a SnackBar with appropriate message and returns false.
  static bool validate(BuildContext context) {
    if (!QuickServicesBookingDraft.acceptTerms.value) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please accept the Terms & Conditions.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      return false;
    }

    if (!QuickServicesBookingDraft.acceptPrivacy.value) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please accept the Privacy Policy.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                'BOOKING TERMS',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: QuickServicesBookingDraft.acceptTerms,
            builder: (context, accepted, _) {
              return _buildLegalRow(
                isDark: isDark,
                value: accepted,
                leadingText: 'I accept the ',
                linkText: 'Terms & Conditions',
                onChanged: (val) {
                  QuickServicesBookingDraft.acceptTerms.value = val ?? false;
                },
                onLinkPressed: () => _openLegalPage(context, _termsUrl),
              );
            },
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: QuickServicesBookingDraft.acceptPrivacy,
            builder: (context, accepted, _) {
              return _buildLegalRow(
                isDark: isDark,
                value: accepted,
                leadingText: 'I accept the ',
                linkText: 'Privacy Policy',
                onChanged: (val) {
                  QuickServicesBookingDraft.acceptPrivacy.value = val ?? false;
                },
                onLinkPressed: () => _openLegalPage(context, _privacyUrl),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow({
    required bool isDark,
    required bool value,
    required String leadingText,
    required String linkText,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onLinkPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primaryGold,
            checkColor: AppColors.backgroundDark,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                leadingText,
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.4,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onLinkPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    linkText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      height: 1.4,
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
