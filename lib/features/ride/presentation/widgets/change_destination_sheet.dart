import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/active_ride_provider.dart';

class ChangeDestinationSheet extends ConsumerStatefulWidget {
  const ChangeDestinationSheet({super.key});

  @override
  ConsumerState<ChangeDestinationSheet> createState() =>
      _ChangeDestinationSheetState();
}

class _ChangeDestinationSheetState
    extends ConsumerState<ChangeDestinationSheet> {
  final _addressController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSearching = false;
  List<_SuggestionItem> _suggestions = [];
  _SuggestionItem? _selectedItem;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.removeListener(_onSearchChanged);
    _addressController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // If user selected a suggestion, don't re-search
    if (_selectedItem != null &&
        _addressController.text == _selectedItem!.name) {
      return;
    }
    _selectedItem = null;

    _debounce?.cancel();
    final query = _addressController.text.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    // Use the rider's current location (or ride pickup) as bias center
    final rideState = ref.read(activeRideProvider);
    final biasLat = rideState.driverLocation?.latitude ??
        rideState.ride?.pickupLat ??
        AppConstants.defaultLat;
    final biasLng = rideState.driverLocation?.longitude ??
        rideState.ride?.pickupLng ??
        AppConstants.defaultLng;

    try {
      final dio = Dio();
      // Use Photon (Komoot) — free OSM geocoder with fuzzy/phonetic matching
      // and strong location bias. Handles typos like "Charmnar" → "Charminar".
      final url =
          'https://photon.komoot.io/api/'
          '?q=${Uri.encodeComponent(query)}'
          '&lat=$biasLat'
          '&lon=$biasLng'
          '&limit=6'
          '&lang=en';

      final response = await dio.get(
        url,
        options: Options(headers: {
          'User-Agent': 'GozoltApp/1.0',
          'Accept': 'application/json',
        }),
      );
      final data = response.data;

      if (!mounted) return;

      if (data is Map<String, dynamic> &&
          data['features'] is List &&
          (data['features'] as List).isNotEmpty) {
        final features = data['features'] as List;
        setState(() {
          _suggestions = features.map((f) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final coords = f['geometry']?['coordinates'] as List?;
            final lng = (coords != null && coords.isNotEmpty)
                ? (coords[0] as num).toDouble()
                : 0.0;
            final lat = (coords != null && coords.length > 1)
                ? (coords[1] as num).toDouble()
                : 0.0;

            final name = props['name'] as String? ?? '';
            // Build a readable subtitle from city, state, country
            final parts = <String>[
              if ((props['street'] as String?)?.isNotEmpty == true)
                props['street'] as String,
              if ((props['city'] as String?)?.isNotEmpty == true)
                props['city'] as String,
              if ((props['state'] as String?)?.isNotEmpty == true)
                props['state'] as String,
              if ((props['country'] as String?)?.isNotEmpty == true)
                props['country'] as String,
            ];
            final subtitle = parts.join(', ');

            return _SuggestionItem(
              name: name.isNotEmpty ? name : subtitle,
              subtitle: name.isNotEmpty ? subtitle : '',
              lat: lat,
              lng: lng,
            );
          }).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectSuggestion(_SuggestionItem item) {
    _selectedItem = item;
    _addressController.text = item.name;
    _addressController.selection =
        TextSelection.collapsed(offset: item.name.length);
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(activeRideProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.edit_location_alt,
                      color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 8),
                  Text('Change Destination',
                      style: AppTextStyles.headlineSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a new drop-off address. The driver will be notified and fare will be updated.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Current destination
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current drop-off',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.textMuted)),
                          Text(
                            rideState.ride?.dropoffAddress ?? 'Unknown',
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // New destination input
              TextField(
                controller: _addressController,
                autofocus: true,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search nearby destinations...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.location_on,
                      color: AppColors.primaryGold, size: 20),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        )
                      : _addressController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _addressController.clear();
                                _selectedItem = null;
                                setState(() => _suggestions = []);
                              },
                            )
                          : null,
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGold),
                  ),
                ),
              ),

              // Location suggestions
              if (_suggestions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return InkWell(
                        onTap: () => _selectSuggestion(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.subtitle.isNotEmpty)
                                      Text(
                                        item.subtitle,
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                color:
                                                    AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Pending status
              if (rideState.isDestinationChangePending) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Waiting for driver to accept...',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Buttons — show Cancel Request when pending, otherwise show Cancel + Request Change
              if (rideState.isDestinationChangePending)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(activeRideProvider.notifier).cancelDestinationChange();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel Request'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                              color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitting ? null : _submitDestinationChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                          disabledBackgroundColor:
                              AppColors.primaryGold.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).scaffoldBackgroundColor),
                              )
                            : const Text('Request Change',
                                style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDestinationChange() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a destination'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination from the suggestions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final item = _selectedItem!;
    final finalAddress =
        item.subtitle.isNotEmpty ? '${item.name}, ${item.subtitle}' : item.name;

    await ref.read(activeRideProvider.notifier).requestDestinationChange(
          newAddress: finalAddress,
          newLat: item.lat,
          newLng: item.lng,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

class _SuggestionItem {
  final String name;
  final String subtitle;
  final double lat;
  final double lng;

  const _SuggestionItem({
    required this.name,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });
}
