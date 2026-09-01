import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/data/models/location_data.dart';

class BikeRentalLocationField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color dotColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String labelOverride;

  const BikeRentalLocationField({
    super.key,
    required this.controller,
    required this.hint,
    required this.dotColor,
    this.trailing,
    this.onTap,
    this.labelOverride = '',
  });

  String get _label {
    if (labelOverride.isNotEmpty) return labelOverride;
    if (dotColor == AppColors.success) return 'PICKUP';
    if (dotColor == AppColors.error) return 'DROP-OFF';
    return 'STOP';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = controller.text.isNotEmpty;
    final fieldBg = isDark
        ? const Color(0xFF1A1F2B)
        : const Color(0xFFF0F2F5);
    final fieldBorder = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final labelColor = dotColor.withOpacity(0.85);

    return Row(
      children: [
        // Colored dot with subtle glow
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasValue
                      ? dotColor.withOpacity(0.35)
                      : fieldBorder,
                  width: hasValue ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label row
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Value / hint
                  Text(
                    hasValue ? controller.text : hint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: hasValue
                          ? (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class BikeRentalLocationSearchSheet extends StatefulWidget {
  final ValueChanged<LocationData> onSelect;
  final bool showCurrentLocation;

  const BikeRentalLocationSearchSheet({
    super.key,
    required this.onSelect,
    this.showCurrentLocation = false,
  });

  @override
  State<BikeRentalLocationSearchSheet> createState() => _BikeRentalLocationSearchSheetState();
}

class _BikeRentalLocationSearchSheetState extends State<BikeRentalLocationSearchSheet> {
  final _searchController = TextEditingController();
  final _dio = Dio();
  Timer? _debounce;
  List<LocationData> _results = [];
  bool _isSearching = false;
  bool _showingQuickPicks = true;

  static const _maltaQuickPicks = [
    LocationData(
      address: 'Malta International Airport',
      latitude: 35.8575,
      longitude: 14.4775,
      subtitle: 'Luqa, LQA 4000',
    ),
    LocationData(
      address: '24 Luxury Towers, Sliema',
      latitude: 35.9117,
      longitude: 14.5050,
      subtitle: 'Sliema waterfront, Malta',
    ),
    LocationData(
      address: 'Valletta Bus Terminal',
      latitude: 35.8950,
      longitude: 14.5089,
      subtitle: 'Valletta, Malta',
    ),
    LocationData(
      address: 'St. Julian\'s Bay',
      latitude: 35.9186,
      longitude: 14.4893,
      subtitle: 'St. Julian\'s, Malta',
    ),
    LocationData(
      address: 'Mdina Gate',
      latitude: 35.8858,
      longitude: 14.4024,
      subtitle: 'Mdina, Malta',
    ),
    LocationData(
      address: 'Bugibba Square',
      latitude: 35.9512,
      longitude: 14.4157,
      subtitle: 'Bugibba, Malta',
    ),
    LocationData(
      address: 'Marsaxlokk Harbour',
      latitude: 35.8419,
      longitude: 14.5432,
      subtitle: 'Marsaxlokk, Malta',
    ),
    LocationData(
      address: 'University of Malta',
      latitude: 35.9026,
      longitude: 14.4835,
      subtitle: 'Msida, Malta',
    ),
    LocationData(
      address: 'Mater Dei Hospital',
      latitude: 35.8993,
      longitude: 14.4847,
      subtitle: 'Msida, Malta',
    ),
    LocationData(
      address: 'The Point Shopping Mall',
      latitude: 35.9113,
      longitude: 14.5056,
      subtitle: 'Sliema, Malta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _results = _maltaQuickPicks;
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = _maltaQuickPicks;
        _isSearching = false;
        _showingQuickPicks = true;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPlaceSuggestions(query.trim());
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    double biasLat = AppConstants.defaultLat;
    double biasLng = AppConstants.defaultLng;
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        biasLat = pos.latitude;
        biasLng = pos.longitude;
      }
    } catch (_) {}

    List<LocationData> newResults = [];

    // TIER 1: Google Places Autocomplete
    try {
      final googleUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&location=$biasLat%2C$biasLng'
          '&radius=100000'
          '&key=${AppConstants.googleMapsApiKey}';

      final googleRes = await _dio.get(googleUrl);
      final gData = googleRes.data;

      if (gData is Map<String, dynamic> && gData['status'] == 'OK' && gData['predictions'] is List) {
        final predictions = gData['predictions'] as List;
        newResults = predictions.map((p) {
          final structured = p['structured_formatting'] as Map<String, dynamic>?;
          final mainText = structured?['main_text'] as String? ?? p['description'] as String? ?? query;
          final secondaryText = structured?['secondary_text'] as String?;

          return LocationData(
            address: mainText,
            latitude: 0,
            longitude: 0,
            subtitle: secondaryText,
            placeId: p['place_id'] as String?,
          );
        }).toList();
      }
    } catch (_) {}

    // TIER 2: Photon Fallback
    if (newResults.isEmpty) {
      try {
        final url = 'https://photon.komoot.io/api/'
            '?q=${Uri.encodeComponent(query)}'
            '&lat=$biasLat'
            '&lon=$biasLng'
            '&limit=8'
            '&lang=en';

        final response = await _dio.get(url, options: Options(headers: {'User-Agent': 'GozoltApp/1.0', 'Accept': 'application/json'}));
        final data = response.data;

        if (data is Map<String, dynamic> && data['features'] is List) {
          final features = data['features'] as List;
          newResults = features.map((f) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final coords = f['geometry']?['coordinates'] as List?;
            final lng = (coords != null && coords.isNotEmpty) ? (coords[0] as num).toDouble() : 0.0;
            final lat = (coords != null && coords.length > 1) ? (coords[1] as num).toDouble() : 0.0;

            final name = props['name'] as String? ?? '';
            final parts = <String>[
              if ((props['street'] as String?)?.isNotEmpty == true) props['street'] as String,
              if ((props['city'] as String?)?.isNotEmpty == true) props['city'] as String,
              if ((props['state'] as String?)?.isNotEmpty == true) props['state'] as String,
              if ((props['country'] as String?)?.isNotEmpty == true) props['country'] as String,
            ];

            return LocationData(
              address: name.isNotEmpty ? name : parts.firstOrNull ?? query,
              latitude: lat,
              longitude: lng,
              subtitle: parts.isNotEmpty ? parts.join(', ') : null,
            );
          }).toList();
        }
      } catch (_) {}
    }

    // TIER 3: Native Geocoding Fallback
    if (newResults.isEmpty) {
      try {
        final locations = await geocoding.locationFromAddress(query);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          try {
            final placemarks = await geocoding.placemarkFromCoordinates(loc.latitude, loc.longitude);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final address = p.name ?? query;
              final parts = [p.locality, p.administrativeArea, p.country].where((e) => e != null && e.isNotEmpty).join(', ');
              newResults.add(LocationData(
                address: address.isNotEmpty ? address : query,
                latitude: loc.latitude,
                longitude: loc.longitude,
                subtitle: parts.isNotEmpty ? parts : 'Found via native search',
              ));
            } else {
              throw Exception();
            }
          } catch (_) {
            newResults.add(LocationData(
              address: query,
              latitude: loc.latitude,
              longitude: loc.longitude,
              subtitle: 'Found via native search',
            ));
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _showingQuickPicks = false;
      _results = newResults;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search any location...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Current Location special button
            if (_showingQuickPicks && widget.showCurrentLocation)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result = await context.pushNamed<LocationData>(RouteNames.mapPinSelection);
                    if (result != null && mounted) {
                      widget.onSelect(result);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.my_location, color: AppColors.primaryGold, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Confirm via map',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.primaryGold, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            // Section header
            if (_showingQuickPicks && _results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Picks',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            if (!_isSearching && !_showingQuickPicks && _results.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No locations found',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            // Results
            if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final loc = _results[index];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          if (loc.placeId != null && loc.latitude == 0 && loc.longitude == 0) {
                            try {
                              final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json'
                                  '?place_id=${loc.placeId}'
                                  '&fields=geometry'
                                  '&key=${AppConstants.googleMapsApiKey}';
                              final res = await _dio.get(detailsUrl);
                              final dData = res.data;
                              if (dData['status'] == 'OK') {
                                final location = dData['result']['geometry']['location'];
                                final lat = (location['lat'] as num).toDouble();
                                final lng = (location['lng'] as num).toDouble();
                                if (mounted) {
                                  widget.onSelect(loc.copyWith(latitude: lat, longitude: lng));
                                }
                                return;
                              }
                            } catch (_) {
                              // Fallback below
                            }
                          }
                          
                          // Immediately call onSelect — no delay
                          widget.onSelect(loc);
                        },
                        splashColor: AppColors.primaryGold.withOpacity(0.15),
                        highlightColor: AppColors.primaryGold.withOpacity(0.08),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _showingQuickPicks
                                      ? (isDark ? const Color(0xFF1C2333) : const Color(0xFFF0F2F5))
                                      : AppColors.primaryGold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _showingQuickPicks
                                      ? Icons.location_on_outlined
                                      : Icons.place_outlined,
                                  color: _showingQuickPicks
                                      ? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)
                                      : AppColors.primaryGold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.address,
                                      style:
                                          AppTextStyles.bodyMedium.copyWith(
                                        color: isDark
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (loc.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        loc.subtitle!,
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
