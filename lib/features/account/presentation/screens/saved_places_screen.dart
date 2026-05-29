import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/account_providers.dart';
import '../../../home/data/models/user_address.dart';

class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(accountAddressesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: Theme.of(context).cardTheme.color,
        onRefresh: () async {
          ref.read(accountAddressesProvider.notifier).load();
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
          // ── Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
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
                            color: AppColors.backgroundDark
                                .withOpacity(0.15),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.backgroundDark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Saved Places',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────
          if (addressState.isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerListTile(),
                  childCount: 4,
                ),
              ),
            )
          else if (addressState.addresses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off,
                        color: AppColors.textMuted, size: 56),
                    const SizedBox(height: 16),
                    Text('No saved places',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
                    const SizedBox(height: 6),
                    Text('Add your frequently visited places',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 150,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPlaceSheet(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('Add Place'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...addressState.addresses.map((addr) => GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _labelIcon(addr.label),
                                  color: AppColors.primaryGold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(addr.label,
                                        style: AppTextStyles.titleSmall),
                                    const SizedBox(height: 2),
                                    Text(
                                      addr.address,
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showPlaceSheet(context, ref,
                                    address: addr),
                                child: const Icon(Icons.edit_outlined,
                                    color: AppColors.textSecondary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () =>
                                    _confirmDelete(context, ref, addr.id),
                                child: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                              ),
                            ],
                          ),
                        ),
                      )),


                    // Add button
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: GestureDetector(
                          onTap: () => _showPlaceSheet(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add,
                                    color: AppColors.primaryGold, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Add New Place',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.primaryGold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _labelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.place;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Place', style: AppTextStyles.headlineSmall),
        content: Text(
          'Are you sure you want to remove this saved place?',
          style: AppTextStyles.bodyMedium
              .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  ref.read(accountAddressesProvider.notifier).deleteAddress(id);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPlaceSheet(BuildContext context, WidgetRef ref,
      {UserAddress? address}) {
    final isEdit = address != null;
    final labelController = TextEditingController(text: address?.label);
    final addressController = TextEditingController(text: address?.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Place' : 'Add Place',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Label (e.g. Home, Work, Gym)',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Address',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (labelController.text.isNotEmpty &&
                      addressController.text.isNotEmpty) {
                    final data = {
                      'label': labelController.text,
                      'address': addressController.text,
                    };

                    if (isEdit) {
                      ref
                          .read(accountAddressesProvider.notifier)
                          .updateAddress(address.id, data);
                    } else {
                      ref
                          .read(accountAddressesProvider.notifier)
                          .addAddress(data);
                    }
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Update' : 'Save', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

