import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/auth_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool isTerms;

  const PrivacyPolicyScreen({super.key, this.isTerms = false});

  String get _title => isTerms ? 'Terms of Service' : 'Privacy Policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
              ),
              child: Row(
                children: [
                  AuthBackButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: January 2025',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      context,
                      '1. Introduction',
                      'Welcome to Gozolt. This ${_title.toLowerCase()} governs your use of the Gozolt mobile application and related services. By accessing or using our services, you agree to be bound by these terms.',
                    ),
                    _buildSection(
                      context,
                      '2. Data Collection',
                      'We collect information you provide directly to us, including your name, phone number, email address, location data, and payment information. This data is necessary to provide our ride-hailing services.',
                    ),
                    _buildSection(
                      context,
                      '3. Use of Information',
                      'We use the information we collect to provide, maintain, and improve our services, process transactions, send notifications about your rides, and communicate with you about promotions and updates.',
                    ),
                    _buildSection(
                      context,
                      '4. Data Sharing',
                      'We may share your information with drivers to facilitate rides, payment processors to handle transactions, and as required by law. We do not sell your personal information to third parties.',
                    ),
                    _buildSection(
                      context,
                      '5. GDPR Compliance',
                      'As a company operating in the EU, we comply with the General Data Protection Regulation (GDPR). You have the right to access, rectify, erase, or port your data. You may also object to processing or withdraw consent at any time.',
                    ),
                    _buildSection(
                      context,
                      '6. Data Retention',
                      'We retain your personal data for as long as your account is active or as needed to provide services. You may request deletion of your account and associated data at any time through the app settings.',
                    ),
                    _buildSection(
                      context,
                      '7. Security',
                      'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.',
                    ),
                    _buildSection(
                      context,
                      '8. Contact Us',
                      'If you have any questions about this ${_title.toLowerCase()}, please contact us at privacy@gozolt.com or through the in-app support feature.',
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                      ),
                      child: Text(
                        'Note: This is placeholder content. The final legal text will be provided by Gozolt\'s legal team.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
