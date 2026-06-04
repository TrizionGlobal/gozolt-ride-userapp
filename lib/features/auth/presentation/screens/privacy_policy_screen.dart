import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: AppColors.backgroundDark, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
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
                      'Last Updated: 23 May 2026',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (isTerms) ...[
                      Text(
                        'By using Gozolt, you agree to these Terms of Service.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gozolt is a technology platform connecting Riders with independent licensed Suppliers and their authorised Drivers. Gozolt does not provide transportation services directly.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        'Services',
                        body: 'Gozolt currently provides:\n• Ride-Hailing / Cab Booking\n\nAdditional services may be introduced in the future.',
                      ),
                      _buildSection(
                        context,
                        'User Responsibilities',
                        body: 'Users agree to:\n• Provide accurate information\n• Follow applicable laws\n• Treat Drivers respectfully\n• Avoid misuse or fraudulent activity',
                      ),
                      _buildSection(
                        context,
                        'Payments & Rewards',
                        body: 'Ride fares may include distance, time, waiting, and booking charges.\n\nGoCoins rewards, referrals, and redemption benefits are subject to applicable rules and tier limitations within the App.',
                      ),
                      _buildSection(
                        context,
                        'Account Suspension',
                        body: 'Accounts may be suspended or terminated for fraud, abuse, illegal activity, or safety violations.',
                      ),
                      _buildSection(
                        context,
                        'Privacy',
                        body: 'Use of the Platform is also governed by the Gozolt Privacy Policy.',
                      ),
                    ] else ...[
                      Text(
                        'Gozolt (“we”, “our”, or “us”) is operated by Primooo Global Ltd., Malta.\nWe collect and process certain information to provide ride-booking and related services through the Gozolt Platform.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        'Information We Collect',
                        body: 'We may collect:\n• Name, phone number, and email address\n• Live location and trip details\n• Payment and transaction information\n• Device and technical information\n• Rewards, referrals, and GoCoins activity\n• Customer support communications',
                      ),
                      _buildSection(
                        context,
                        'How We Use Your Data',
                        body: 'We use your information to:\n• Provide ride-booking services\n• Match Riders with Drivers\n• Process payments and rewards\n• Improve app performance and safety\n• Prevent fraud and abuse\n• Comply with legal obligations',
                      ),
                      _buildSection(
                        context,
                        'Permissions',
                        body: 'Depending on your device settings, Gozolt may request access to:\n• Location services\n• Notifications\n• Camera\n• Photos/media\n• Phone/SMS verification\n\nPermissions can be managed in your device settings.',
                      ),
                      _buildSection(
                        context,
                        'Payments',
                        body: 'Online payments are securely processed through trusted third-party payment providers such as Stripe. Gozolt does not store full card details or CVV information.',
                      ),
                      _buildSection(
                        context,
                        'GDPR Rights',
                        body: 'Users in the European Union have rights including:\n• Access to personal data\n• Correction of inaccurate data\n• Data deletion requests\n• Restricting or objecting to processing\n• Data portability',
                      ),
                      _buildSection(
                        context,
                        'Account Deletion',
                        body: 'Users may delete their account anytime through:\nSettings → Account → Delete Account',
                      ),
                    ],
                    _buildSection(
                      context,
                      'Contact',
                      content: _buildContactUs(context),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSection(BuildContext context, String title, {String? body, Widget? content}) {
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
          if (body != null)
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                height: 1.6,
              ),
            ),
          if (content != null) content,
        ],
      ),
    );
  }

  Widget _buildContactUs(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final linkColor = Colors.blue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Primooo Global Ltd.', style: AppTextStyles.bodyMedium.copyWith(color: textColor, height: 1.6)),
        Row(
          children: [
            Text('Support: ', style: AppTextStyles.bodyMedium.copyWith(color: textColor, height: 1.6)),
            Expanded(
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse('mailto:support@gozolt.com.mt')),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    'support@gozolt.com.mt',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: linkColor,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isTerms)
          Row(
            children: [
              Text('Privacy: ', style: AppTextStyles.bodyMedium.copyWith(color: textColor, height: 1.6)),
              Expanded(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse('mailto:privacy@gozolt.com.mt')),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      'privacy@gozolt.com.mt',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: linkColor,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTerms ? 'Full Terms: ' : 'Full Policy: ', style: AppTextStyles.bodyMedium.copyWith(color: textColor, height: 1.6)),
            Expanded(
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(isTerms ? 'https://sites.google.com/view/gozoltlegal/terms-of-service' : 'https://sites.google.com/view/gozoltlegal/privacy-policy')),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    isTerms ? 'https://sites.google.com/view/gozoltlegal/terms-of-service' : 'https://sites.google.com/view/gozoltlegal/privacy-policy',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: linkColor,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
