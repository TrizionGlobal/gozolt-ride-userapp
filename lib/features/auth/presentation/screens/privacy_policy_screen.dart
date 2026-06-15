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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Last Updated
                    Text(
                      'Last Updated: 23 May 2026',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (isTerms) ...[
                      const _BodyText(
                        'By using Gozolt, you agree to these Terms of Service.\n\n'
                        'Gozolt is a technology platform connecting Riders with independent licensed Suppliers and their authorised Drivers. Gozolt does not provide transportation services directly.',
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      const _SectionTitle('Services'),
                      const SizedBox(height: 8),
                      const _BodyText('Gozolt currently provides:'),
                      const SizedBox(height: 10),
                      const _BulletPoint('Ride-Hailing / Cab Booking'),
                      const SizedBox(height: 10),
                      const _BodyText('Additional services may be introduced in the future.'),
                      const SizedBox(height: 24),

                      const _SectionTitle('User Responsibilities'),
                      const SizedBox(height: 8),
                      const _BodyText('Users agree to:'),
                      const SizedBox(height: 10),
                      const _BulletPoint('Provide accurate information'),
                      const _BulletPoint('Follow applicable laws'),
                      const _BulletPoint('Treat Drivers respectfully'),
                      const _BulletPoint('Avoid misuse or fraudulent activity'),
                      const SizedBox(height: 24),

                      const _SectionTitle('Payments & Rewards'),
                      const SizedBox(height: 8),
                      const _BodyText('Ride fares may include distance, time, waiting, and booking charges.\n\nGoCoins rewards, referrals, and redemption benefits are subject to applicable rules and tier limitations within the App.'),
                      const SizedBox(height: 24),

                      const _SectionTitle('Account Suspension'),
                      const SizedBox(height: 8),
                      const _BodyText('Accounts may be suspended or terminated for fraud, abuse, illegal activity, or safety violations.'),
                      const SizedBox(height: 24),

                      const _SectionTitle('Privacy'),
                      const SizedBox(height: 8),
                      const _BodyText('Use of the Platform is also governed by the Gozolt Privacy Policy.'),
                      const SizedBox(height: 24),
                    ] else ...[
                      const _BodyText(
                        'Gozolt (“we”, “our”, or “us”) is operated by Primooo Global Ltd., Malta.\n\n'
                        'We collect and process certain information to provide ride-booking and related services through the Gozolt Platform.',
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      const _SectionTitle('Information We Collect'),
                      const SizedBox(height: 8),
                      const _BodyText('We may collect:'),
                      const SizedBox(height: 10),
                      const _BulletPoint('Name, phone number, and email address'),
                      const _BulletPoint('Live location and trip details'),
                      const _BulletPoint('Payment and transaction information'),
                      const _BulletPoint('Device and technical information'),
                      const _BulletPoint('Rewards, referrals, and GoCoins activity'),
                      const _BulletPoint('Customer support communications'),
                      const SizedBox(height: 24),

                      const _SectionTitle('How We Use Your Data'),
                      const SizedBox(height: 8),
                      const _BodyText('We use your information to:'),
                      const SizedBox(height: 10),
                      const _BulletPoint('Provide ride-booking services'),
                      const _BulletPoint('Match Riders with Drivers'),
                      const _BulletPoint('Process payments and rewards'),
                      const _BulletPoint('Improve app performance and safety'),
                      const _BulletPoint('Prevent fraud and abuse'),
                      const _BulletPoint('Comply with legal obligations'),
                      const SizedBox(height: 24),

                      const _SectionTitle('Permissions'),
                      const SizedBox(height: 8),
                      const _BodyText('Depending on your device settings, Gozolt may request access to:'),
                      const SizedBox(height: 10),
                      const _BulletPoint('Location services'),
                      const _BulletPoint('Notifications'),
                      const _BulletPoint('Camera'),
                      const _BulletPoint('Photos/media'),
                      const _BulletPoint('Phone/SMS verification'),
                      const SizedBox(height: 10),
                      const _BodyText('Permissions can be managed in your device settings.'),
                      const SizedBox(height: 24),

                      const _SectionTitle('Payments'),
                      const SizedBox(height: 8),
                      const _BodyText('Online payments are securely processed through trusted third-party payment providers such as Stripe. Gozolt does not store full card details or CVV information.'),
                      const SizedBox(height: 24),

                      const _SectionTitle('GDPR Rights'),
                      const SizedBox(height: 8),
                      const _BodyText('Users in the European Union have rights including:'),
                      const SizedBox(height: 10),
                      const _BulletPoint('Access to personal data'),
                      const _BulletPoint('Correction of inaccurate data'),
                      const _BulletPoint('Data deletion requests'),
                      const _BulletPoint('Restricting or objecting to processing'),
                      const _BulletPoint('Data portability'),
                      const SizedBox(height: 24),

                      const _SectionTitle('Account Deletion'),
                      const SizedBox(height: 8),
                      const _BodyText('Users may delete their account anytime through:\nSettings → Account → Delete Account'),
                      const SizedBox(height: 24),
                    ],

                    // Contact Us
                    const _SectionTitle('Contact Us'),
                    const SizedBox(height: 8),
                    const _BodyText('Primooo Global Ltd.'),
                    const SizedBox(height: 10),
                    const _ClickableBullet(
                      label: 'Support: ',
                      linkText: 'support@gozolt.com.mt',
                      launchUri: 'mailto:support@gozolt.com.mt',
                    ),
                    if (!isTerms)
                      const _ClickableBullet(
                        label: 'Privacy: ',
                        linkText: 'privacy@gozolt.com.mt',
                        launchUri: 'mailto:privacy@gozolt.com.mt',
                      ),
                    _ClickableBullet(
                      label: isTerms ? 'Full Terms: ' : 'Full Policy: ',
                      linkText: isTerms ? 'https://sites.google.com/view/gozoltlegal/terms-of-service' : 'https://sites.google.com/view/gozoltlegal/privacy-policy',
                      launchUri: isTerms ? 'https://sites.google.com/view/gozoltlegal/terms-of-service' : 'https://sites.google.com/view/gozoltlegal/privacy-policy',
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.titleMedium.copyWith(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
        height: 1.6,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClickableBullet extends StatelessWidget {
  final String label;
  final String linkText;
  final String launchUri;

  const _ClickableBullet({
    required this.label,
    required this.linkText,
    required this.launchUri,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(launchUri);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        linkText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
