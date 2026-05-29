import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/router/route_names.dart';
import '../providers/account_providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _confirmChecked = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.error.withOpacity(0.8),
                    AppColors.error,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Go back',
                        button: true,
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete Account',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Warning icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 36),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'This action is permanent',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 20),

                // What happens section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What happens when you delete your account:',
                          style: AppTextStyles.titleSmall),
                      const SizedBox(height: 12),
                      _impactRow(Icons.person_off,
                          'Your profile and personal data will be permanently deleted'),
                      _impactRow(Icons.history,
                          'All ride history will be removed'),
                      _impactRow(Icons.stars,
                          'All GoCoins and rewards will be forfeited'),
                      _impactRow(Icons.credit_card,
                          'Saved payment methods will be removed'),
                      _impactRow(Icons.people,
                          'Referral data and bonuses will be lost'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // GDPR note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.info, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Under GDPR, you have the right to request data deletion.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirmation checkbox
                Semantics(
                  label: 'Confirm account deletion checkbox',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _confirmChecked = !_confirmChecked);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _confirmChecked
                                ? AppColors.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _confirmChecked
                                  ? AppColors.error
                                  : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                            ),
                          ),
                          child: _confirmChecked
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'I understand this action is irreversible and all my data, GoCoins, and ride history will be permanently deleted.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Delete button (double confirmation)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _confirmChecked && !_isDeleting ? _deleteAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.error.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Delete My Account',
                            style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text('Cancel, keep my account',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    HapticFeedback.heavyImpact();
    // Double confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Final Confirmation', style: AppTextStyles.headlineSmall),
        content: Text(
          'This is your last chance. Are you absolutely sure you want to delete your account? This cannot be undone.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Go Back',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: Text('Yes, Delete',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final ds = ref.read(accountRemoteDatasourceProvider);
      await ds.deleteAccount();
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account. Please try again.')),
        );
      }
      return;
    }

    if (mounted) {
      final storage = ref.read(secureStorageProvider);
      await storage.clearTokens();
      if (mounted) {
        // Show success modal
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Account Deleted', style: AppTextStyles.headlineSmall),
            content: Text(
              'Your account has been deleted successfully. We\'re sorry to see you go.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.goNamed(RouteNames.welcome);
                },
                child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }
}
