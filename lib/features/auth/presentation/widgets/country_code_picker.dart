import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/country_code.dart';

class CountryCodePicker extends StatefulWidget {
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelected;

  const CountryCodePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required CountryCode selected,
    required ValueChanged<CountryCode> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => CountryCodePicker(
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  final _searchController = TextEditingController();
  List<CountryCode> _filtered = supportedCountryCodes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = supportedCountryCodes;
      } else {
        _filtered = supportedCountryCodes.where((c) {
          return c.name.toLowerCase().contains(q) ||
              c.dialCode.contains(q) ||
              c.code.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Select Country',
              style: AppTextStyles.titleLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search country or code...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? AppColors.inputDark,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No countries found',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final country = _filtered[index];
                        final isSelected =
                            country.code == widget.selected.code;

                        return ListTile(
                          onTap: () {
                            widget.onSelected(country);
                            Navigator.of(context).pop();
                          },
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            country.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                            ),
                          ),
                          trailing: Text(
                            country.dialCode,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor:
                              AppColors.primaryGold.withOpacity(0.08),
                        );
                      },
                    ),
            ),
          ],
        ),
        );
      },
    );
  }
}
